use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed refaddr );

# OFFLINE test for karr k74 (decision (b), 2026-10-09; ADR 0062 in core): a
# statement the SERVER refused fails its Future with a DBIO::Exception::Server
# -- sqlstate, constraint, table, detail -- that stringifies to the very text
# the Future failed with before. Whatever did not come from the server stays a
# plain string without a SQLSTATE.
#
# WHY the distinction is the heart of it: EV::Pg sets error_fields right before
# it calls a statement's callback, but ONLY for a PGRES_FATAL_ERROR result
# (Pg.xs 0.02 and 0.07). On "connection lost", "pipeline aborted", "connection
# finished", "empty query", a croak at dispatch and after a reset the hash is
# still the one of the PREVIOUS error. A transport that attached error_fields
# to every failure would hand a caller the SQLSTATE of a statement that is long
# gone -- a connection lost after a deadlock would look like a deadlock. The
# transport tells a fresh error from a stale one by the text: only a server's
# error begins with the severity and the primary message of error_fields.
#
# The claims, each one against the callbacks of the real storage code with
# EV::Pg as the single substitution (as in t/97):
#   1. a server error on the pooled path is the object, with all four fields,
#      and compares as the text: eq, =~, and as the one value on_fail gets.
#   2. the text is the server's in whatever lc_messages: "FEHLER:  ..." is
#      judged by the severity error_fields carries, not by "ERROR".
#   3. a failure that is not the server's -- connection lost, pipeline aborted,
#      connection finished, empty query, the dispatch croak -- is a string with
#      no SQLSTATE, also when the connection holds the error_fields of an
#      earlier server error (the stale case).
#   4. the next server error carries its own fields, not the earlier ones.
#   5. a field the server did not send is undef; a verbose message
#      ("ERROR:  23505: ...") is still the server's.
#   6. the same on the pinned path, inside txn_do_async (the object reaches the
#      caller of txn_do_async as the same object), for notify, and for a COPY
#      the server refused; a COPY that ends with the coderef's own error ends
#      with that, whatever error_fields holds.
#   7. an EV::Pg without error_fields keeps the string.
#   8. where core puts its own words in front -- "BEGIN failed: ...",
#      "COMMIT failed: ...", "Transaction aborted: ... Rollback failed: ..." --
#      the server's object is kept, as a derived copy of the same class with
#      the same fields and a context (BEGIN, COMMIT, ROLLBACK), stringifying
#      with the prefix (core k335, ADR 0062).
#
# THE ONE SUBSTITUTION is EV::Pg: a fake the real pool builds through its real
# constructor. It answers nothing by itself; the test fires the callbacks it
# queued, and decides what error_fields holds when it does.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our @SENT;      # every statement sent: { pg, sql, cb }
  our $REFUSE;    # true: a dispatch croaks "not connected" (EV::Pg does, before it queues)
  my $ID = 0;

  sub new {
    my ($class, %args) = @_;
    my $self = bless { on_connect => $args{on_connect}, up => 0, id => ++$ID }, $class;
    Scalar::Util::weaken(my $weak = $self);
    my $t;
    $t = EV::timer(0.001, 0, sub {
      undef $t;
      return unless $weak;
      $weak->{up} = 1;
      $weak->{on_connect}->() if $weak->{on_connect};
    });
    return $self;
  }

  sub is_connected  { $_[0]{up} ? 1 : 0 }
  sub pending_count { 0 }
  sub socket        { -1 }
  sub error_message { undef }
  sub finish        { $_[0]{up} = 0; return }
  sub error_fields  { $_[0]{fields} }

  sub _send {
    my ($self, $sql, $cb) = @_;
    Carp::croak('not connected') if $REFUSE || !$self->{up};
    push @SENT, { pg => $self, sql => $sql, cb => $cb };
    return;
  }

  sub query_params { my ($self, $sql, $bind, $cb) = @_; $self->_send($sql, $cb) }
  sub query        { my ($self, $sql, $cb) = @_; $self->_send($sql, $cb) }
  sub put_copy_data { 1 }
  sub put_copy_end  { 1 }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Storage;

# These tests are not about the session reset of a pool connection (karr k99):
# NoSessionReset puts the connection back at once, as before the reset existed.
use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;
use DBIO::PostgreSQL::EV::Pool;
use DBIO::Exception::Server ();

alarm 60;

my @SELECT = ('thing', [qw( id name )], {});

sub settle {
  my $done = 0;
  EV::now_update();
  my $t = EV::timer(0.02, 0, sub { $done = 1 });
  EV::run(EV::RUN_ONCE()) until $done;
  return;
}

sub until_sent {
  my ($n) = @_;
  my $deadline = EV::time() + 2;
  settle() while @EV::Pg::SENT < $n && EV::time() < $deadline;
  settle();
  return;
}

sub new_storage {
  my $storage = DBIO::PostgreSQL::EV::Storage->new(undef);
  $storage->connect_info([ { dbname => 'fake', pool_size => 1 } ]);
  @EV::Pg::SENT   = ();
  $EV::Pg::REFUSE = 0;
  return $storage;
}

# Fire a statement's callback as EV::Pg does. A completion that dies is only
# warned about there; here it is returned.
sub fire {
  my ($entry, @result) = @_;
  eval { $entry->{cb}->(@result); 1 } or return $@;
  return '';
}

# The server refuses $entry: error_fields is set first, then the callback runs
# with (undef, $text) -- Pg.xs, for a PGRES_FATAL_ERROR result.
sub server_error {
  my ($entry, $text, %fields) = @_;
  $entry->{pg}{fields} = {%fields};
  return fire($entry, undef, $text);
}

# Not the server: the callback runs with a text of EV::Pg's own and error_fields
# is not touched -- whatever the previous error left in it stays.
sub transport_error {
  my ($entry, $text) = @_;
  return fire($entry, undef, $text);
}

# What a Future failed with, as the one value on_fail gets.
sub failure_of {
  my ($f) = @_;
  my @got;
  $f->on_fail(sub { @got = @_ });
  return \@got;
}

sub is_server_error {
  my ($got, %want) = @_;
  my $label = delete $want{label};
  ok blessed($got) && $got->isa('DBIO::Exception::Server'), "$label: a DBIO::Exception::Server"
    or return;
  is $got->$_, $want{$_}, "$label: $_" for sort keys %want;
}

sub is_plain_string {
  my ($got, $text, $label) = @_;
  ok !ref $got, "$label: a plain string, no object";
  is $got, $text, "$label: the text is as it was";
}

my $UNIQUE = qq{ERROR:  duplicate key value violates unique constraint "thing_name_key"\n};
my %UNIQUE = (
  sqlstate   => '23505',
  severity   => 'ERROR',
  primary    => 'duplicate key value violates unique constraint "thing_name_key"',
  constraint => 'thing_name_key',
  table      => 'thing',
  detail     => 'Key (name)=(a) already exists.',
);

# -----------------------------------------------------------------------------
# 1. The pooled path
# -----------------------------------------------------------------------------
{
  my $l = 'pooled';
  my $storage = new_storage();
  my $f = $storage->select_async(@SELECT);
  my $got = failure_of($f);
  until_sent(1);
  is fire_server_error_ok(server_error($EV::Pg::SENT[0], $UNIQUE, %UNIQUE)), 1, "$l: the callback ran clean";

  ok $f->is_failed, "$l: the Future failed";
  is scalar @$got, 1, "$l: with one value, as before";
  is_server_error $got->[0], label => $l,
    sqlstate => '23505', constraint => 'thing_name_key', table => 'thing',
    detail => 'Key (name)=(***) already exists.';
  is "$got->[0]", $UNIQUE, "$l: it stringifies to the text, newline and all";
  ok $got->[0] eq $UNIQUE, "$l: and is eq to it";
  like $got->[0], qr/duplicate key value violates unique constraint/, "$l: and matches a regex";
  my $thrown = eval { $f->get; 1 } ? undef : $@;
  is refaddr($thrown), refaddr($got->[0]), "$l: get throws that same object";

  # 4. the next server error brings its own fields
  my $g = $storage->select_async(@SELECT);
  until_sent(2);
  my $seen = failure_of($g);
  server_error($EV::Pg::SENT[1], qq{ERROR:  deadlock detected\n},
    sqlstate => '40P01', severity => 'ERROR', primary => 'deadlock detected');
  is_server_error $seen->[0], label => "$l, the next error",
    sqlstate => '40P01', constraint => undef, table => undef, detail => undef;
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 2. lc_messages: severity and primary are the server's words
# -----------------------------------------------------------------------------
{
  my $l = 'de_DE';
  my $storage = new_storage();
  my $f = $storage->select_async(@SELECT);
  my $got = failure_of($f);
  until_sent(1);
  my $text = "FEHLER:  storniere Anfrage wegen Zeitüberschreitung\n";
  server_error($EV::Pg::SENT[0], $text,
    sqlstate => '57014', severity => 'FEHLER',
    primary  => 'storniere Anfrage wegen Zeitüberschreitung');
  is_server_error $got->[0], label => $l, sqlstate => '57014';
  is "$got->[0]", $text, "$l: the German text is untouched";
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 3. what is not the server's stays a string -- also on a stale error_fields
# -----------------------------------------------------------------------------
{
  my $l = 'stale';
  my $storage = new_storage();

  # an earlier server error leaves its fields on the connection
  my $first = $storage->select_async(@SELECT);
  my $seen  = failure_of($first);
  until_sent(1);
  server_error($EV::Pg::SENT[0], $UNIQUE, %UNIQUE);
  is_server_error $seen->[0], label => "$l: control, the error before", sqlstate => '23505';

  for my $case (
    [ 'connection lost'     => 'connection lost' ],
    [ 'pipeline aborted'    => 'pipeline aborted' ],
    [ 'connection finished' => 'connection finished' ],
    [ 'empty query'         => 'empty query' ],
  ) {
    my ($name, $text) = @$case;
    my $before = @EV::Pg::SENT;
    my $f = $storage->select_async(@SELECT);
    my $got = failure_of($f);
    until_sent($before + 1);
    is $EV::Pg::SENT[-1]{pg}{fields}{sqlstate}, '23505',
      "$l, $name: the connection still holds the earlier error's fields";
    transport_error($EV::Pg::SENT[-1], $text);
    ok $f->is_failed, "$l, $name: the Future failed";
    is_plain_string $got->[0], $text, "$l, $name";
  }
  $storage->disconnect;
}
{
  my $l = 'dispatch croak';
  my $storage = new_storage();
  my $warm = $storage->select_async(@SELECT);
  until_sent(1);
  server_error($EV::Pg::SENT[0], $UNIQUE, %UNIQUE);   # leaves the fields behind
  $EV::Pg::REFUSE = 1;
  my $f = $storage->select_async(@SELECT);
  my $got = failure_of($f);
  settle();
  ok $f->is_failed, "$l: EV::Pg refuses the statement, the Future failed";
  is_plain_string $got->[0], "not connected\n", $l;
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 5. fields the server did not send; verbose; an EV::Pg without error_fields
# -----------------------------------------------------------------------------
{
  my $l = 'fields';
  my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
  my $pg = bless { fields => { sqlstate => '42601', severity => 'ERROR', primary => 'syntax error at or near "x"' } }, 'EV::Pg';

  my $e = $s->_pg_server_error($pg, qq{ERROR:  syntax error at or near "x"\n});
  is_server_error $e, label => "$l: only sqlstate sent", sqlstate => '42601',
    constraint => undef, table => undef, detail => undef;

  $e = $s->_pg_server_error($pg, qq{ERROR:  syntax error at or near "x"\nLINE 1: x\n        ^\n});
  is_server_error $e, label => "$l: a multi-line text", sqlstate => '42601';

  $e = $s->_pg_server_error($pg, qq{ERROR:  42601: syntax error at or near "x"\n});
  is_server_error $e, label => "$l: verbose", sqlstate => '42601';

  is $s->_pg_server_error($pg, "ERROR:  something else\n"), "ERROR:  something else\n",
    "$l: the text of another error is not this one's";
  is $s->_pg_server_error($pg, 'connection lost'), 'connection lost', "$l: a text that is not an error";
  is $s->_pg_server_error({ no => 'such method' }, "ERROR:  x\n"), "ERROR:  x\n",
    "$l: no error_fields on the connection";
  $pg->{fields} = undef;
  is $s->_pg_server_error($pg, "ERROR:  x\n"), "ERROR:  x\n", "$l: no error seen yet";
  $pg->{fields} = { sqlstate => '42601', primary => 'x' };
  is $s->_pg_server_error($pg, "ERROR:  x\n"), "ERROR:  x\n",
    "$l: fields without a severity cannot show the error is fresh";
  $pg->{fields} = { sqlstate => '42601', severity => 'ERROR', primary => 'x' };
  my $obj = bless {}, 'Some::Error';
  is $s->_pg_server_error($pg, $obj), $obj, "$l: an object passes unchanged";
  is $s->_pg_server_error($pg, undef), undef, "$l: undef passes unchanged";
}

# -----------------------------------------------------------------------------
# 6. pinned, txn_do_async, notify, copy_in
# -----------------------------------------------------------------------------
{
  my $l = 'pinned';
  my $storage = new_storage();
  my $acquired = $storage->pool->acquire;
  settle();
  my $pg = $acquired->get;
  my $f = $storage->_query_async_pinned($pg, 'INSERT INTO thing (name) VALUES ($1)', ['a']);
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], $UNIQUE, %UNIQUE);
  is_server_error $got->[0], label => $l, sqlstate => '23505', constraint => 'thing_name_key';
  $storage->disconnect;
}

# txn_do_async: the statement's object reaches the caller as it is.
{
  my $l = 'txn_do_async, statement';
  my $storage = new_storage();
  my $stmt;
  my $txn = $storage->txn_do_async(sub {
    return $stmt = $_[0]->insert_async('thing', { name => 'a' });
  });
  my $got = failure_of($txn);
  until_sent(1);
  is $EV::Pg::SENT[0]{sql}, 'BEGIN', "$l: BEGIN first";
  fire($EV::Pg::SENT[0], [ ]);
  until_sent(2);
  server_error($EV::Pg::SENT[1], $UNIQUE, %UNIQUE);
  until_sent(3);
  is $EV::Pg::SENT[2]{sql}, 'ROLLBACK', "$l: rolled back";
  fire($EV::Pg::SENT[2], [ ]);
  settle();
  ok $txn->is_failed, "$l: the transaction failed";
  is_server_error $got->[0], label => $l, sqlstate => '23505', table => 'thing';
  $storage->disconnect;
}

# 8. what core prepends: held as it is.
{
  my $l = 'BEGIN failed';
  my $storage = new_storage();
  my $txn = $storage->txn_do_async(sub { return });
  my $got = failure_of($txn);
  until_sent(1);
  server_error($EV::Pg::SENT[0], qq{ERROR:  current transaction is aborted\n},
    sqlstate => '25P02', severity => 'ERROR', primary => 'current transaction is aborted');
  settle();
  ok $txn->is_failed, "$l: the transaction failed";
  is_server_error $got->[0], label => $l, sqlstate => '25P02', context => 'BEGIN',
    constraint => undef, table => undef, detail => undef;
  like "$got->[0]", qr/\ABEGIN failed: .*current transaction is aborted/s, "$l: the text is core's plus the server's";
  $storage->disconnect;
}
{
  my $l = 'COMMIT failed';
  my $storage = new_storage();
  my $txn = $storage->txn_do_async(sub { return 1 });
  my $got = failure_of($txn);
  until_sent(1);
  fire($EV::Pg::SENT[0], [ ]);
  until_sent(2);
  is $EV::Pg::SENT[1]{sql}, 'COMMIT', "$l: COMMIT is sent";
  server_error($EV::Pg::SENT[1], $UNIQUE, %UNIQUE);
  # the server refused the COMMIT: core sends a ROLLBACK on the pinned
  # connection before the transaction fails (core karr k372)
  until_sent(3);
  is $EV::Pg::SENT[2]{sql}, 'ROLLBACK', "$l: a ROLLBACK follows the refused COMMIT";
  fire($EV::Pg::SENT[2], [ ]);
  settle();
  ok $txn->is_failed, "$l: the transaction failed";
  is_server_error $got->[0], label => $l, sqlstate => '23505', context => 'COMMIT',
    constraint => 'thing_name_key', table => 'thing', detail => 'Key (name)=(***) already exists.';
  like "$got->[0]", qr/\ACOMMIT failed: ERROR:  duplicate key value/, "$l: the text is core's plus the server's";
  $storage->disconnect;
}
{
  my $l = 'Rollback failed';
  my $storage = new_storage();
  my $txn = $storage->txn_do_async(sub { return $_[0]->insert_async('thing', { name => 'a' }) });
  my $got = failure_of($txn);
  until_sent(1);
  fire($EV::Pg::SENT[0], [ ]);
  until_sent(2);
  server_error($EV::Pg::SENT[1], $UNIQUE, %UNIQUE);
  until_sent(3);
  is $EV::Pg::SENT[2]{sql}, 'ROLLBACK', "$l: ROLLBACK is sent";
  server_error($EV::Pg::SENT[2], qq{ERROR:  could not roll back\n},
    sqlstate => 'XX000', severity => 'ERROR', primary => 'could not roll back');
  settle();
  ok $txn->is_failed, "$l: the transaction failed";
  is_server_error $got->[0], label => $l, sqlstate => 'XX000', context => 'ROLLBACK';
  like "$got->[0]", qr/Rollback failed: .*could not roll back/s, "$l: the text is core's plus the server's";
  $storage->disconnect;
}

{
  my $l = 'notify';
  my $storage = new_storage();
  my $f = $storage->notify('chan', 'payload');
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], qq{ERROR:  payload string too long\n},
    sqlstate => '22023', severity => 'ERROR', primary => 'payload string too long');
  is_server_error $got->[0], label => $l, sqlstate => '22023';
  $storage->disconnect;
}

{
  my $l = 'copy_in, refused';
  my $storage = new_storage();
  my $f = $storage->copy_in('thing', ['name'], sub { 1 });
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], qq{ERROR:  relation "thing" does not exist\n},
    sqlstate => '42P01', severity => 'ERROR', primary => 'relation "thing" does not exist');
  is_server_error $got->[0], label => $l, sqlstate => '42P01';
  $storage->disconnect;
}
{
  my $l = 'copy_in, the coderef dies';
  my $storage = new_storage();
  my $f = $storage->copy_in('thing', ['name'], sub { die "my own error\n" });
  my $got = failure_of($f);
  until_sent(1);
  # the first firing opens the stream; the connection holds an old error's fields
  $EV::Pg::SENT[0]{pg}{fields} = { %UNIQUE };
  fire($EV::Pg::SENT[0], 'COPY_IN');
  # the server's answer to the end of the stream: its own error text
  server_error($EV::Pg::SENT[0], qq{ERROR:  COPY from stdin failed: my own error\n},
    sqlstate => '57014', severity => 'ERROR', primary => 'COPY from stdin failed: my own error');
  ok $f->is_failed, "$l: the COPY failed";
  is_plain_string $got->[0], "my own error\n", "$l: with the coderef's own error, as before";
  $storage->disconnect;
}

# Values stay out of a server error (karr k99, core k386): the keys and columns
# are named, the DETAIL values are masked in the message and in detail.
{
  my $l = 'values masked';
  my $storage = new_storage();
  my $f = $storage->select_async(@SELECT);
  my $got = failure_of($f);
  until_sent(1);
  my $text = $UNIQUE . qq{DETAIL:  Key (name)=(secret-value) already exists.\n};
  server_error($EV::Pg::SENT[0], $text,
    %UNIQUE, detail => 'Key (name)=(secret-value) already exists.');
  is_server_error $got->[0], label => $l, sqlstate => '23505',
    detail => 'Key (name)=(***) already exists.';
  unlike "$got->[0]", qr/secret-value/, "$l: the message holds no value";
  like "$got->[0]", qr/^DETAIL:  Key \(name\)=\(\*\*\*\) already exists\.$/m,
    "$l: the DETAIL line names the column";
  $storage->disconnect;
}

# a helper kept at the end: the callbacks above return '' when they ran clean
sub fire_server_error_ok { return $_[0] eq '' ? 1 : do { diag "callback died: $_[0]"; 0 } }

done_testing;
