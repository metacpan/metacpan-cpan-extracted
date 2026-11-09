use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;

# LIVE. What is left on the server when a transaction of the storage ends in
# an error.
#
# CLAIMED: a transaction that ends in an error is rolled back ON THE SERVER,
# and the storage says what the server says. After the error
#
#   * transaction_depth of the storage is 0,
#   * @@trancount of the session the storage talks to is 0,
#   * the row changed inside the transaction reads as it did before, through
#     the storage,
#   * and a second session reads it too: no lock is left on it.
#
# All four are compared at once, per case; the storage's own word alone is
# what was wrong here. That the change was there, inside a transaction, before
# the error is a test of its own in every case: a rollback of nothing proves
# nothing.
#
# Plain tests, green on every client library:
#
#   1. txn_do, a valid UPDATE, then a statement the server refuses at prepare
#      (Msg 207, Invalid column name). The control.
#   2. txn_scope_guard, a valid UPDATE, then a statement the server refuses at
#      execute (Msg 2601, duplicate key).
#   3. txn_scope_guard, a valid UPDATE, then a die in Perl: no server error.
#
# Cases that need the FreeTDS class (karr k65; TODO under any other client
# library, see below):
#
#   4. txn_scope_guard, a valid UPDATE, then the statement of 1.
#   5. The same without the valid UPDATE.
#   6. txn_do and txn_scope_guard, a valid UPDATE, a cursor read with a
#      fetch and left open, then a die: rolled back.
#   7. txn_scope_guard, a valid UPDATE, a cursor left open, $guard->commit:
#      commit throws, naming the open cursor, before anything is sent; the
#      failed commit ends the transaction (core, karr k372): the cursor is
#      finished, ROLLBACK goes out on the same connection, depth 0,
#      @@trancount 0, the change gone, the caller gets the COMMIT's error.
#   8. A cursor left open, then txn_scope_guard and txn_do: BEGIN TRAN throws,
#      naming the open cursor, and nothing is begun (depth 0, @@trancount 0).
#
# WHY these are what they are (DBI trace of 2026-10-05; the CS_CONNECTION each
# statement was sent on is in it): BEGIN TRAN, COMMIT and ROLLBACK are sent
# with $dbh->do on a handle whose AutoCommit is on. For a statement on a
# handle that has an active statement, DBD::Sybase opens a second connection
# ("parent has active kids - opening new connection") and sends it there. No
# error reaches anybody. A ROLLBACK goes where no transaction is open, a
# COMMIT likewise -- the UPDATE is gone when the connection closes -- and the
# storage counts down regardless. Two things leave an active statement handle:
#
#   * a cursor somebody has not read to its end (6, 7, 8);
#   * under FreeTDS with TDS 5.0 a dynamic statement the server refuses at
#     prepare (4, 5): DBD::Sybase's prepare returns a handle marked active
#     and sets the database handle's "in use" flag (syb_st_prepare, dbdimp.c
#     of 1.27). The handle is a temporary of the interpreter while the
#     exception unwinds, and the guard, a lexical, is destroyed before it
#     and rolls back. txn_do catches in an eval of its own, after the
#     temporary is gone, which is why 1 never needed a fix. A failure at
#     execute (2) leaves a handle that is not active; a die in Perl (3)
#     leaves none.
#
# DBIO::Sybase::Storage::FreeTDS therefore, with an active statement handle on
# the connection:
#
#   * ROLLBACK -- of a guard, of txn_do, of txn_rollback -- finishes every
#     active statement handle and rolls back on the same connection. A cursor
#     read across the rollback is ended by it: the accepted price (it is not
#     asserted here either way).
#   * BEGIN TRAN throws before anything is sent and leaves the storage as it
#     was; COMMIT throws the same way and the core then ends the transaction
#     as it does after any failed commit (rollback as above, depth 0).
#     Nothing is sent on a second connection silently.
#
# The offline t/75-txn-open-cursor.t pins the same with a mock handle.
#
# Measured 2026-10-05 (1 to 3), 2026-10-18 (4 to 8) against SAP ASE 16.0 SP02
# PL02, with DBD::Sybase 1.27 built against FreeTDS 1.3.17, TDS 5.0. What this
# file does NOT claim:
#
#   * anything about the Sybase Open Client libraries. No connection here was
#     made with them. There the FreeTDS class is not mixed in, core sends the
#     rollback with $dbh->rollback, and whether DBD::Sybase's prepare of a
#     refused dynamic statement returns a handle at all is not known. 4 to 8
#     are TODO there too, with that as the reason, so that a run with Open
#     Client reports what it finds and fails on nothing nobody has seen.
#   * that the session is the same one afterwards. A storage that hung up and
#     connected again would have rolled back as well; the session ids before
#     and after are a note.
#   * anything about a schema that names no storage_type. The schema here
#     loads the Sybase component, as a schema has to since core ADR 0067
#     (karr k90), and its storage becomes the ASE class at the first use
#     (karr k64, t/62-component-rebless-live.t). Until k90 it named none and
#     the storage was detected from the DSN: the runs described above were
#     made that way, and none with the component yet.
#   * anything about the ASE writer storage: nothing here inserts, so every
#     statement runs on the storage's own connection.
#
# The second session sets a lock wait of five seconds: ASE waits for a lock
# without limit, and a transaction left open would hang this file otherwise.
# A storage that is left inside a transaction is hung up after its case, which
# ends the transaction; the table is dropped at the end, and in END for a run
# that died on the way.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

my $live = 1;

my $TABLE = 'txn_guard_live_item';

# Cases 4 to 8 are about the FreeTDS class (karr k65); with any other client
# library they are TODO: nothing here was ever run with Open Client.
my $OPEN_OTHER = 'never run with the Sybase Open Client libraries; the '
  . 'FreeTDS class these cases are about is not mixed in there (karr k65)';

{
  package T::TxnGuard::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('txn_guard_live_item');
  __PACKAGE__->add_columns(
    n    => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('n');
}

{
  package T::TxnGuard::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Item => 'T::TxnGuard::Result::Item');
}

# Plain DBI, with the DSN as it was given: for setup, and for looking at the
# rows from a session that is not the storage's.
my $admin;
sub admin {
  return $admin ||= do {
    my $dbh = DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('set lock wait 5');
    $dbh;
  };
}

sub server_value { ( admin()->selectrow_array(@_) )[0] }

# The server's address and the login are the environment's and stay out of the
# output.
sub squashed {
  my $text = shift // '(undef)';
  $text =~ s/\b(host|port|server)=[^;\s]*/$1=../g;
  $text =~ s/\Q$pass\E/../g if length $pass;
  $text =~ s/\s+/ /g;
  return length $text > 400 ? substr($text, 0, 400) . ' ...' : $text;
}

sub table_there {
  return server_value(
    "select count(*) from sysobjects where name = '$TABLE' and type = 'U'"
  );
}

sub drop_table { admin()->do("drop table $TABLE") if table_there() }

# Three rows, as every case finds them.
sub fresh_rows {
  admin()->do("delete from $TABLE");
  admin()->do("insert into $TABLE (n, name) values ($_, 'seed $_')") for 1 .. 3;
}

# A statement the server refuses at prepare leaves DBD::Sybase a handle whose
# DESTROY warns, "(in cleanup) ... DESTROY failed: ... Prepared statement
# 'DBD<n>' does not exist". Any other warning is a finding and goes through.
my $destroy_warnings = 0;
$SIG{__WARN__} = sub {
  return $destroy_warnings++ if $_[0] =~ /DBD::Sybase::st DESTROY failed/;
  warn @_;
};

drop_table();
admin()->do(
  "create table $TABLE (n int not null primary key, name varchar(100) not null)"
);

my $schema  = T::TxnGuard::Schema->connect($dsn, $user, $pass);
my $storage = $schema->storage;
$storage->ensure_connected;   # driver resolution is lazy

isa_ok $storage, 'DBIO::Sybase::Storage::ASE',
  'the storage of the declared driver';

my $freetds = $storage->_using_freetds ? 1 : 0;
my $OPEN    = $freetds ? undef : $OPEN_OTHER;

note 'the storage is a ' . ref $storage;
note 'client library: ' . ( admin()->{syb_oc_version} || '(unknown)' );
note 'server: ' . squashed( ( split /\n/, server_value('select @@version') )[0] );

my $rs = $schema->resultset('Item');

# What the storage's own session says: (@@trancount, @@spid). Asked on the
# handle the storage holds, without a ping in between.
sub session_says {
  my @row = eval { $storage->_get_dbh->selectrow_array('select @@trancount, @@spid') };
  return @row ? @row : ( 'not answered: ' . squashed($@), '?' );
}

# The valid UPDATE of a case, and what the storage and its session say right
# after it: the change is there, and it is inside a transaction.
my @inside;
sub change_row_1 {
  $rs->search({ n => 1 })->update({ name => 'changed' });
  @inside = ( $rs->find(1)->name, ( session_says() )[0] );
}

# No UPDATE: only that a transaction is open.
sub change_nothing { @inside = ( 'seed 1', ( session_says() )[0] ) }

# Refused at prepare: the statement has a placeholder, so it is prepared as a
# dynamic statement, and the server looks at the column then. Msg 207.
sub refused_at_prepare {
  $rs->search(\'no_such_column = 1')->update({ name => 'never' });
}

# Refused at execute: row 3 is there. Msg 2601.
sub refused_at_execute { $rs->search({ n => 2 })->update({ n => 3 }) }

# A cursor on the storage's own connection, one row read and the rest left:
# an active statement handle, as a resultset somebody is still reading is. It
# is taken after the case's UPDATE: while it is open any other statement of
# the storage would go over a second connection too.
my @cursors;
sub open_cursor {
  my $sth = $storage->_get_dbh->prepare("select n from $TABLE order by n");
  $sth->execute;
  $sth->fetchrow_arrayref;
  push @cursors, $sth;
  return $sth;
}

sub close_cursors { $_->finish for splice @cursors }

my %ROLLED_BACK = (
  'transaction_depth of the storage'      => 0,
  '@@trancount of the storage\'s session' => 0,
  'row 1, read through the storage'       => 'seed 1',
  'row 1, read by a second session'       => 'seed 1',
);

# One case. $code runs a transaction that ends in an error; $inside is what
# change_row_1 or change_nothing must have seen before it; $error is what the
# caller must be handed. $todo, when given, is why the case is TODO.
sub rolled_back_after {
  my ($name, $code, $inside, $error, $todo) = @_;
  local $TODO = $todo;
  close_cursors();

  fresh_rows();
  @inside = ();

  my ( undef, $spid_before ) = session_says();

  my $died = eval { $code->(); 1 } ? '(no error)' : "$@";

  my ( $trancount, $spid_after ) = session_says();

  my %now = (
    'transaction_depth of the storage'      => $storage->transaction_depth,
    '@@trancount of the storage\'s session' => $trancount,
    'row 1, read through the storage'       =>
      ( eval { $rs->find(1)->name } // 'not answered: ' . squashed($@) ),
    'row 1, read by a second session'       =>
      ( eval { server_value("select name from $TABLE where n = 1") }
        // 'not answered: ' . squashed($@) ),
  );

  # Before anything is asserted: a storage left inside a transaction holds
  # its locks until it is hung up, and the next case needs the rows.
  my $clean = ! grep { $now{$_} ne $ROLLED_BACK{$_} } keys %ROLLED_BACK;
  $storage->disconnect unless $clean;

  like $died, $error, "$name: the error reaches the caller"
    or diag squashed($died);

  is_deeply \@inside, $inside,
    "$name: before the error row 1 read '$inside->[0]' through the storage, "
    . 'inside a transaction (@@trancount 1)';

  note "$name: session $spid_before before, $spid_after after";

  {
    local $TODO = $todo;

    is_deeply \%now, \%ROLLED_BACK,
      "$name: rolled back on the server, and the storage says what the server says"
      or diag join "\n", map { sprintf '%-40s %s', "$_:", $now{$_} } sort keys %now;
  }

  $storage->ensure_connected unless $clean;
}

# ------------------------------------------------------------- plain tests

rolled_back_after(
  'txn_do, refused at prepare',
  sub { $schema->txn_do(sub { change_row_1(); refused_at_prepare() }) },
  [ 'changed', 1 ],
  qr/no_such_column/,
);

rolled_back_after(
  'guard, refused at execute',
  sub {
    my $guard = $schema->txn_scope_guard;
    change_row_1();
    refused_at_execute();
    $guard->commit;
  },
  [ 'changed', 1 ],
  qr/duplicate key/i,
);

rolled_back_after(
  'guard, die in Perl',
  sub {
    my $guard = $schema->txn_scope_guard;
    change_row_1();
    die "no server error\n";
  },
  [ 'changed', 1 ],
  qr/\Ano server error$/,
);

# ---------------------------------------------- the FreeTDS class (karr k65)

rolled_back_after(
  'guard, refused at prepare',
  sub {
    my $guard = $schema->txn_scope_guard;
    change_row_1();
    refused_at_prepare();
    $guard->commit;
  },
  [ 'changed', 1 ],
  qr/no_such_column/,
  $OPEN,
);

rolled_back_after(
  'guard, refused at prepare, nothing changed before',
  sub {
    my $guard = $schema->txn_scope_guard;
    change_nothing();
    refused_at_prepare();
    $guard->commit;
  },
  [ 'seed 1', 1 ],
  qr/no_such_column/,
  $OPEN,
);

rolled_back_after(
  'txn_do, cursor left open, die',
  sub {
    $schema->txn_do(sub {
      change_row_1();
      open_cursor();
      die "no server error\n";
    });
  },
  [ 'changed', 1 ],
  qr/no server error/,
  $OPEN,
);

rolled_back_after(
  'guard, cursor left open, die',
  sub {
    my $guard = $schema->txn_scope_guard;
    change_row_1();
    open_cursor();
    die "no server error\n";
  },
  [ 'changed', 1 ],
  qr/\Ano server error$/,
  $OPEN,
);

# The commit is refused before it is sent, and a failed commit of the
# outermost transaction ends it (core, karr k372, k99): the cursor is finished
# and ROLLBACK goes out on the same connection. The caller gets the error of
# the COMMIT; rolled_back_after asserts depth 0, @@trancount 0, the change gone.
rolled_back_after(
  'guard, cursor left open, commit',
  sub {
    my $guard = $schema->txn_scope_guard;
    change_row_1();
    open_cursor();
    $guard->commit;
  },
  [ 'changed', 1 ],
  qr/COMMIT.*open cursor/s,
  $OPEN,
);

# BEGIN TRAN with a cursor open is refused before it is sent.
for my $way (
  [ 'txn_scope_guard' => sub { $schema->txn_scope_guard } ],
  [ 'txn_do'          => sub { $schema->txn_do(sub { change_row_1() }) } ],
) {
  my ($via, $begin) = @$way;

  local $TODO = $OPEN;

  fresh_rows();
  close_cursors();
  open_cursor();

  my $died = eval { $begin->(); 1 } ? '(no error)' : "$@";
  close_cursors();

  like $died, qr/BEGIN TRAN.*open cursor/s,
    "$via, cursor left open: BEGIN TRAN is refused, naming the cursor"
    or diag squashed($died);

  is_deeply [ $storage->transaction_depth, ( session_says() )[0] ], [ 0, 0 ],
    "$via, cursor left open: nothing was begun (depth 0, \@\@trancount 0)";

  is server_value("select name from $TABLE where n = 1"), 'seed 1',
    "$via, cursor left open: row 1 is as it was, for a second session too";
}

note "$destroy_warnings warning(s) 'DBD::Sybase::st DESTROY failed' swallowed: "
  . 'one per statement refused at prepare';

$storage->disconnect;
drop_table();

is table_there(), 0, 'nothing of this test is left on the server';

done_testing;

# The table again, on a new connection: for a run that died on the way. The
# storage first -- a transaction it left open holds a lock on the table.
END {
  if ($live) {
    local $?;
    eval { $storage->disconnect } if $storage;
    undef $admin;
    eval { drop_table(); 1 }
      or diag "Could not clean up after this test: $@";
  }
}
