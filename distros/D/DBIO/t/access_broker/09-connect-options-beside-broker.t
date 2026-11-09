# ABSTRACT: The connect options of a broker-backed connection are given beside the broker
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::Async;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k243, ADR 0030 addendum 2026-09-27 II). After k240 the hash
# beside a broker took the async mode and nothing else, so a connection whose
# details come from a broker answering a hash of connection parameters
# (DBIO::AccessBroker::Static) had no way at all to set DBI attributes,
# quote_names, on_connect_do/call or pool_size. The hash now takes the connect
# options -- and with an async mode, the ones a backend applies itself go to
# the backend too, or the connection refuses the backend.
#
# What this file claims:
#   1. beside a broker, the connect options land exactly where they land when
#      the same options come with a DSN: DBI attributes, storage options
#      (on_connect_do), SQL maker options (quote_names), ignore_version, and
#      pool_size as a DBI attribute of a sync connection (karr k211);
#   2. they join the broker's answer on every connection, not only the first:
#      the broker is asked again per connect, and a rotated answer still gets
#      them;
#   3. a setting given both beside the broker and in a DBI-form answer must
#      have the same value in both; different values throw, naming the setting
#      and not its values -- when configured, and on a later connect whose
#      answer changed; the very same reference counts as the same value;
#   4. the connection itself (dsn, user, password, dbh_maker, dbname, host,
#      port) is the broker's answer and throws beside it, naming the keys;
#   5. with an async mode, a backend gets the broker alone while the hash
#      holds only what the owning storage applies (mode, storage and SQL maker
#      options); the backend's owner carries on_connect_do, so pooled
#      connections replay it (ADR 0049);
#   6. DBD attributes or pool_size beside the broker go to the backend as
#      [ $broker, \%options ] -- the connect info as given -- only for a
#      transport declaring broker_connect_options; any other transport is
#      refused at resolution, naming the transport, the settings and the
#      capability, while the sync connection keeps them;
#   7. core DBIO::Storage::Async::connect_info takes that form for a declaring
#      transport: private keys stripped centrally (ADR 0048), pool_size sizes
#      the pool, the DBD attributes are kept for the transport, and merging
#      them into an answer follows the rule of claim 3; a transport that does
#      not declare it refuses non-empty options, and a hash holding only
#      private keys is the bare broker form. It keeps no conninfo of its own
#      from the broker's answer: every connection asks the broker anew, so a
#      stored copy could only be an earlier answer, with its password -- and
#      a storage whose broker is taken away gets no such copy (karr k252).
#
# THE SUBSTITUTIONS: a fake driver storage (DBIO::Test::Storage registered for
# the DBD name 'FakeDBD'); fake async modes whose backends record the connect
# info they get; DBI->connect records its arguments.
#
# pg_enable_utf8 stands for "a private attribute of this connection's DBD"
# throughout. Since karr k307 a sync connection refuses a lowercase key beside
# the broker that is not one (32-dbi-broker-unapplied-options-beside.t), so the
# fake driver storage declares pg_ as the prefix of its DBD, as the storage of
# a DBD outside DBI's prefix registry does. The value that must not be quoted
# in claim 3 is carried by a private_ attribute for the same reason.

{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(FakeDBD => __PACKAGE__);
  sub _dbd_attribute_prefixes { 'pg_' }
}

# A transport that does not declare broker_connect_options and records what
# it was handed.
{
  package T::RecordingBackend;
  use base 'DBIO::Storage::Async';
  sub new { my ($class, $schema) = @_; bless { schema => $schema }, $class }
  sub connect_info { my $self = shift; $self->{connect_info} = shift if @_; $self->{connect_info} }
  sub disconnect { 1 }
}

# A transport that declares it, running core's own connect_info; it records
# the connect info it was handed before core strips it.
{
  package T::DeclaringBackend;
  use base 'DBIO::Storage::Async';
  sub transport_capabilities { qw( broker_connect_options ) }
  sub disconnect { 1 }
  sub connect_info {
    my $self = shift;
    $self->{handed} = $_[0] if @_;
    return $self->SUPER::connect_info(@_);
  }
}

T::FakeDriver::Storage->register_async_mode(k243plain    => 'T::RecordingBackend');
T::FakeDriver::Storage->register_async_mode(k243declares => 'T::DeclaringBackend');

# A broker answering the DBI form, with attributes of its own; each answer
# names a fresh user, as a rotating broker's would.
{
  package T::DBIFormBroker;
  use base 'DBIO::AccessBroker';
  sub new { my ($class, @answers) = @_; bless { answers => \@answers, calls => 0 }, $class }
  sub connect_info_for {
    my $self  = shift;
    my $n     = ++$self->{calls};
    my @attrs = @{ $self->{answers} };
    my $attrs = $attrs[ $n > @attrs ? $#attrs : $n - 1 ] || {};
    return [ 'dbi:FakeDBD:dbname=app', "user_$n", 'p', { %$attrs } ];
  }
}

{
  package T::FakeDBH;
  sub new { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]{$_[1]} }
}

my %DEFAULT_ATTRS = (
  AutoCommit         => 1,
  PrintError         => 0,
  RaiseError         => 1,
  ShowErrorStatement => 0,
);

sub static_broker {
  return DBIO::AccessBroker::Static->new(
    host => 'db.example', dbname => 'appdb', username => 'app', password => 's3cret',
  );
}

sub connect_with {
  my (@connect_info) = @_;
  my $schema = DBIO::Test->init_schema(
    no_connect   => 1,
    storage_type => '+T::FakeDriver::Storage',
  );
  return $schema->connection(@connect_info)->storage;
}

sub dbi_connects {
  my ($storage, $times) = @_;
  my @connects;
  no warnings qw(redefine once);
  require DBI;
  local *DBI::connect = sub { shift; push @connects, [@_]; T::FakeDBH->new };
  $storage->_connect for 1 .. $times;
  return @connects;
}

# ---------------------------------------------------------------------------
# 1. Beside a broker, where they land with a DSN.
# ---------------------------------------------------------------------------
{
  my $on_connect = [ 'SET search_path TO app' ];
  my %options = (
    pg_enable_utf8      => 1,
    LongReadLen         => 4096,
    pool_size           => 3,
    on_connect_do       => $on_connect,
    disable_sth_caching => 1,
    quote_names         => 0,
    ignore_version      => 1,
  );

  my $broker = static_broker();
  my $beside = connect_with($broker, { %options });
  my $dsn    = connect_with(
    'dbi:FakeDBD:dbname=appdb;host=db.example', 'app', 's3cret', { %options },
  );

  is $beside->access_broker, $broker, 'the broker beside its options is attached';
  is_deeply $beside->_dbi_connect_info, $dsn->_dbi_connect_info,
    'DBI connect info: the same as with a DSN';
  is_deeply $beside->_dbi_connect_info->[3],
    { %DEFAULT_ATTRS, pg_enable_utf8 => 1, LongReadLen => 4096, pool_size => 3 },
    '... the DBI attributes, pool_size among them on a sync connection (k211)';
  is $beside->on_connect_do, $on_connect, 'on_connect_do is the storage option';
  ok $beside->disable_sth_caching, 'disable_sth_caching is the storage option';
  is_deeply $beside->_sql_maker_opts, $dsn->_sql_maker_opts,
    'SQL maker options: the same as with a DSN';
  is $beside->_sql_maker_opts->{quote_names}, 0, '... quote_names => 0 among them';
  is_deeply $beside->_dbio_connect_attributes, $dsn->_dbio_connect_attributes,
    'the introspectable attributes (ignore_version) as with a DSN';
  ok !exists $beside->_dbi_connect_info->[3]{ignore_version},
    '... and ignore_version stays out of DBI->connect';
  ok !defined $beside->_async_mode, 'no mode: a sync connection';
}

# ---------------------------------------------------------------------------
# 2. On every connection.
# ---------------------------------------------------------------------------
{
  my $storage  = connect_with(T::DBIFormBroker->new({ PrintWarn => 0 }), { pg_enable_utf8 => 1 });
  my @connects = dbi_connects($storage, 2);

  is scalar @connects, 2, 'two connects';
  is $connects[1][1], 'user_3', 'the second connect has the rotated answer';
  is_deeply [ map { $_->[3] } @connects ], [
    ({ %DEFAULT_ATTRS, PrintWarn => 0, pg_enable_utf8 => 1 }) x 2,
  ], "the options beside the broker join each answer's attributes";
}

# ---------------------------------------------------------------------------
# 3. A setting in both places.
# ---------------------------------------------------------------------------
{
  my $storage = connect_with(T::DBIFormBroker->new({ pg_enable_utf8 => 1 }), { pg_enable_utf8 => 1 });
  is $storage->_dbi_connect_info->[3]{pg_enable_utf8}, 1, 'the same value in both places is accepted';
}

throws_ok {
  connect_with(T::DBIFormBroker->new({ pg_enable_utf8 => 0 }), { pg_enable_utf8 => 1 });
} qr/Connection setting 'pg_enable_utf8' is given both beside the AccessBroker and in the broker's answer, with different values/,
  'different values throw, naming the setting';

{
  my $on_connect = [ 'SET x = 1' ];
  my $storage = connect_with(
    T::DBIFormBroker->new({ on_connect_do => $on_connect }),
    { on_connect_do => $on_connect },
  );
  is $storage->on_connect_do, $on_connect, 'the very same reference in both places is the same value';

  throws_ok {
    connect_with(
      T::DBIFormBroker->new({ on_connect_do => [ 'SET x = 1' ] }),
      { on_connect_do => [ 'SET x = 1' ] },
    );
  } qr/Connection setting 'on_connect_do' is given both/,
    'two different references are two settings, and throw';
}

{
  my $storage = connect_with(
    T::DBIFormBroker->new({}, { pg_enable_utf8 => 0, private_secret => 'hunter2' }),
    { pg_enable_utf8 => 1, private_secret => 'hunter2' },
  );
  throws_ok { dbi_connects($storage, 1) }
    qr/Connection setting 'pg_enable_utf8' is given both/,
    'an answer that changed to a different value throws on the next connect';
  unlike $@, qr/hunter2/, '... and the error names no value';
}

# ---------------------------------------------------------------------------
# 4. The connection itself is the broker's.
# ---------------------------------------------------------------------------
throws_ok {
  connect_with(static_broker(), { dsn => 'dbi:FakeDBD:x', password => 'p', host => 'other', quote_names => 1 });
} qr/the hash beside the broker takes connect options, not the connection itself: dsn, password, host/,
  'dsn, user, password, dbh_maker, dbname, host or port beside the broker throw, named';

# ---------------------------------------------------------------------------
# 5. Only settings the owner applies: the backend gets the broker alone.
# ---------------------------------------------------------------------------
{
  my $broker     = static_broker();
  my $on_connect = [ 'SET search_path TO app' ];
  my $storage    = connect_with($broker, {
    async          => 'k243plain',
    on_connect_do  => $on_connect,
    quote_names    => 0,
    ignore_version => 1,
  });

  my $backend = $storage->async;
  isa_ok $backend, 'T::RecordingBackend', 'a transport that does not declare it';
  is_deeply $backend->connect_info, [ $broker ], 'is handed the broker alone';
  is $backend->_owner_storage, $storage, '... its owner is this storage';
  is $backend->_owner_storage->on_connect_do, $on_connect,
    '... which carries the on_connect_do its pooled connections replay';
}

# ---------------------------------------------------------------------------
# 6. Settings a backend applies itself.
# ---------------------------------------------------------------------------
{
  my $storage = connect_with(static_broker(), {
    async => 'k243plain', pg_enable_utf8 => 1, pool_size => 3, on_connect_do => 'SET x = 1',
  });

  is_deeply $storage->_dbi_connect_info->[3], { %DEFAULT_ATTRS, pg_enable_utf8 => 1 },
    'the sync connection has the DBI attributes, without pool_size (k211)';

  throws_ok { $storage->async }
    qr/async mode 'k243plain': transport T::RecordingBackend does not take connection settings beside an AccessBroker \(it does not declare 'broker_connect_options'.*\), so pg_enable_utf8, pool_size would reach this connection but none of its pooled ones/s,
    'a transport that does not declare broker_connect_options is refused, named with the settings';
}

{
  my $broker  = static_broker();
  my %options = (async => 'k243declares', pg_enable_utf8 => 1, pool_size => 3, quote_names => 0);
  my $storage = connect_with($broker, { %options });

  my $backend = $storage->async;
  isa_ok $backend, 'T::DeclaringBackend', 'a transport that declares it';
  is_deeply $backend->{handed}, [ $broker, { %options } ],
    'is handed the connect info as given, the options beside the broker';
  is $backend->access_broker, $broker, '... takes the broker';
  is $backend->{_pool_size}, 3, '... sizes its pool by pool_size';
  is_deeply $backend->_access_broker_call_attributes, { pg_enable_utf8 => 1 },
    '... and keeps the DBD attributes, the private keys stripped';
}

# ---------------------------------------------------------------------------
# 7. Core's Storage::Async::connect_info on its own.
# ---------------------------------------------------------------------------
{
  my $broker = static_broker();
  my $async  = T::DeclaringBackend->new(undef);
  $async->connect_info([ $broker, {
    async => 'x', on_connect_do => 'SET x = 1', cursor_class => 'X', quote_char => '"',
    ignore_version => 1, pool_size => 7, mysql_enable_utf8mb4 => 1,
  } ]);

  is $async->access_broker, $broker, 'the broker beside its options is attached';
  ok $async->_conninfo_provider, '... with the per-spawn provider';
  is $async->{_pool_size}, 7, 'pool_size sizes the pool';
  is_deeply $async->_access_broker_call_attributes, { mysql_enable_utf8mb4 => 1 },
    'only the DBD attributes are kept for the transport';
  is $async->{_conninfo}, undef, "no conninfo is kept from the broker's answer";
  {
    my $detached = T::DeclaringBackend->new(undef);
    $detached->connect_info([ $broker ]);
    $detached->clear_access_broker;
    my $info = $detached->_current_async_connect_info('write');
    ok !defined $info->[0],
      "the broker taken away, the connect info is not the broker's earlier answer";
  }

  is_deeply $async->_merge_access_broker_settings({ PrintWarn => 0 }, $async->_access_broker_call_attributes),
    { PrintWarn => 0, mysql_enable_utf8mb4 => 1 },
    'merging them into an answer adds them';
  throws_ok {
    $async->_merge_access_broker_settings({ mysql_enable_utf8mb4 => 0 }, $async->_access_broker_call_attributes);
  } qr/Connection setting 'mysql_enable_utf8mb4' is given both/,
    '... and refuses a different value in the answer';

  $async->connect_info([ 'dbi:FakeDBD:dbname=x' ]);
  is_deeply $async->_access_broker_call_attributes, {}, 'a later non-broker connect_info clears them';
}

{
  my $async = DBIO::Storage::Async->new(undef);   # the base declares nothing
  throws_ok {
    $async->connect_info([ static_broker(), { pool_size => 3, pg_enable_utf8 => 1 } ]);
  } qr/Transport DBIO::Storage::Async does not take connection settings beside an AccessBroker.*pg_enable_utf8, pool_size/s,
    'a transport that does not declare it refuses non-empty options';

  my $broker = static_broker();
  $async->connect_info([ $broker, { async => 'x', on_connect_do => 'SET x = 1' } ]);
  is $async->access_broker, $broker, 'options that are all private: the bare broker form';
  is $async->{_pool_size}, 5, '... with the default pool size';
}

done_testing;
