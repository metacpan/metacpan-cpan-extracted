# ABSTRACT: pool_size sizes the async pool and must not reach the owner's sync DBI->connect
use strict;
use warnings;

use Test::More;

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::Storage::Async;

# karr k211. A connection opened with { async => $mode, pool_size => N } has
# TWO consumers of its connect attrs: the embedded async backend, whose pool
# N sizes (DBIO::Storage::Async::_normalize_async_connect_info), and the
# owning SYNC storage, which opens its own DBI handle whenever something asks
# it for one -- e.g. DBIO::MySQL::Storage::sql_maker reading _server_info on
# the upsert_async path. pool_size means nothing to a DBD: DBD::MariaDB
# rejects it outright ("Unknown attribute pool_size"), which is exactly how
# dbio-mysql-ev t/17-upsert-live.t died against a real MySQL. The sync split
# must keep it out of what reaches DBI->connect, while the async backend (fed
# the raw _connect_info) must still see it.

{
  package Karr211::Storage::Async;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub _normalize_conninfo {
    my ($self, $info) = @_;
    return [ { %{ $info->[0] } }, {} ] if ref $info->[0] eq 'HASH';
    my ($dsn, $user, $pass, $attrs) = @$info;
    return [ { dsn => $dsn, user => $user, password => $pass, %{ $attrs || {} } }, {} ];
  }
}

{
  package Karr211::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}

my $schema = DBIO::Test->init_schema;

# --- async connection, dsn/user/pass + \%attrs form -------------------------
{
  my $storage = Karr211::Storage->new($schema);
  $storage->connect_info([
    'dbi:Karr211Mock:', 'user', 'pass',
    { async => 'future_io', pool_size => 2, RaiseError => 1 },
  ]);

  my $dbi_attrs = $storage->_dbi_connect_info->[3] || {};
  ok !exists $dbi_attrs->{pool_size},
    'async connection: pool_size does not reach the sync DBI->connect attrs';
  is $dbi_attrs->{RaiseError}, 1,
    'async connection: a genuine DBI attribute still passes through';

  # The other consumer still gets it: the strip is on the sync split only.
  my $async = $storage->async;
  isa_ok $async, 'Karr211::Storage::Async', 'future_io convention adapter';
  is $async->{_pool_size}, 2,
    'async backend still sizes its pool from the connect attrs';
}

# --- async connection, single \%hash form (Catalyst-style) ------------------
{
  my $storage = Karr211::Storage->new($schema);
  $storage->connect_info([{
    dsn => 'dbi:Karr211Mock:', user => 'user', password => 'pass',
    async => 'future_io', pool_size => 3,
  }]);

  my $dbi_attrs = $storage->_dbi_connect_info->[3] || {};
  ok !exists $dbi_attrs->{pool_size},
    'hashref form: pool_size does not reach the sync DBI->connect attrs';
  is $storage->async->{_pool_size}, 3,
    'hashref form: async backend still sizes its pool';
}

# --- control: a SYNC connection has no pool, so nothing consumes pool_size ---
# There it is not DBIO's to swallow: it stays a DBI attribute and the DBD's
# verdict on it stands (fail loud rather than silently ignore a knob that has
# no effect on a connection without an async backend).
{
  my $storage = Karr211::Storage->new($schema);
  $storage->connect_info([ 'dbi:Karr211Mock:', 'user', 'pass', { pool_size => 2 } ]);

  is $storage->_dbi_connect_info->[3]{pool_size}, 2,
    'sync connection: pool_size is left to the DBD';
}

done_testing;
