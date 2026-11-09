use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker::Static;

# karr k397. The connect options an async backend takes form a DECLARED list.
# Core names pool_size, acquire_timeout, max_waiters and txn_timeout in one place
# (DBIO::Storage::_core_async_option_names); a backend adds its own with the
# class method async_option_names. With an async mode set, the owning sync
# storage keeps every name of that list out of its own DBI->connect and the
# backend receives it; a name nobody declares is refused like any unknown
# connect attribute; without a mode the DBD decides, as before.
#
# The claims:
#   1. a core option and a backend-declared one reach the backend
#      (async_option) -- in the hash form, the DBI form and beside an
#      AccessBroker -- and not the DBD (not DBI->connect's attributes, nor the
#      conninfo the transport's reshape seam builds);
#   2. an option no backend declares throws as an unknown attribute, also one a
#      different mode's backend declares;
#   3. without an async mode none of them is a DBIO option: the DBD's verdict
#      stands;
#   4. a value the core checks is checked when the connect info is read, and the
#      message names the option and never the value;
#   5. a new connect_info starts from none; the pool is given acquire_timeout
#      and max_waiters by the storage that owns it.

{
  package K397D::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub async_option_names { qw( statement_timeout max_in_flight ) }
  sub _normalize_conninfo {
    my ($self, $info) = @_;
    return $info if ref $info->[0] eq 'HASH' || (Scalar::Util::blessed($info->[0]) && $info->[0]->isa('DBIO::AccessBroker'));
    my ($dsn, $user, $pass, $attrs) = @$info;
    return [ { dsn => $dsn, user => $user, password => $pass, %{ $attrs || {} } }, {} ];
  }
  sub disconnect { 1 }
  sub pool {
    my $self = shift;
    return $self->{pool} ||= K397D::Pool->new(
      conninfo => 'x', size => 1, future_class => 'DBIO::Test::Future', storage => $self,
    );
  }
  sub _delay { DBIO::Test::Future->new }
}

{
  package K397D::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { bless {}, 'K397D::Conn' }
}

{
  # A backend that declares nothing of its own.
  package K397D::PlainBackend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub disconnect { 1 }
}

{
  package K397D::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
  DBIO::Storage::DBI->register_driver(K397DMock => __PACKAGE__);
  sub _dbd_attribute_prefixes { 'k397d_' }
}

K397D::Storage->register_async_mode(k397mode  => 'K397D::Backend');
K397D::Storage->register_async_mode(k397plain => 'K397D::PlainBackend');

my $schema = DBIO::Test->init_schema;

sub storage_for {
  my ($info) = @_;
  my $storage = K397D::Storage->new($schema);
  $storage->connect_info($info);
  return $storage;
}

# --- the lists -------------------------------------------------------------------------
is_deeply [ DBIO::Storage::Async->async_option_names ], [],
  'a backend declares nothing of its own by default';
is_deeply [ sort DBIO::Storage::Async->declared_async_option_names ],
  [ sort qw( pool_size acquire_timeout max_waiters txn_timeout reset_timeout ) ],
  'the core\'s names are the declared list';
is_deeply [ sort K397D::Backend->declared_async_option_names ],
  [ sort qw( pool_size acquire_timeout max_waiters txn_timeout reset_timeout statement_timeout max_in_flight ) ],
  'a backend\'s names extend it, each once';

# --- 1. the hash form ---------------------------------------------------------------------
{
  my $storage = storage_for([{
    dsn => 'dbi:K397DMock:', async => 'k397mode', RaiseError => 1,
    pool_size => 2, acquire_timeout => 3, max_waiters => 4, txn_timeout => 9,
    statement_timeout => 7, max_in_flight => 8,
  }]);

  my $attrs = $storage->_dbio_connect_attributes;
  is_deeply [ grep { exists $attrs->{$_} } qw( pool_size acquire_timeout max_waiters txn_timeout reset_timeout statement_timeout max_in_flight ) ], [],
    'hash form: no async option reaches the DBI->connect attributes';
  is $attrs->{RaiseError}, 1, 'hash form: a DBI attribute does';

  my $async = $storage->async;
  isa_ok $async, 'K397D::Backend';
  is $async->async_option($_->[0]), $_->[1], "hash form: the backend has $_->[0]"
    for [ acquire_timeout => 3 ], [ max_waiters => 4 ], [ txn_timeout => 9 ],
        [ statement_timeout => 7 ], [ max_in_flight => 8 ];
  is $async->{_pool_size}, 2, 'hash form: pool_size sizes the pool, as before';

  my $conninfo = $async->{_conninfo};
  is_deeply [ grep { exists $conninfo->{$_} } qw( acquire_timeout max_waiters txn_timeout statement_timeout max_in_flight ) ],
    [], 'hash form: nothing of it is in the conninfo the transport connects with';

  my $pool = $async->pool;
  is $pool->{max_waiters}, 4, 'the pool is given max_waiters by the storage that owns it';
  is $pool->{acquire_timeout}, 3, 'the pool is given acquire_timeout by the storage that owns it';
}

# --- 1. the DBI form -------------------------------------------------------------------------
{
  my $storage = storage_for([
    'dbi:K397DMock:', 'user', 'pass',
    { async => 'k397mode', RaiseError => 1, acquire_timeout => 6, statement_timeout => 2 },
  ]);
  my $attrs = $storage->_dbio_connect_attributes;
  is_deeply [ grep { exists $attrs->{$_} } qw( acquire_timeout statement_timeout ) ], [],
    'DBI form: no async option reaches the DBI->connect attributes';
  is $attrs->{RaiseError}, 1, 'DBI form: a DBI attribute does';
  my $async = $storage->async;
  is $async->async_option('acquire_timeout'), 6, 'DBI form: the backend has acquire_timeout';
  is $async->async_option('statement_timeout'), 2, 'DBI form: and its own option';
  ok !exists $async->{_conninfo}{statement_timeout}, 'DBI form: neither is in the conninfo';
}

# --- 1. beside an AccessBroker -----------------------------------------------------------------
{
  my $broker  = DBIO::AccessBroker::Static->new(
    host => 'h', dbname => 'app', username => 'u', password => 'p',
  );
  my $storage = storage_for([ $broker, {
    async => 'k397mode', acquire_timeout => 5, max_waiters => 2, statement_timeout => 3,
  } ]);
  my $async = $storage->async;
  is $async->async_option('acquire_timeout'), 5,
    'beside a broker: the backend has the core option without declaring broker_connect_options';
  is $async->async_option('max_waiters'), 2, 'beside a broker: max_waiters';
  is $async->async_option('statement_timeout'), 3, 'beside a broker: and its own option';
}

# --- 2. what nobody declares ---------------------------------------------------------------------
throws_ok {
  storage_for([{ dsn => 'dbi:K397DMock:', async => 'k397mode', no_such_option => 1 }]);
} qr/Unknown connect attribute\(s\) 'no_such_option'/, 'an option nobody declares is an unknown attribute';

throws_ok {
  storage_for([{ dsn => 'dbi:K397DMock:', async => 'k397plain', statement_timeout => 1 }]);
} qr/Unknown connect attribute\(s\) 'statement_timeout'/,
  'an option another mode\'s backend declares is unknown here';

lives_ok {
  storage_for([{ dsn => 'dbi:K397DMock:', async => 'k397plain', acquire_timeout => 1, txn_timeout => 1, max_waiters => 1 }]);
} 'the core\'s options are known to every backend';

# --- 3. without a mode the DBD decides ---------------------------------------------------------------
for my $name (qw( acquire_timeout max_waiters txn_timeout statement_timeout )) {
  throws_ok {
    storage_for([{ dsn => 'dbi:K397DMock:', $name => 1 }]);
  } qr/Unknown connect attribute\(s\) '$name'/, "no async mode: $name is no DBIO option, the DBD's verdict stands";
}

# --- 4. values the core checks --------------------------------------------------------------------------
for my $bad (
  [ acquire_timeout => 'soon' ], [ acquire_timeout => -3 ], [ max_waiters => 0 ],
  [ max_waiters => 'many' ], [ txn_timeout => 0 ], [ txn_timeout => 'long' ],
) {
  my ($name, $value) = @$bad;
  my $storage = storage_for([{ dsn => 'dbi:K397DMock:', async => 'k397mode', $name => $value }]);
  my $error = eval { $storage->async; 1 } ? '' : "$@";
  like $error, qr/Connect option '$name' takes/, "an invalid $name is refused when the backend reads it";
  unlike $error, qr/soon|many|long/, "the message for $name names no value";
}

# --- 5. a new connect_info starts from none ------------------------------------------------------------------
{
  my $async = K397D::Backend->new($schema);
  $async->connect_info([{ dsn => 'x', acquire_timeout => 3, statement_timeout => 1 }]);
  is $async->async_option('acquire_timeout'), 3, 'backend alone: connect_info keeps the option';
  $async->connect_info([{ dsn => 'y' }]);
  is $async->async_option('acquire_timeout'), undef, 'backend alone: a new connect_info forgets it';
  is $async->async_option('statement_timeout'), undef, 'backend alone: also the backend\'s own';
}

done_testing;
