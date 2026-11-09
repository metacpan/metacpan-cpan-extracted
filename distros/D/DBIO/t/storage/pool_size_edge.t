use strict;
use warnings;
use Test::More;

use DBIO::Storage::PoolBase;
use DBIO::Storage::Async;
use DBIO::AccessBroker;
use DBIO::Test::Future ();

# karr k270. The pool's size comes from outside: the pool_size connect
# attribute, or a pool_size in an AccessBroker's answer, handed to
# DBIO::Storage::PoolBase::new as size. Only a plain positive size was ever
# executed by a test.
#
#   * A size the pool cannot be -- negative, no number, a fraction -- became
#     its max_size as given. acquire spawns while it counts fewer connections
#     than max_size, so with -1 or 'abc' it never spawned: every acquire was
#     queued for a release nobody could make, and waited for good. No error,
#     at connect or later.
#
# The claims this file pins:
#
#   1. no size, or a size that is false, is the default of 5 -- and the pool
#      really is that big;
#   2. a positive integer is the size, as a number or as a string of digits;
#   3. anything else is refused by new, naming what a size has to be -- and
#      never quoting a value that is no number; no pool is built, so no acquire
#      is left waiting on it;
#   4. the same refusal reaches a size given as pool_size in the connect info
#      of an async storage, or in a broker's answer, when the storage builds
#      its pool.
#
# Whether a size of 0 should be refused rather than taken as "not given" is
# not decided here: 0 has meant the default all along, in PoolBase and in the
# family's transports, and stays so.
#
# Mock only, against DBIO::Test::Future and Future.pm.

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

{
  package K270S::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { bless { id => ++$_[0]{n} }, 'K270S::Conn' }
}

sub new_pool {
  my ($fc, @size) = @_;
  return K270S::Pool->new(conninfo => 'fake', future_class => $fc, @size);
}

# Acquire until one acquire is not served at once; how many were.
sub served_at_once {
  my ($pool, $limit) = @_;
  my $served = 0;
  while ($served < $limit) {
    my $f = $pool->acquire;
    last unless $f->is_ready && !$f->is_failed;
    $served++;
  }
  return $served;
}

my $REFUSAL = qr/Pool size must be a positive integer/;

my $have_future = eval { require Future; 1 };

for my $fc ('DBIO::Test::Future', $have_future ? 'Future' : ()) {

  # -------------------------------------------------------------------------
  # 1. No size, or a false one: the default.
  # -------------------------------------------------------------------------
  for my $case (
    [ 'no size'            => () ],
    [ 'an undefined size'  => (size => undef) ],
    [ 'a size of 0'        => (size => 0) ],
    [ "a size of '0'"      => (size => '0') ],
    [ 'an empty size'      => (size => '') ],
  ) {
    my ($name, @size) = @$case;
    my $l = "$fc, $name";
    my $pool = eval { new_pool($fc, @size) };

    ok $pool, "$l: a pool is built" or diag $@;
    next unless $pool;
    is $pool->max_size, 5, "$l: of the default size";
    is served_at_once($pool, 10), 5, "$l: five acquires are served, the sixth waits";
    is $pool->size, 5, "$l: by five connections";
  }

  # -------------------------------------------------------------------------
  # 2. A positive integer.
  # -------------------------------------------------------------------------
  for my $case (
    [ 'a size of 1'            => 1,    1 ],
    [ 'a size of 3'            => 3,    3 ],
    [ "a size of '3'"          => '3',  3 ],
    [ 'a size of 2.0'          => 2.0,  2 ],
    [ 'a size of 12'           => 12,   12 ],
  ) {
    my ($name, $size, $expect) = @$case;
    my $l = "$fc, $name";
    my $pool = eval { new_pool($fc, size => $size) };

    ok $pool, "$l: a pool is built" or diag $@;
    next unless $pool;
    cmp_ok $pool->max_size, '==', $expect, "$l: of that size";
    is served_at_once($pool, 20), $expect,
      "$l: that many acquires are served, the next waits";
  }

  # -------------------------------------------------------------------------
  # 3. Anything else is refused.
  # -------------------------------------------------------------------------
  for my $case (
    #  name                          size             named in the refusal
    [ 'a negative size'           => -1,              qr/got -1\b/ ],
    [ 'a negative size as string' => '-3',            qr/got -3\b/ ],
    [ 'a fraction'                => 1.5,             qr/got 1\.5\b/ ],
    [ 'a fraction below one'      => 0.5,             qr/got 0\.5\b/ ],
    [ 'a word'                    => 'abc',           qr/got a value that is no number/ ],
    [ 'digits and a word'         => '3abc',          qr/got a value that is no number/ ],
    [ 'digits and a newline'      => "3\n",           qr/positive integer/ ],
    [ "a true zero, '0E0'"        => '0E0',           qr/positive integer/ ],
    [ "'00'"                      => '00',            qr/positive integer/ ],
    [ 'an array reference'        => [ 3 ],           qr/got an? ARRAY reference/ ],
    [ 'a hash reference'          => { size => 3 },   qr/got an? HASH reference/ ],
  ) {
    my ($name, $size, $names) = @$case;
    my $l = "$fc, $name";
    @warnings = ();

    my $pool  = eval { new_pool($fc, size => $size) };
    my $error = "$@";

    ok !$pool, "$l: no pool is built";
    like $error, $REFUSAL, "$l: new says what a size has to be";
    like $error, $names, "$l: and what it got";
    unlike $error, qr/abc/, "$l: without quoting a value that is no number";
    is_deeply [@warnings], [], "$l: and without a warning";

    # What a pool of that size did: it never spawned, and queued every caller.
    my $f = $pool ? $pool->acquire : undef;
    ok !( $f && !$f->is_ready ), "$l: no acquire is left waiting on such a pool";
  }
}

# ---------------------------------------------------------------------------
# 4. Through an async storage: the size it was connected with reaches the pool
#    it builds on first use, as the family's transports hand it on.
# ---------------------------------------------------------------------------
{
  package K270S::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class { 'DBIO::Test::Future' }
  sub transport_capabilities { qw( broker_connect_options ) }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K270S::Pool->new(
      conninfo     => 'fake',
      future_class => $self->future_class,
      size         => $self->{_pool_size},
    );
  }
}

{
  package K270S::Broker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %answer) = @_; bless { answer => \%answer }, $class }
  sub connect_info_for { return { %{ $_[0]{answer} } } }
}

sub backend_with {
  my ($info) = @_;
  my $backend = K270S::Backend->new(undef);
  $backend->connect_info($info);
  return $backend;
}

for my $case (
  [ 'pool_size in the connect info',
    sub { [ { dbname => 'app', pool_size => $_[0] }, {} ] } ],
  [ "pool_size in a broker's answer",
    sub { [ K270S::Broker->new(dbname => 'app', pool_size => $_[0]) ] } ],
  [ 'pool_size beside a broker',
    sub { [ K270S::Broker->new(dbname => 'app'), { pool_size => $_[0] } ] } ],
) {
  my ($name, $info) = @$case;

  {
    my $backend = backend_with($info->(2));
    my $pool = eval { $backend->pool };
    ok $pool, "$name, 2: the storage builds its pool" or diag $@;
    is $pool && $pool->max_size, 2, "$name, 2: of that size";
  }

  for my $bad (-1, 'abc') {
    my $l = "$name, $bad";
    my $backend = eval { backend_with($info->($bad)) };
    ok $backend, "$l: the storage takes the connect info" or diag $@;
    next unless $backend;

    my $pool = eval { $backend->pool };
    ok !$pool, "$l: the storage builds no pool";
    like "$@", $REFUSAL, "$l: the pool's refusal says what a size has to be";
  }
}

# Given nowhere, and given as 0: the storage's default, which is the pool's.
for my $case (
  [ 'no pool_size'   => [ { dbname => 'app' }, {} ] ],
  [ 'a pool_size of 0' => [ { dbname => 'app', pool_size => 0 }, {} ] ],
) {
  my ($name, $info) = @$case;
  my $pool = eval { backend_with($info)->pool };
  ok $pool, "$name: the storage builds its pool" or diag $@;
  is $pool && $pool->max_size, 5, "$name: of the default size";
}

done_testing;
