# ABSTRACT: An async backend and the broker answers it cannot connect from
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;
use DBIO::Test::Future ();

# OFFLINE (karr k264; the async twin of 17-dbi-broker-unusable-answer.t).
# 12-async-broker-without-answer.t covers a broker that answers NOTHING (undef,
# {}, [], a false value). This file is about the answers that are something,
# and still nothing a connection can be made from.
#
# _current_async_connect_info hands on whatever the broker answered -- a hash
# paired with an empty options hash, anything else as it came -- and
# _normalize_async_connect_info splits it with $info->[0]. On a plain string
# that died in an array dereference whose message QUOTED THE STRING: a DSN,
# which may carry a password. On a code reference, a scalar reference or an
# object it died of "Not an ARRAY reference", which names nobody.
#
# What this file claims:
#   1. An answer that is neither a hash nor an array -- a plain scalar, a code
#      reference, a scalar reference, an object -- is refused at connect_info:
#      the error names the broker class and the SHAPE of the answer, never a
#      value of it. Attached directly or through a HostBound view.
#   2. The same as a LATER answer, when a pool connection is opened: acquire's
#      Future fails with that error, and no connection is built -- not from
#      this answer, not from an earlier one.
#   3. The third shape karr k264 names, undef, is refused one step earlier, by
#      the storage's one question to the broker -- with the broker class and
#      the shape as well.
#   4. The shapes an async backend takes still connect (control): a hash of
#      connection parameters, a [ \%conninfo, \%opts ] pair, the DBI form.
#   5. The refusal is _normalize_async_connect_info's own, so a transport that
#      splits the broker's answer itself (dbio-async, and this file's backend
#      at every pool spawn) gets it too. Static connect info of such a shape is
#      refused the same way, naming no broker. undef is not this method's to
#      refuse: with a broker it never arrives, and without one it is what an
#      unconfigured storage has.
#
# WHERE THE REFUSAL SITS, and why not one step earlier: dbio-mysql-ev,
# dbio-postgresql-ev and dbio-postgresql's future_io adapter read
# _current_async_connect_info and name an unusable answer in their own words,
# with the shapes their client takes ("MySQL ev cannot connect from what the
# AccessBroker returned: a plain string"). A refusal inside
# _current_async_connect_info would speak before them.
#
# THE SUBSTITUTIONS: a pool that records every connection it builds instead of
# connecting; a transport running core's own connect_info and building each
# pool connection's conninfo the way dbio-async's DBIO::Async::Storage does
# (_normalize_async_connect_info over the broker's current answer).

# A broker answering from a script: one code per call, the last one repeating.
{
  package T::ScriptBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answers) = @_; bless { answers => \@answers, calls => 0 }, $class }
  sub connect_info_for {
    my $self = shift;
    my $i = $self->{calls}++;
    $i = $#{ $self->{answers} } if $i > $#{ $self->{answers} };
    return $self->{answers}[$i]->();
  }
}

{
  package T::RecordingPool;
  use base 'DBIO::Storage::PoolBase';
  our @BUILT;
  sub _create_connection { my ($self, $conninfo) = @_; push @BUILT, $conninfo; bless { conninfo => $conninfo }, 'T::Conn' }
  sub _transform_conninfo { $_[1] }
}

{
  package T::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub disconnect   { delete $_[0]{pool}; 1 }
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    return $conninfo;
  }
  sub pool {
    my $self = shift;
    $self->{pool} ||= T::RecordingPool->new(
      size         => 5,
      future_class => $self->future_class,
      ($self->_conninfo_provider
        ? (conninfo_provider => $self->_conninfo_provider)
        : (conninfo          => $self->{_conninfo})),
    );
  }
}

my ($USER, $PASSWORD) = ('k264-user', 'k264-secret');
my $VALUE = qr/k264-(?:user|secret|dsn)/;   # every value of an answer in this file

sub good_answer { { dbname => 'app', user => $USER, password => $PASSWORD } }

my %NO_SHAPE = (
  'a plain scalar'               => sub { "dbi:Fake:dbname=k264-dsn;user=$USER;password=$PASSWORD" },
  'a CODE reference'             => sub { sub { $PASSWORD } },
  'a SCALAR reference'           => sub { \"dbi:Fake:dbname=k264-dsn;password=$PASSWORD" },
  'an object of class T::Answer' => sub { bless { dsn => 'dbi:Fake:k264-dsn', password => $PASSWORD }, 'T::Answer' },
);

sub cannot_use {
  my ($broker_class, $shape) = @_;
  return qr/AccessBroker \Q$broker_class\E answered connect info an async storage cannot connect from \(\Q$shape\E\)/;
}

sub failure_of { my ($f) = @_; return $f->is_failed ? "$f->{values}[0]" : '' }

# ---------------------------------------------------------------------------
# 1. Neither a hash nor an array, at connect_info.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NO_SHAPE) {
  {
    my $storage = T::Backend->new(undef);
    throws_ok { $storage->connect_info([ T::ScriptBroker->new($NO_SHAPE{$shape}) ]) }
      cannot_use('T::ScriptBroker', $shape),
      "$shape at connect_info: throws, naming the broker class and the shape";
    unlike "$@", $VALUE, "$shape at connect_info: naming no value of the answer";
    like "$@", qr/hash of connection parameters/, "$shape at connect_info: saying what it takes";
  }

  {
    my $storage = T::Backend->new(undef);
    my $view = T::ScriptBroker->new($NO_SHAPE{$shape})->for_host('replica.example');
    throws_ok { $storage->connect_info([ $view ]) }
      cannot_use('DBIO::AccessBroker::HostBound', $shape),
      "$shape through a HostBound view: throws, naming the view and the shape";
    unlike "$@", $VALUE, "$shape through a HostBound view: naming no value of the answer";
  }
}

# ---------------------------------------------------------------------------
# 2. Neither a hash nor an array, when a pool connection is opened.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NO_SHAPE) {
  # connect_info asks once, each pool spawn once more
  my $broker  = T::ScriptBroker->new(\&good_answer, \&good_answer, $NO_SHAPE{$shape});
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ $broker ]);
  local @T::RecordingPool::BUILT;

  my $good = $storage->pool->acquire;
  ok !$good->is_failed, "$shape as a later answer: a pool connection before it is opened";
  is_deeply \@T::RecordingPool::BUILT, [ good_answer() ], "$shape as a later answer: ... with the broker's answer";

  my $f = $storage->pool->acquire;
  ok $f->is_failed, "$shape as a later answer: the next pool connection fails";
  like failure_of($f), cannot_use('T::ScriptBroker', $shape),
    "$shape as a later answer: naming the broker class and the shape";
  unlike failure_of($f), $VALUE, "$shape as a later answer: naming no value, of this answer or an earlier one";
  is scalar @T::RecordingPool::BUILT, 1, "$shape as a later answer: no connection is built";
}

# ---------------------------------------------------------------------------
# 3. undef: refused by the storage's question to the broker.
# ---------------------------------------------------------------------------
{
  my $storage = T::Backend->new(undef);
  throws_ok { $storage->connect_info([ T::ScriptBroker->new(sub { undef }) ]) }
    qr/AccessBroker T::ScriptBroker answered no connect info \(undef\)/,
    'undef at connect_info: throws, naming the broker class and the shape';
}

{
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(\&good_answer, sub { undef }) ]);
  local @T::RecordingPool::BUILT;
  my $f = $storage->pool->acquire;
  like failure_of($f), qr/AccessBroker T::ScriptBroker answered no connect info \(undef\)/,
    'undef as a later answer: the pool connection fails, naming the broker class and the shape';
  unlike failure_of($f), $VALUE, '... and no value of the earlier answer';
  is scalar @T::RecordingPool::BUILT, 0, '... and no connection is built';
}

# ---------------------------------------------------------------------------
# 4. The shapes an async backend takes (control).
# ---------------------------------------------------------------------------
my %TAKEN = (
  'a hash of connection parameters' =>
    [ sub { good_answer() }, good_answer() ],
  'a [ \%conninfo, \%opts ] pair' =>
    [ sub { [ good_answer(), { some => 'opt' } ] }, good_answer() ],
  'the DBI form' =>
    [ sub { [ 'dbi:Fake:dbname=app', $USER, $PASSWORD, {} ] }, 'dbi:Fake:dbname=app' ],
);

for my $shape (sort keys %TAKEN) {
  my ($answer, $conninfo) = @{ $TAKEN{$shape} };
  my $storage = T::Backend->new(undef);
  lives_ok { $storage->connect_info([ T::ScriptBroker->new($answer) ]) } "$shape: connect_info takes it";
  local @T::RecordingPool::BUILT;
  ok !$storage->pool->acquire->is_failed, "$shape: a pool connection is opened";
  is_deeply \@T::RecordingPool::BUILT, [ $conninfo ], "$shape: ... from its conninfo";
}

# ---------------------------------------------------------------------------
# 5. The refusal is _normalize_async_connect_info's own.
# ---------------------------------------------------------------------------
for my $shape (sort keys %NO_SHAPE) {
  my $storage = T::Backend->new(undef);
  $storage->connect_info([ T::ScriptBroker->new(\&good_answer) ]);
  throws_ok { $storage->_normalize_async_connect_info($NO_SHAPE{$shape}->()) }
    cannot_use('T::ScriptBroker', $shape),
    "_normalize_async_connect_info, $shape, a broker attached: throws, naming the broker class and the shape";
  unlike "$@", $VALUE, "_normalize_async_connect_info, $shape: naming no value";
}

for my $shape (sort(keys %NO_SHAPE), 'a HASH reference') {
  my $info = $shape eq 'a HASH reference' ? good_answer() : $NO_SHAPE{$shape}->();
  my $storage = T::Backend->new(undef);
  throws_ok { $storage->connect_info($info) }
    qr/An async storage cannot connect from this connect info \(\Q$shape\E\)\. It takes an array/,
    "static connect info, $shape: connect_info throws, naming the shape and what it takes";
  unlike "$@", $VALUE, "static connect info, $shape: naming no value";
  unlike "$@", qr/AccessBroker/, "static connect info, $shape: and no broker, there being none";
}

{
  my $storage = T::Backend->new(undef);
  is_deeply [ $storage->_normalize_async_connect_info(undef) ], [ undef, 5, {} ],
    '_normalize_async_connect_info, undef: no conninfo, the default pool size, no options -- as before';
  is_deeply [ $storage->_normalize_async_connect_info([ good_answer(), { some => 'opt' } ]) ],
    [ good_answer(), 5, { some => 'opt' } ],
    '_normalize_async_connect_info, a pair: split as before';
}

done_testing;
