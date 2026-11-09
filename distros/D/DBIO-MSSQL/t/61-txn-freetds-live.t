use strict;
use warnings;

use Test::More;
use File::Temp ();
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;
use DBIO::Storage::DBI;

# LIVE (karr k41; dbio-sybase karr k65). Where BEGIN TRAN, COMMIT and ROLLBACK
# go when the database handle has a statement handle active, and what is left
# on the server afterwards -- on SQL Server over DBD::Sybase and FreeTDS.
#
# dbio-sybase measured this on ASE (t/64-txn-scope-guard-live.t there): its
# FreeTDS class sends the three statements with $dbh->do, DBD::Sybase runs a
# statement on a handle with an active statement over a second connection, and
# the session of the transaction never sees it. DBIO::MSSQL::Storage::Sybase
# has the same class mixed in. This file is the same question put to SQL
# Server, on two ways:
#
#   direct   a schema whose storage is pinned to DBIO::MSSQL::Storage::Sybase
#            itself (storage_type): on dbi:Sybase: the storage ends as
#            DBIO::MSSQL::Storage::Sybase::FreeTDS. Its transaction
#            statements are DBIO::Sybase::Storage::FreeTDS's, $dbh->do.
#   pinned   a schema that loaded the MSSQL component: the storage is pinned
#            to DBIO::MSSQL::Storage and adapts itself to the access path at
#            its first use (karr k37; core k301, ADR 0059) -- over DBD::Sybase
#            into that same class, with the same transaction statements.
#
# and on two forms of the DSN, because a second connection is where they
# differ (t/60): host=..;port=.., and a server named in a freetds.conf.
#
# THE TWO WAYS ARE ONE CLASS NOW, AND EVERY CASE HAS ONE EXPECTATION FOR BOTH.
# That is the claim this file makes about the pinned way: whatever the
# DBD::Sybase class does with a transaction, a schema that declares the
# driver gets exactly that -- no better and no worse. It was not so when this
# file was written (2026-10-05): the pinned storage stayed the base class,
# sent its transaction statements through core ($dbh->begin_work, ->commit,
# ->rollback), and failed in its own way in six of the ten cases. What it did
# then is at the end of this comment; it is not tested here any more, because
# a schema that declares the driver no longer gets that class on this DBD.
#
# CLAIMED: a transaction ends on the server when the storage says it has
# ended, and it ends one way. After a transaction that ended in an error
#
#   * transaction_depth of the storage is 0,
#   * the session the transaction began on has no transaction open,
#   * a second session reads the row changed inside as it was before -- so no
#     lock is left on it,
#   * the storage reads it so too,
#   * it still reads so once the storage has hung up,
#   * the body of the transaction ran once,
#   * and no UPDATE of it was done while that session had no transaction
#     open: a change made outside the transaction is not undone by rolling
#     it back, and looks committed whatever becomes of the COMMIT.
#
# After a commit the same holds with the change in the place of the old
# value and no error -- or the commit is refused, and then as above. Every
# case is one such comparison, all seven at once: any one of them alone can
# be right while the transaction is not over. What was seen inside the
# transaction is a test of its own in every case, a rollback of nothing
# proves nothing.
#
# Where a case does not end like that, what it ends like IS a plain test too,
# so that whoever changes it has to touch that line knowingly, and the claim
# is a TODO test beside it. The error the caller is handed is a plain test in
# every case.
#
# THE DECISION THESE CASES MEASURE (maintainer, 2026-10-18; dbio-sybase karr
# k65, here karr k43): DBIO::Sybase::Storage::FreeTDS no longer sends BEGIN
# TRAN, COMMIT or ROLLBACK past an active statement handle (an open cursor) --
# DBD::Sybase would run them on a second connection, outside the transaction.
#
#   * ROLLBACK -- that of a guard and of txn_do too -- finishes every active
#     statement handle of the connection and rolls back on the same
#     connection. The price: a cursor read across a rollback is over, its next
#     ->next returns nothing, without an error. Tested in 6, 7 and 8.
#   * BEGIN TRAN THROWS, before anything is sent. The storage is as it was:
#     transaction_depth, the open transaction, the locks. Nothing changes on
#     the server and the body of a txn_do does not run.
#   * COMMIT throws the same way, before anything is sent, and core treats it
#     like any failed commit of the outermost transaction (karr k372): the
#     storage rolls back on the same connection, which ends the cursor, and
#     transaction_depth is 0. Tested in 8.
#
# The tests of this file used to pin what happened before, a transaction
# that stayed open on a stray COMMIT/ROLLBACK (Msg 3902/3903 from another
# session), a body that ran twice, an UPDATE committed outside any
# transaction. Those claims are replaced, not weakened: the claim above is
# the same, and 6, 7, 9 and 10 now meet it as plain tests where they were
# TODO tests (the IS lines that described the defects are gone with them).
#
# 8, a guard whose commit is refused, follows core's rule for a failed commit
# of the outermost transaction (karr k372, 2026-10-26): the commit throws as
# decided, the storage rolls the transaction back, the row is free again and
# the caller is handed the refusal of the COMMIT. A plain test for each of the
# four combinations of way and form.
#
# THE CASES, and what each does now (the defects they had, as measured on
# 2026-10-05 and 2026-10-07 on both ways and forms, are listed at the end of
# this comment):
#
#    1. txn_do, an UPDATE, a statement the server refuses at prepare
#       (Msg 207).                                   Clean.
#    2. guard, an UPDATE, a statement refused at execute (Msg 2627).
#                                                    Clean.
#    3. guard, an UPDATE, a die in Perl.             Clean.
#    4. guard, an UPDATE, the statement of 1.        Clean.
#    5. guard, the statement of 1 and nothing before it.
#                                                    Clean.
#       4 AND 5 ARE THE TWO CASES THAT ARE RED ON ASE. They are green here:
#       see a.
#    6. txn_do, an UPDATE, a cursor left open, die.
#       Clean: the caller gets its own exception, nothing else, the body ran
#       once, depth 0, nothing open or locked. The cursor is over.
#    7. guard, an UPDATE, a cursor left open, die.
#       Clean, as 6, and no warning.
#    8. guard, an UPDATE, a cursor left open, $guard->commit.
#       commit throws "Cannot COMMIT while a statement handle ... is still
#       active", and the storage rolls back (karr k372). Clean: the caller
#       gets the refusal, depth 0, nothing open or locked, no UPDATE. The
#       cursor is over.
#    9. a cursor left open, THEN txn_do with an UPDATE.
#       BEGIN TRAN throws, the body does not run, nothing is sent: depth 0,
#       no transaction, no UPDATE -- on the host and port form and on the named
#       server alike.
#   10. a cursor left open, THEN guard, an UPDATE, die.
#       As 9; the guard is never made.
#
# THE DEFECTS THESE CASES HAD (karr k41), kept as the reason for the decision.
# Traced on the direct way (DBI trace level 4; the CS_CONNECTION each
# statement was sent on is in it) with the FreeTDS class as it was, $dbh->do for
# all three statements:
#
#   a. The refused statement of 1, 4 and 5 leaves no statement handle here.
#      On ASE (TDS 5.0) DBD::Sybase's prepare of a dynamic statement the
#      server refuses returns a handle, marked active, and that handle is
#      what sends the guard's ROLLBACK astray. On SQL Server (TDS 7.4) the
#      same prepare fails in DBD::Sybase: the trace has "prepare= ( undef )"
#      and "DESTROY ... ignored - handle not initialised", and the ROLLBACK
#      after it is sent on the CS_CONNECTION the BEGIN TRAN was sent on. So
#      4 and 5 do not hit the FreeTDS class here.
#   b. An open cursor does, 6 to 8: "syb_st_prepare() parent has active kids
#      - opening new connection", a new CS_CONNECTION, ROLLBACK or COMMIT
#      executed on it, "syb_st_destroy(): connection closed". That is what
#      ASE does. What differs is the answer: ASE takes a ROLLBACK or COMMIT
#      without a transaction in silence, SQL Server answers Msg 3903 or 3902,
#      "... request has no corresponding BEGIN TRANSACTION". So txn_rollback
#      and txn_commit throw, and the storage does not count down: it says 1
#      and the server says 1, where on ASE it said 0. The error names a
#      missing BEGIN, which is true of the session it came from and not of
#      the one the caller knows.
#   c. In 7 that error reaches nobody: the caller is handed its own
#      exception, and there is no warning. Read in core's TxnScopeGuard, not
#      traced: its DESTROY catches the failed rollback and, for an exception
#      that is a plain string, writes "Transaction aborted ... Rollback
#      failed" to $@ -- which is not what the caller's eval ends up with.
#   d. BEGIN TRAN goes the same way, 9 and 10: with a cursor open it is
#      sent on a new connection, which is closed after it. No error: a BEGIN
#      TRAN is valid anywhere. The storage counts up to 1; its session has
#      no transaction. What follows depends on the DSN. A named server: the
#      UPDATE gets a connection of its own as well and is committed there at
#      once, the COMMIT gets a third and is answered Msg 3902, the ROLLBACK
#      a fourth, Msg 3903. Host and port: the second connection is made all
#      the same -- `use <database>` is answered on it -- but leaves client
#      message 44, "Server name not found in configuration files", on the
#      handle. Inside do() the execute clears it, which is why BEGIN TRAN,
#      COMMIT and ROLLBACK go through on this form too; core's own prepare
#      is handed it as the statement's error (t/60 has that for a SELECT),
#      so the UPDATE is refused.
#
#   Also MEASURED BESIDE THIS FILE (2026-10-05, the direct way): with every
#   active statement handle of the database handle finished before BEGIN
#   TRAN, COMMIT and ROLLBACK are sent, 6 to 10 ended clean, on both forms of
#   the DSN, each statement on the session of the transaction. That
#   measurement is what dbio-sybase karr k65 decided on, in a variant: only
#   ROLLBACK finishes the handles, BEGIN TRAN and COMMIT throw.
#
#   And MEASURED BESIDE THIS FILE (2026-10-05): the direct way told to use no
#   placeholders, which makes it DBIO::MSSQL::Storage::Sybase::NoBindVars
#   with the FreeTDS class. The statement of 1 is refused at execute there,
#   not at prepare; 1, 4 and 5 are clean, 6 and 8 end as they do here.
#
# WHAT THE PINNED WAY DID BEFORE IT ADAPTED (measured 2026-10-05, plain and
# TODO tests of this file until 2026-10-07; karr k42 and k43 were written
# from it). It is what DBIO::MSSQL::Storage does on a DBD::Sybase handle with
# core's transaction statements, and a storage of that class is reached today
# only by pinning a private subclass of it by hand:
#
#   * 5 (karr k42): "Rollback failed", Msg 3903, and transaction_depth stayed
#     1 with nothing open on the server. DBD::Sybase runs a transaction as
#     SET IMPLICIT_TRANSACTIONS ON, so the server opens it with the first
#     statement that touches a table; the refused statement never ran, and
#     the ROLLBACK TRAN DBD::Sybase sends nevertheless found nothing. A
#     txn_do whose body ran no statement at all threw at its commit
#     (Msg 3902).
#   * 6 to 8 (karr k43): DBD::Sybase sends COMMIT TRAN and ROLLBACK TRAN
#     itself, on the connection of the database handle, and with a result
#     set pending there the client library refuses (message 51). Nothing
#     went to a second connection and nothing reached the server; the caller
#     got a DBD::Sybase panic ("can't change AutoCommit ... with active
#     statement handles"). In 6, txn_do then took the connection for lost --
#     its ping threw on that handle -- connected again and ran the body a
#     SECOND time, which waited for the lock the first run still held; the
#     caller got that lock timeout (Msg 1222) in the place of its own
#     exception.
#   * 9 and 10: begin_work was refused with the same panic. Nothing begun,
#     the body did not run. Clean -- the one thing the base class did better
#     than the class the pinned way has now, which sends BEGIN TRAN to a
#     second connection there (d).
#
# Measured against SQL Server 2022 (16.0.4295.3), DBD::Sybase 1.27 built
# against FreeTDS 1.3.17, TDS 7.4 on both forms of the DSN. What this file
# does NOT claim:
#
#   * anything about DBD::ODBC. No connection here goes through it.
#   * anything about another client library or another version of these.
#     Without FreeTDS the FreeTDS class is not mixed in, and this file skips.
#     That a refused prepare leaves no statement handle (a) is how this
#     DBD::Sybase and this protocol version were seen to behave; a setup
#     where it leaves one would make 4 and 5 what they are on ASE, and they
#     would fail here as plain tests, which is what they are for.
#   * that a commit with a cursor open is anything but refused: the claim above
#     takes "committed, or refused with nothing left open" for a commit, and
#     a refused commit rolls the transaction back (8).
#   * that a second session never waits where READ_COMMITTED_SNAPSHOT is on.
#     The second session reads WITH (READCOMMITTEDLOCK), which asks for the
#     lock whatever the database option says; the option was off in every
#     run, so that this hint does what it is there for was not seen.
#   * that the session of a transaction is the same one afterwards. "The
#     session the transaction began on" is the session id read before the
#     case, and what the server says of it is
#     sys.dm_exec_sessions.open_transaction_count, read from the second
#     session: the storage's own handle cannot be asked while a cursor is
#     open on it, that question would go to a second connection too. Where
#     no cursor is open yet, @@TRANCOUNT is read through the handle beside
#     it, and the two agree.
#
# Nothing here may wait for a lock without a limit: the second session and
# every storage set LOCK_TIMEOUT, and the whole file is under an alarm with
# no handler, which ends the process whatever it is blocked in. A statement
# DBD::Sybase sends over a second connection has no lock timeout -- it is a
# new login -- and that alarm is what stands behind it.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_MSSQL_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_sybase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_sybase');

# Only "not installed" is a reason to skip. A DBIO::Sybase that is there and
# does not load is a failure, and so is this distribution's own class on top
# of it -- neither may hide behind a skip.
unless (eval { require DBIO::Sybase::Storage::FreeTDS; 1 }) {
  die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage(?:/FreeTDS)?\.pm };

  plan skip_all => 'Test needs DBIO::Sybase (optional, cpanfile recommends): '
    . 'the transaction statements under test are its FreeTDS class\'s';
}

require DBIO::MSSQL::Storage::Sybase;

# Host and port come out of the DSN: the named server of the second form is
# written from them, so that both forms provably go to the same place.
my %dsn_part = $dsn =~ /\Adbi:Sybase:(.*)\z/s
  ? ( map { /\A([^=]+)=(.*)\z/s ? ($1 => $2) : ($_ => '') } split /;/, $1 )
  : ();
my ($host, $port, $dbname) = @dsn_part{qw(host port database)};

plan skip_all => 'This test compares the host and port form of the DSN with '
  . 'a named server it writes from them; $ENV{DBIO_TEST_MSSQL_DSN} must be '
  . 'exactly dbi:Sybase:host=<host>;port=<port>;database=<database> '
  . '(nothing else, no server=<name>)'
  unless keys %dsn_part == 3
    and 3 == grep { defined && length } $host, $port, $dbname;

# The whole file, whatever it is blocked in. No handler: Perl would run one
# only between two operations, and a read on a socket is one operation.
alarm 600;

my $TABLE   = 'k41_live_item';
my $LOCK_MS = 3000;

{
  package T::K41::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k41_live_item');
  __PACKAGE__->add_columns(
    n    => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('n');
}

{
  package T::K41::Pinned;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
}

{
  # Pinned to the DBD::Sybase class itself: a schema always declares its
  # driver (core ADR 0067).
  package T::K41::Direct;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::MSSQL::Storage::Sybase');
}

$_->register_class(Item => 'T::K41::Result::Item')
  for qw(T::K41::Pinned T::K41::Direct);

my %SCHEMA_CLASS = ( direct => 'T::K41::Direct', pinned => 'T::K41::Pinned' );

# The server's address, its name and the login are the environment's and stay
# out of the output.
sub hidden {
  my $text = shift // '(undef)';
  $text =~ s/\b(host|port|server)=[^;\s]*/$1=../g;
  $text =~ s/\Q$pass\E/../g if length $pass;
  $text =~ s/\s+/ /g;
  $text =~ s/ \z//;
  return $text;
}

sub squashed {
  my $text = hidden(shift);
  return length $text > 400 ? substr($text, 0, 400) . ' ...' : $text;
}

# Plain DBI, with the DSN as it was given: for setup, and for looking at the
# rows and the sessions from a session that is not the storage's. It never
# has two statements at once.
my $admin;
sub admin {
  return $admin ||= do {
    my $dbh = DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do("SET LOCK_TIMEOUT $LOCK_MS");
    $dbh;
  };
}

sub server_value { ( admin()->selectrow_array(@_) )[0] }

plan skip_all => 'This test is about DBD::Sybase built against FreeTDS: '
  . 'without it the FreeTDS class is not mixed into the storage'
  unless ( admin()->{syb_oc_version} || '' ) =~ /freetds/i;

plan skip_all => 'This test reads sys.dm_exec_sessions for another session; '
  . 'the login needs VIEW SERVER STATE'
  unless server_value(q{SELECT HAS_PERMS_BY_NAME(NULL, NULL, 'VIEW SERVER STATE')});

my $live = 1;   # past every skip_all: from here on there is something to drop

sub table_there { server_value("SELECT COUNT(*) FROM sys.tables WHERE name = '$TABLE'") }

sub drop_table { admin()->do("DROP TABLE $TABLE") if table_there() }

# Three rows, as every case finds them.
sub fresh_rows {
  admin()->do("DELETE FROM $TABLE");
  admin()->do("INSERT INTO $TABLE (n, name) VALUES ($_, 'seed $_')") for 1 .. 3;
}

# How many transactions the server says a session has open; 'gone' when the
# session is not there any more. Never asked of the session itself.
sub open_transactions_of {
  my $spid = shift;
  return server_value(
    'SELECT open_transaction_count FROM sys.dm_exec_sessions WHERE session_id = ?',
    undef, $spid,
  ) // 'gone';
}

my $WAITS = 'waits for a lock until its timeout (Msg 1222)';

# Row 1 as a second session reads it, asking for the lock whatever
# READ_COMMITTED_SNAPSHOT says.
sub second_session_reads {
  my $name = eval {
    server_value("SELECT name FROM $TABLE WITH (READCOMMITTEDLOCK) WHERE n = 1");
  };
  return $name if defined $name;
  return $@ =~ /number=1222\b/ ? $WAITS : 'not answered: ' . squashed($@);
}

# Warnings that are part of what is measured. Anything else is a finding: it
# goes through, and the last test of the file fails on it -- core's "Driver
# mismatch" for the pinned way above all, which every pinned storage got at
# its first use until it adapted to the access path.
my @KNOWN_WARNING = (
  # the DBD::Sybase class's own notice, once per process
  [ 'FreeTDS notice' => qr/compiled against buggy FreeTDS version/ ],
  # DBD::Sybase, for a statement the server refuses at prepare
  [ 'refused prepare'
      => qr/ct_result\(ct_dynamic\(CS_PREPARE\)\) returned -205/ ],
);
my (%known_warnings, @other_warnings);
local $SIG{__WARN__} = sub {
  my $warning = $_[0];
  for my $known (@KNOWN_WARNING) {
    return $known_warnings{ $known->[0] }++ if $warning =~ $known->[1];
  }
  push @other_warnings, squashed($warning);
  warn hidden($warning) . "\n";
};

# ------------------------------------------------- the two forms of the DSN

my $NAMED = 'k41_live_named';

my $conf = File::Temp->new(SUFFIX => '.conf');
print {$conf} "[$NAMED]\n\thost = $host\n\tport = $port\n\ttds version = 7.4\n";
close $conf or die "Cannot write the temporary freetds.conf: $!";

# FREETDSCONF is read at every connect -- the ones DBD::Sybase makes on its
# own as well -- so it is set for as long as a storage of that form lives.
my @FORMS = (
  { name => 'host and port', dsn => $dsn },
  {
    name => 'named server',
    dsn  => "dbi:Sybase:server=$NAMED;database=$dbname",
    conf => "$conf",
  },
);

# ------------------------------------------------------- what a case does

# Set for each case.
my ($schema, $storage, $rs, $cursor, @inside, $body_ran, $unprotected);

sub trancount_through_the_handle {
  return ( $storage->_get_dbh->selectrow_array('SELECT @@TRANCOUNT') )[0];
}

my $began_on;   # session id of the storage, read before the case

# The valid UPDATE of a case, and what is seen right after it: the change is
# there, and it is inside a transaction -- says the session itself, and says
# the server of that session. Only where no cursor is open.
sub change_row_1 {
  $rs->search({ n => 1 })->update({ name => 'changed' });
  @inside = (
    $rs->find(1)->name,
    trancount_through_the_handle(),
    open_transactions_of($began_on),
  );
  $unprotected++ unless $inside[-1];
}

# With a cursor open the storage's handle cannot be asked, so this is the
# server's word alone: is there a transaction, before the UPDATE and after?
sub change_row_1_beside_a_cursor {
  @inside = ( open_transactions_of($began_on) );
  $rs->search({ n => 1 })->update({ name => 'changed' });
  push @inside, open_transactions_of($began_on);
  $unprotected++ unless $inside[-1];
}

# No statement at all, not even a SELECT: the case is about a transaction
# nothing ran in.
sub change_nothing { @inside = ( open_transactions_of($began_on) ) }

# Refused at prepare: the statement has a placeholder, so it is prepared as a
# dynamic statement, and the server looks at the column then. Msg 207.
sub refused_at_prepare {
  $rs->search(\'no_such_column = 1')->update({ name => 'never' });
}

# Refused at execute: row 3 is there. Msg 2627.
sub refused_at_execute { $rs->search({ n => 2 })->update({ n => 3 }) }

# A result set read with ->next and not to its end: three rows, one fetched.
sub leave_a_cursor_open {
  $cursor = $rs->search({}, { order_by => 'n' });
  my $n = $cursor->next->n;
  die "the cursor did not start at row 1 but at $n\n" unless $n == 1;
}

my @STATE = (
  'transaction_depth of the storage',
  'open transactions of the session it began on',
  'row 1, read by a second session',
  'row 1, read through the storage',
  'row 1, once the storage has hung up',
  'times the body of the transaction ran',
  'UPDATEs done with no transaction open there',
);

sub state_of { my %state; @state{@STATE} = @_; return \%state }

sub described {
  my $state = shift;
  return join "\n", map { sprintf '%-48s %s', "$_:", $state->{$_} } @STATE;
}

# The claim. $ends is how the case ends, 'error' or 'commit'.
sub ended_clean {
  my ($ends, $died, $state) = @_;

  my ($depth, $open, $second, $through, $after, $ran, $unprotected)
    = @{$state}{@STATE};

  return 0 unless $depth eq '0' and $open eq '0' and $unprotected eq '0';
  return 0 unless $second eq $through and $through eq $after;

  # refused or failed: as it was before, and not run more than once
  return $second eq 'seed 1' && $ran <= 1 if $died ne '(no error)';

  return $ends eq 'commit' && $second eq 'changed' && $ran == 1;
}

# One case on one way and one form of the DSN.
sub run_case {
  my ($label, $way, $form, $case) = @_;

  # One expectation for both ways: they are the same class.
  my $expect = $case->{expect};
  $expect = $expect->{ $form->{name} } unless exists $expect->{error};

  my $name = "$label, $case->{name}";

  fresh_rows();
  ( @inside, $cursor ) = ();
  $body_ran = $unprotected = 0;

  $schema = $SCHEMA_CLASS{$way}->connect($form->{dsn}, $user, $pass, {
    on_connect_do => [ "SET LOCK_TIMEOUT $LOCK_MS" ],
  });
  $storage = $schema->storage;
  $storage->ensure_connected;
  $rs = $schema->resultset('Item');

  $began_on = ( $storage->_get_dbh->selectrow_array('SELECT @@SPID') )[0];

  my $died = eval { $case->{code}->(); 1 } ? '(no error)' : hidden("$@");

  # In this order: the first three with the cursor of the case still open,
  # as its caller would have it -- and none of them through the storage's
  # handle, where a statement would go to a second connection now.
  my @now = (
    $storage->transaction_depth,
    open_transactions_of($began_on),
    second_session_reads(),
  );

  # The price of the rollback that ended the cursor: it is over, and says so
  # by returning nothing.
  my $after_rollback;
  if ($expect->{cursor_ended}) {
    my $row = eval { $cursor->next };
    $after_rollback = $@ ? 'an error: ' . squashed($@)
                    : defined $row ? 'a row' : 'nothing';
  }

  undef $cursor;

  push @now,
    eval { $rs->find(1)->name } // 'not answered: ' . squashed($@);

  # A storage left inside a transaction holds its locks until it has hung
  # up, and the next case needs the rows.
  eval { $storage->disconnect; 1 }
    or diag "$name: disconnect failed: " . squashed($@);

  push @now, second_session_reads(), $body_ran, $unprotected;

  my $now = state_of(@now);

  like $died, $expect->{error}, "$name: the caller is handed "
    . ( $expect->{error_is} || 'the error of the transaction' )
    or diag squashed($died);

  is_deeply \@inside, $expect->{inside},
    "$name: inside, " . $expect->{inside_is};

  is $after_rollback, 'nothing',
    "$name: the cursor read across the rollback is over -- next returns "
  . 'nothing, without an error'
    if $expect->{cursor_ended};

  if (my $is = $expect->{is}) {
    is_deeply $now, state_of(@$is), "$name IS: $expect->{is_is}"
      or diag described($now);
  }

  {
    local $TODO = $expect->{todo};

    die "$name: an expectation without a reason, or a reason without one\n"
      if !!$expect->{is} != !!$expect->{todo};

    ok ended_clean($case->{ends}, $died, $now),
      "$name" . ( $TODO ? ' SHOULD' : '' ) . ': '
      . ( $case->{ends} eq 'commit'
          ? 'the transaction is over, committed or refused -- on the server '
          . 'as the storage says'
          : 'the transaction is over and rolled back -- on the server as '
          . 'the storage says' )
      or diag described($now);
  }

  ( $schema, $storage, $rs ) = ();
}

# What 1 to 4 and 6 to 8 see inside.
my %CHANGED_INSIDE = (
  inside    => [ 'changed', 1, 1 ],
  inside_is => 'row 1 read \'changed\' through the storage, in a transaction '
             . '(@@TRANCOUNT 1, and the server says 1 of that session)',
);

my $COMMIT_REFUSED = qr/Cannot COMMIT while a statement handle of the connection is still active \(an open cursor\)/;
my $BEGIN_REFUSED  = qr/Cannot BEGIN TRAN while a statement handle of the connection is still active \(an open cursor\)/;

my @CASES = (
  # ----------------------------------------------------------- 1 to 5
  {
    name => '1. txn_do, UPDATE, refused at prepare',
    ends => 'error',
    code => sub {
      $schema->txn_do(sub { $body_ran++; change_row_1(); refused_at_prepare() });
    },
    expect => { error => qr/no_such_column/, %CHANGED_INSIDE },
  },
  {
    name => '2. guard, UPDATE, refused at execute',
    ends => 'error',
    code => sub {
      my $guard = $schema->txn_scope_guard;
      $body_ran++;
      change_row_1();
      refused_at_execute();
      $guard->commit;
    },
    expect => { error => qr/duplicate key/i, %CHANGED_INSIDE },
  },
  {
    name => '3. guard, UPDATE, die in Perl',
    ends => 'error',
    code => sub {
      my $guard = $schema->txn_scope_guard;
      $body_ran++;
      change_row_1();
      die "no server error\n";
    },
    expect => { error => qr/\Ano server error\z/, %CHANGED_INSIDE },
  },
  {
    name => '4. guard, UPDATE, refused at prepare',
    ends => 'error',
    code => sub {
      my $guard = $schema->txn_scope_guard;
      $body_ran++;
      change_row_1();
      refused_at_prepare();
      $guard->commit;
    },
    expect => { error => qr/no_such_column/, %CHANGED_INSIDE },
  },
  {
    name => '5. guard, refused at prepare, nothing before it',
    ends => 'error',
    code => sub {
      my $guard = $schema->txn_scope_guard;
      $body_ran++;
      change_nothing();
      refused_at_prepare();
      $guard->commit;
    },
    expect => {
      error     => qr/no_such_column/,
      inside    => [ 1 ],
      inside_is => 'the server says the session has a transaction open: '
                 . 'BEGIN TRAN was sent',
    },
  },

  # ------------------------------- 6 to 8: a cursor opened in the transaction
  {
    name => '6. txn_do, UPDATE, open cursor, die',
    ends => 'error',
    code => sub {
      $schema->txn_do(sub {
        $body_ran++;
        change_row_1();
        leave_a_cursor_open();
        die "no server error\n";
      });
    },
    expect => {
      error    => qr/\A(?!.*Rollback failed).*no server error/s,
      error_is => 'its own exception, and no word of a failed rollback',
      %CHANGED_INSIDE,
      cursor_ended => 1,
    },
  },
  {
    name => '7. guard, UPDATE, open cursor, die',
    ends => 'error',
    code => sub {
      my $guard = $schema->txn_scope_guard;
      $body_ran++;
      change_row_1();
      leave_a_cursor_open();
      die "no server error\n";
    },
    expect => {
      error    => qr/\Ano server error\z/,
      error_is => 'its own exception and no word of a rollback',
      %CHANGED_INSIDE,
      cursor_ended => 1,
    },
  },
  {
    name => '8. guard, UPDATE, open cursor, commit',
    ends => 'commit',
    code => sub {
      my $guard = $schema->txn_scope_guard;
      $body_ran++;
      change_row_1();
      leave_a_cursor_open();
      $guard->commit;
    },
    expect => {
      error    => $COMMIT_REFUSED,
      error_is => 'the refusal of the commit, named: an open cursor -- commit '
                . 'does not return as if it had committed',
      %CHANGED_INSIDE,
      cursor_ended => 1,
    },
  },

  # --------------------- 9 and 10: a cursor open before the transaction begins
  {
    name => '9. open cursor, then txn_do, UPDATE',
    ends => 'commit',
    code => sub {
      leave_a_cursor_open();
      $schema->txn_do(sub { $body_ran++; change_row_1_beside_a_cursor() });
    },
    expect => {
      error     => $BEGIN_REFUSED,
      error_is  => 'the refusal of BEGIN TRAN, named: an open cursor',
      inside    => [],
      inside_is => 'nothing: the body did not run',
    },
  },
  {
    name => '10. open cursor, then guard, UPDATE, die',
    ends => 'error',
    code => sub {
      leave_a_cursor_open();
      my $guard = $schema->txn_scope_guard;
      $body_ran++;
      change_row_1_beside_a_cursor();
      die "no server error\n";
    },
    expect => {
      error     => $BEGIN_REFUSED,
      error_is  => 'the refusal of BEGIN TRAN, named: an open cursor',
      inside    => [],
      inside_is => 'nothing: the guard was never made',
    },
  },
);

# ------------------------------------------------------------------ the run

drop_table();   # what a run that died before its END block may have left

admin()->do(
  "CREATE TABLE $TABLE (n INT NOT NULL PRIMARY KEY, name VARCHAR(100) NOT NULL)"
);

note 'client library: ' . admin()->{syb_oc_version};
note 'server: ' . squashed( ( split /\n/, server_value('SELECT @@VERSION') )[0] );
note 'READ_COMMITTED_SNAPSHOT of the database: ' . server_value(
  'SELECT is_read_committed_snapshot_on FROM sys.databases WHERE name = DB_NAME()'
);

for my $form (@FORMS) {
  local $ENV{FREETDSCONF} = $form->{conf} if $form->{conf};

  for my $way (qw(direct pinned)) {
    my $label = "$way, $form->{name}";

    # Driver resolution is lazy: connected first, looked at then.
    {
      my $probe = $SCHEMA_CLASS{$way}->connect($form->{dsn}, $user, $pass)->storage;
      $probe->ensure_connected;

      my ($database, $tds) = $probe->_get_dbh->selectrow_array(
        'SELECT DB_NAME(), CONVERT(VARCHAR(20), CONVERT(VARBINARY(4), protocol_version), 1) '
      . 'FROM sys.dm_exec_connections WHERE session_id = @@SPID'
      );

      is $database, $dbname, "$label: connected, to the database of the DSN";

      note "$label: TDS protocol version $tds";

      is ref $probe, 'DBIO::MSSQL::Storage::Sybase::FreeTDS',
        "$label: the storage is the DBD::Sybase transport class with the "
      . 'FreeTDS class mixed in'
      . ( $way eq 'pinned' ? ' -- adapted from the class the component pinned' : '' );

      is $probe->can("_exec_txn_$_"),
         DBIO::Sybase::Storage::FreeTDS->can("_exec_txn_$_"),
        "$label: its _exec_txn_$_ is DBIO::Sybase::Storage::FreeTDS's"
        for qw(begin commit rollback);

      $probe->disconnect;
    }

    run_case($label, $way, $form, $_) for @CASES;
  }
}

# ================================================================ the end

note 'known warnings swallowed: '
  . join ', ', map { "$known_warnings{$_} x $_" } sort keys %known_warnings;

is_deeply \@other_warnings, [], 'no warning but the ones named in this file';

drop_table();

is table_there(), 0, 'nothing of this test is left in the database';

is server_value(
     'SELECT COUNT(*) FROM sys.dm_exec_sessions '
   . 'WHERE is_user_process = 1 AND session_id <> @@SPID '
   . 'AND open_transaction_count > 0 AND login_name = SUSER_SNAME() '
   . 'AND program_name = (SELECT program_name FROM sys.dm_exec_sessions '
   . 'WHERE session_id = @@SPID)'
   ), 0,
  'and no session of it is left with a transaction open';

alarm 0;

done_testing;

# The table again, on a new connection: for a run that died on the way. The
# storage and the cursor first -- a transaction left open holds a lock on the
# table.
END {
  if ($live) {
    local $?;
    undef $cursor;
    eval { $storage->disconnect } if $storage;
    undef $admin;
    eval { drop_table(); 1 }
      or diag 'Could not clean up after this test: ' . squashed($@);
  }
}
