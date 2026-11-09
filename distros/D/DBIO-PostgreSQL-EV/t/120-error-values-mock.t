use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );

# OFFLINE, ADR 0075 (core): the values a statement bound do not reach an
# exception -- on the ways the live file t/119 cannot reach, and on the
# bookkeeping behind it.
#
# The server's text quotes the value that failed. Every text of the server's or
# libpq's that becomes an exception or a failed Future passes the net of the
# bound values and the forms of the server's messages
# (_pg_mask_error_text); the callbacks hold a copy of the plain values for the
# flight of their statement and never the bind array (t/05 holds that).
#
# The claims, with EV::Pg as the single substitution (as in t/98):
#   1. a server error with error_fields: the object's message and detail carry
#      no bound value, wherever it stands in them (a detail of no known form
#      too), and the object is still the server's (sqlstate kept).
#   2. an EV::Pg without error_fields, and a connection whose error_fields do
#      not belong to the text: the string is masked all the same -- the bound
#      value, and the value of a form the server writes.
#   3. a text of no known form and no bound value in it is not changed, nor is
#      the text of a lost connection, an aborted pipeline.
#   4. the pinned path (also with the statement waiting its turn) and the
#      pipeline, notify (channel and payload are binds), and a value of an
#      object with a stringification.
#   5. the session reset: a failing DISCARD ALL is masked.
#   6. a connect action with binds that the server refuses: the exception
#      carries no value.
#   7. the net never throws and is idempotent: a text already masked, a
#      reference, undef.
#   8. a value shorter than four characters is the business of the forms
#      alone: a bound 'ab' is not struck out of the words around it.

BEGIN {
  package EV::Pg;
  use Carp ();
  use Scalar::Util ();

  our @SENT;      # every statement sent: { pg, sql, bind, cb }
  our $NO_FIELDS; # true: this EV::Pg has no error_fields (a version without it)
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
  sub can {
    my ($self, $method) = @_;
    return undef if $NO_FIELDS && $method eq 'error_fields';
    return $self->SUPER::can($method);
  }
  sub error_fields  { $_[0]{fields} }

  sub _send {
    my ($self, $sql, $bind, $cb) = @_;
    Carp::croak('not connected') if !$self->{up};
    push @SENT, { pg => $self, sql => $sql, bind => $bind, cb => $cb };
    return;
  }

  sub query_params { my ($self, $sql, $bind, $cb) = @_; $self->_send($sql, $bind, $cb) }
  sub query        { my ($self, $sql, $cb) = @_; $self->_send($sql, undef, $cb) }
  sub enter_pipeline { 1 }
  sub exit_pipeline  { 1 }
  sub pipeline_sync  { my ($self, $cb) = @_; $self->_send('SYNC', undef, $cb) }

  $INC{'EV/Pg.pm'} = __FILE__;
}

use EV;
use DBIO::PostgreSQL::EV::Storage;
my $RESET;
BEGIN { $RESET = \&DBIO::PostgreSQL::EV::Storage::_reset_pool_connection }

use FindBin;
use lib "$FindBin::Bin/lib";
use NoSessionReset;
use DBIO::PostgreSQL::EV::Pool;
use DBIO::Exception::Server ();

alarm 60;

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
  @EV::Pg::SENT = ();
  $EV::Pg::NO_FIELDS = 0;
  return $storage;
}

sub fire {
  my ($entry, @result) = @_;
  eval { $entry->{cb}->(@result); 1 } or return $@;
  return '';
}

sub server_error {
  my ($entry, $text, %fields) = @_;
  $entry->{pg}{fields} = {%fields};
  return fire($entry, undef, $text);
}

sub failure_of {
  my ($f) = @_;
  my @got;
  $f->on_fail(sub { @got = @_ });
  return \@got;
}

sub texts_of {
  my ($err) = @_;
  my @t = ("$err");
  push @t, grep { defined } map { $err->$_ } qw( detail ) if blessed $err;
  return @t;
}

sub no_value {
  my ($err, $re, $label) = @_;
  my @found = grep { /$re/ } texts_of($err);
  ok !@found, "$label: no value in the exception" or diag "says: @found";
}

my %REL = (
  severity => 'ERROR', sqlstate => '42P01',
  primary  => 'relation "geheim42" does not exist',
);
my $REL = qq{ERROR:  relation "geheim42" does not exist\n};

# -----------------------------------------------------------------------------
# 1. the server's object: message and detail masked, wherever the value stands
# -----------------------------------------------------------------------------
{
  my $l = 'object';
  my $storage = new_storage();
  my $f = $storage->_query_async('SELECT ?::regclass', ['geheim42']);
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], $REL, %REL, detail => 'There is no geheim42 here.');
  ok blessed($got->[0]) && $got->[0]->isa('DBIO::Exception::Server'), "$l: the server's object";
  is $got->[0]->sqlstate, '42P01', "$l: the sqlstate is kept";
  no_value($got->[0], qr/geheim42/, $l);
  is "$got->[0]", qq{ERROR:  relation "***" does not exist\n}, "$l: the sentence stays, the value goes";
  is $got->[0]->detail, 'There is no *** here.', "$l: a detail of no known form loses the bound value";
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 2. no error_fields, or fields that are not this text's: a masked string
# -----------------------------------------------------------------------------
{
  my $l = 'no error_fields';
  my $storage = new_storage();
  $EV::Pg::NO_FIELDS = 1;
  my $f = $storage->_query_async('SELECT ?::regclass', ['geheim42']);
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], $REL, %REL);
  ok !ref $got->[0], "$l: a plain string";
  is $got->[0], qq{ERROR:  relation "***" does not exist\n}, "$l: the bound value is struck out";
  $storage->disconnect;
}
{
  my $l = 'no error_fields, a form of the server';
  my $storage = new_storage();
  $EV::Pg::NO_FIELDS = 1;
  my $f = $storage->_query_async('SELECT ?::integer', ['xyz']);
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], qq{ERROR:  invalid input syntax for type integer: "xyz"\nCONTEXT:  unnamed portal parameter \$1 = 'xyz'\n});
  is $got->[0], qq{ERROR:  invalid input syntax for type integer: "***"\nCONTEXT:  unnamed portal parameter \$1 = '***'\n},
    "$l: the short value goes by the form";
  $storage->disconnect;
}
{
  my $l = 'stale error_fields';
  my $storage = new_storage();
  my $f = $storage->_query_async('SELECT ?::regclass', ['geheim42']);
  my $got = failure_of($f);
  until_sent(1);
  # error_fields of an earlier error, text of the connection's own
  $EV::Pg::SENT[0]{pg}{fields} = { severity => 'ERROR', primary => 'something else', sqlstate => '23505' };
  fire($EV::Pg::SENT[0], undef, 'connection lost: geheim42');
  ok !ref $got->[0], "$l: a plain string";
  is $got->[0], 'connection lost: ***', "$l: masked all the same";
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 3. what has nothing to mask is as it was
# -----------------------------------------------------------------------------
{
  my $l = 'unchanged';
  my $storage = new_storage();
  for my $text ('connection lost', 'pipeline aborted', "ERROR:  something quite new happened\n") {
    my $f = $storage->_query_async('SELECT ?', ['geheim42']);
    my $got = failure_of($f);
    until_sent(1);
    $EV::Pg::SENT[0]{pg}{fields} = undef;
    fire(shift @EV::Pg::SENT, undef, $text);
    is $got->[0], $text, "$l: $text";
    settle();
  }
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 4. pinned, pipeline, notify, an object with a stringification
# -----------------------------------------------------------------------------
{
  my $l = 'pinned';
  my $storage = new_storage();
  my $pg = $storage->pool->acquire->get;
  my $f = $storage->_query_async_pinned($pg, 'SELECT ?::regclass', ['geheim42']);
  my $g = $storage->_query_async_pinned($pg, 'SELECT ?::regtype', ['geheim43']);   # waits its turn
  my ($fgot, $ggot) = (failure_of($f), failure_of($g));
  until_sent(1);
  server_error($EV::Pg::SENT[0], $REL, %REL);
  no_value($fgot->[0], qr/geheim42/, "$l, in flight");
  until_sent(2);
  server_error($EV::Pg::SENT[1], qq{ERROR:  type "geheim43" does not exist\n},
    severity => 'ERROR', sqlstate => '42704', primary => 'type "geheim43" does not exist');
  no_value($ggot->[0], qr/geheim43/, "$l, from the queue");
  $storage->pool->release($pg);
  $storage->disconnect;
}
{
  my $l = 'pipeline';
  my $storage = new_storage();
  my $pg = $storage->pool->acquire->get;
  $storage->_pipeline_enter($pg);
  my $f = $storage->_query_async_pinned($pg, 'SELECT ?::regclass', ['geheim42']);
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], $REL, %REL);
  no_value($got->[0], qr/geheim42/, $l);
  $storage->_pipeline_exit($pg);
  $storage->pool->release($pg);
  $storage->disconnect;
}
{
  my $l = 'notify';
  my $storage = new_storage();
  my $f = $storage->notify('chan', 'payload-geheim42');
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], qq{ERROR:  payload "payload-geheim42" is odd\n},
    severity => 'ERROR', sqlstate => 'XX000', primary => 'payload "payload-geheim42" is odd');
  no_value($got->[0], qr/payload-geheim42/, $l);
  $storage->disconnect;
}
{
  package T120::Stringy;
  use overload '""' => sub { 'object-geheim42' }, fallback => 1;
}
{
  my $l = 'stringifying object';
  my $storage = new_storage();
  my $f = $storage->_query_async('SELECT ?::regclass', [ bless({}, 'T120::Stringy'), undef, [1], \'ref-geheim' ]);
  my $got = failure_of($f);
  until_sent(1);
  server_error($EV::Pg::SENT[0], qq{ERROR:  relation "object-geheim42" does not exist\n},
    severity => 'ERROR', sqlstate => '42P01', primary => 'relation "object-geheim42" does not exist');
  no_value($got->[0], qr/object-geheim42/, $l);
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 5. the session reset
# -----------------------------------------------------------------------------
{
  my $l = 'DISCARD ALL';
  my $storage = new_storage();
  my $pg = $storage->pool->acquire->get;
  my $f = $RESET->($storage, $pg);
  my $got = failure_of($f);
  until_sent(1);
  fire($EV::Pg::SENT[0], undef,
    qq{ERROR:  invalid input syntax for type integer: "xyz"\nCONTEXT:  unnamed portal parameter \$1 = 'xyz'\n});
  like $got->[0], qr/\Athe session of a pool connection could not be reset: DISCARD ALL failed: ERROR:  /, "$l: the step is named";
  no_value($got->[0], qr/xyz/, $l);
  $storage->pool->release($pg);
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 6. a connect action with binds
# -----------------------------------------------------------------------------
{
  my $l = 'connect statement';
  my $storage = new_storage();
  my $pg = $storage->pool->acquire->get;
  my $t = EV::timer(0.01, 0, sub {
    fire($EV::Pg::SENT[-1], undef, qq{ERROR:  relation "geheim42" does not exist\n});
  });
  my $died = eval { $storage->_run_pool_connect_statement($pg, 'SELECT ?::regclass', {}, 'geheim42'); 1 } ? '' : $@;
  like "$died", qr/pool connect statement failed: ERROR:  relation/, "$l: it fails";
  no_value($died, qr/geheim42/, $l);
  $storage->pool->release($pg);
  $storage->disconnect;
}

# -----------------------------------------------------------------------------
# 7. the net: never throws, idempotent
# -----------------------------------------------------------------------------
{
  my $l = 'net';
  my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
  is $s->_pg_mask_error_text(undef, ['geheim42']), undef, "$l: undef is undef";
  my $ref = [];
  is $s->_pg_mask_error_text($ref, ['geheim42']), $ref, "$l: a reference is itself";
  my $once = $s->_pg_mask_error_text(qq{relation "geheim42" does not exist\nDETAIL:  Key (a)=(geheim42) already exists.}, ['geheim42']);
  is $once, qq{relation "***" does not exist\nDETAIL:  Key (a)=(***) already exists.}, "$l: both are struck out";
  is $s->_pg_mask_error_text($once, ['geheim42']), $once, "$l: masked twice is masked once";
  is $s->_pg_mask_error_text('plain text'), 'plain text', "$l: no values given, no form";
  is_deeply DBIO::PostgreSQL::EV::Storage::_pg_error_values('abcd', undef, [1], \'plain-ref', bless({}, 'T120::Stringy')),
    [ 'abcd', 'object-geheim42' ], "$l: the values of a bind list";
}

# -----------------------------------------------------------------------------
# 8. short values are the forms' business
# -----------------------------------------------------------------------------
{
  my $l = 'short value';
  my $s = DBIO::PostgreSQL::EV::Storage->new(undef);
  is $s->_pg_mask_error_text('connection lost on table ab', ['ab']), 'connection lost on table ab',
    "$l: a bound 'ab' stays in the words around it";
}

done_testing;
