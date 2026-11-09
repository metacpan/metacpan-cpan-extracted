# ABSTRACT: A pool_size in a broker's answer sizes the async backend's pool
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::Async;
use DBIO::AccessBroker;

# OFFLINE (karr k245). A broker answering the DBI form can carry pool_size
# among its attributes -- DBIO::AccessBroker::Vault with dbi_attrs =>
# { async => $mode, pool_size => 3 }. The owning sync storage keeps it out of
# its own DBI->connect once there is a mode (karr k211), because pool_size is
# the async backend's setting. But the backend sized its pool only from a
# pool_size key of a hash answer, so such a pool silently ran at the default
# size, and a pool_size given beside the broker silently beat a different one
# in the answer.
#
# What this file claims:
#   1. a pool_size among a DBI-form answer's attributes sizes the backend's
#      pool and stays out of the owner's DBI->connect -- with the mode among
#      the same attributes, with the mode beside the broker, and from the
#      answer's extra-attributes hash;
#   2. a hash answer's own pool_size still sizes it;
#   3. pool_size beside the broker and in the answer: the same value is
#      accepted; different values throw when the backend is built, naming
#      pool_size and neither value -- not one of them silently winning;
#   4. given nowhere, the pool keeps its default size.
#
# THE SUBSTITUTIONS: a fake driver storage (DBIO::Test::Storage registered for
# the DBD name 'FakeDBD'); fake async modes whose transports run core's own
# DBIO::Storage::Async::connect_info; DBI->connect records its arguments.

{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeDBD => __PACKAGE__);
}

# A transport running core's connect_info, declaring nothing.
{
  package T::CoreBackend;
  use base 'DBIO::Storage::Async';
  sub disconnect { 1 }
}

# The same, declaring broker_connect_options.
{
  package T::DeclaringBackend;
  use base 'DBIO::Storage::Async';
  sub transport_capabilities { qw( broker_connect_options ) }
  sub disconnect { 1 }
}

T::FakeDriver::Storage->register_async_mode(k245core     => 'T::CoreBackend');
T::FakeDriver::Storage->register_async_mode(k245declares => 'T::DeclaringBackend');

# A broker answering the DBI form, as Vault does: its attributes (and,
# optionally, extra attributes) as given.
{
  package T::DBIFormBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, $attrs, $extra) = @_; bless { attrs => $attrs, extra => $extra }, $class }
  sub connect_info_for {
    my $self = shift;
    return [ 'dbi:FakeDBD:dbname=app', 'u', 'p', { %{ $self->{attrs} } },
      ($self->{extra} ? { %{ $self->{extra} } } : ()) ];
  }
}

# A broker answering a hash of connection parameters.
{
  package T::HashBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, %hash) = @_; bless { hash => \%hash }, $class }
  sub connect_info_for { return { %{ $_[0]{hash} } } }
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

sub connect_with {
  my (@connect_info) = @_;
  my $schema = DBIO::Test->init_schema(
    no_connect   => 1,
    storage_type => '+T::FakeDriver::Storage',
  );
  return $schema->connection(@connect_info)->storage;
}

sub dbi_connect_attrs {
  my ($storage) = @_;
  my @connects;
  no warnings qw(redefine once);
  require DBI;
  local *DBI::connect = sub { shift; push @connects, [@_]; T::FakeDBH->new };
  $storage->_connect;
  return $connects[0][3];
}

# ---------------------------------------------------------------------------
# 1. Among a DBI-form answer's attributes.
# ---------------------------------------------------------------------------
{
  my $storage = connect_with(T::DBIFormBroker->new({ async => 'k245core', pool_size => 3 }));

  ok !exists dbi_connect_attrs($storage)->{pool_size},
    "the mode among the answer's attributes: pool_size stays out of the owner's DBI->connect";
  is $storage->async->{_pool_size}, 3, '... and sizes the pool';
}

{
  my $storage = connect_with(T::DBIFormBroker->new({ pool_size => 3 }), { async => 'k245core' });

  ok !exists dbi_connect_attrs($storage)->{pool_size},
    'the mode beside the broker: pool_size stays out of the owner\'s DBI->connect';
  is $storage->async->{_pool_size}, 3, '... and sizes the pool';
}

{
  my $storage = connect_with(
    T::DBIFormBroker->new({ async => 'k245core', pool_size => 3 }, { pool_size => 4 }),
  );
  is $storage->async->{_pool_size}, 4, "the answer's extra attributes win over its attributes";
}

# ---------------------------------------------------------------------------
# 2. A hash answer's own key.
# ---------------------------------------------------------------------------
{
  my $storage = connect_with(
    T::HashBroker->new(dbname => 'app', user => 'u', password => 'p', pool_size => 6),
    { async => 'k245core' },
  );
  is $storage->async->{_pool_size}, 6, "a hash answer's pool_size sizes the pool";
}

# ---------------------------------------------------------------------------
# 3. In the answer and beside the broker.
# ---------------------------------------------------------------------------
{
  my $storage = connect_with(
    T::DBIFormBroker->new({ pool_size => 3 }),
    { async => 'k245declares', pool_size => 3 },
  );
  is $storage->async->{_pool_size}, 3, 'the same value in both places is accepted';
}

{
  my $storage = connect_with(
    T::DBIFormBroker->new({ async => 'k245declares', pool_size => 4711 }),
    { pool_size => 4712 },
  );
  throws_ok { $storage->async }
    qr/Connection setting 'pool_size' is given both beside the AccessBroker and in the broker's answer, with different values/,
    'different values throw when the backend is built, naming pool_size';
  unlike $@, qr/471[12]/, '... and neither value';
}

{
  my $storage = connect_with(
    T::HashBroker->new(dbname => 'app', user => 'u', password => 'p', pool_size => 6),
    { async => 'k245declares', pool_size => 2 },
  );
  throws_ok { $storage->async } qr/Connection setting 'pool_size' is given both/,
    '... for a hash answer as well';
}

# ---------------------------------------------------------------------------
# 4. Given nowhere.
# ---------------------------------------------------------------------------
{
  my $storage = connect_with(T::DBIFormBroker->new({ async => 'k245core' }));
  is $storage->async->{_pool_size}, 5, 'no pool_size anywhere: the default pool size';
  is(DBIO::Storage::Async->_access_broker_pool_size([ 'dbi:FakeDBD:x', 'u', 'p', {} ], undef),
    undef, '... which _access_broker_pool_size leaves to the pool: it answers undef');
}

done_testing;
