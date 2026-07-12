# ABSTRACT: karr #66 -- async connect_info must not leak DBIO-private attrs to DBI->connect
use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# ADR 0030's future_io async mode embeds a DBIO::Storage::Async backend
# inside the sync DBIO::Storage::DBI instance (_async_storage,
# lib/DBIO/Storage/DBI.pm ~1023). The SYNC side's own connect_info()
# (~line 620) correctly strips DBIO-private connect attrs -- async,
# quote_char/name_sep/quote_names, storage_options incl. cursor_class, and
# ignore_version -- before they reach DBI->connect (~656-661). But
# _async_storage hands the embedded backend the RAW, pre-strip
# _connect_info, so those same private attrs flow untouched into the async
# backend's own connect_info (DBIO::Storage::Async ~line 252) and land in
# {_conninfo}, which a pool ultimately feeds to DBI->connect. A strict DBD
# (e.g. DBD::MariaDB) rejects an unrecognised 'async' attribute outright.
#
# Reproduced here with mock storage only -- no real DBD, no dbi:SQLite.

# A trivial, already-declared class so DBIO::Storage's cursor_class
# component_class setter has something harmless to "load".
{ package Karr66::FakeCursor; }

# --- The embedded async backend: convention sibling of Karr66::Storage below.
# Minimal concrete DBIO::Storage::Async, overriding only the seams this test
# drives (future_class, the connect-info reshape seam, and pool).
{
  package Karr66::Storage::Async;
  use base 'DBIO::Storage::Async';

  sub future_class { 'Future' }

  # DB-specific connect-info reshaping seam (identity by default in the base
  # class). A real driver adapter reshapes the DBI-style
  # [$dsn, $user, $pass, \%attrs] array _async_storage hands it into its own
  # native [ \%conninfo, \%opts ] shape -- exactly the kind of reshape that
  # (today) does nothing to strip the DBIO-private keys out of %attrs first.
  sub _normalize_conninfo {
    my ($self, $info) = @_;
    my ($dsn, $user, $pass, $attrs) = @$info;
    return [ { dsn => $dsn, user => $user, password => $pass, %{ $attrs || {} } }, {} ];
  }

  # Pool seam: a real driver's pool ultimately calls DBI->connect (or an
  # engine-native equivalent) with the conninfo hash. Karr66::MockPool below
  # simulates a STRICT DBD by dying the moment it sees a leaked 'async' key --
  # the DBD::MariaDB "Unknown attribute async" failure from karr #66.
  sub pool {
    my $self = shift;
    $self->{pool} ||= Karr66::MockPool->new(
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size} || 5,
    );
  }
}

{
  package Karr66::MockPool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection {
    my ($self, $conninfo) = @_;
    die "Unknown attribute 'async' (strict DBD simulation, karr #66)\n"
      if ref $conninfo eq 'HASH' && exists $conninfo->{async};
    return bless { conninfo => $conninfo }, 'Karr66::MockConn';
  }
}

# --- The sync driver storage: future_io must resolve Karr66::Storage::Async
# by convention (ref($storage) . '::Async'), exactly like a real driver ------
{
  package Karr66::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}

my $schema  = DBIO::Test->init_schema;
my $storage = Karr66::Storage->new($schema);

# The connect attrs a caller writes for a real driver: async mode selection
# plus quoting/versioning/storage options that are DBIO-private and never
# meant for DBI->connect.
$storage->connect_info([
  'dbi:Karr66Mock:', 'user', 'pass',
  {
    async          => 'future_io',
    quote_char     => '`',
    name_sep       => '.',
    quote_names    => 1,
    ignore_version => 1,
    cursor_class   => 'Karr66::FakeCursor',
  },
]);

is $storage->_async_mode, 'future_io',
  'sync connect_info() pulled async_mode out for the instance';

# Reference behaviour: the SYNC side's own DBI-bound attrs are already clean.
# (This is the correct behaviour the async side below is missing.)
my $sync_dbi_attrs = $storage->_dbi_connect_info->[3] || {};
for my $key (qw(async quote_char name_sep quote_names ignore_version cursor_class)) {
  ok !exists $sync_dbi_attrs->{$key},
    "sync side: '$key' does not reach the DBI connect attrs";
}

# --- The bug: the embedded async backend gets the RAW, un-stripped info ----
my $async = $storage->async;
isa_ok $async, 'Karr66::Storage::Async',
  'future_io resolved the convention adapter';

for my $key (qw(async quote_char name_sep quote_names ignore_version cursor_class)) {
  ok !exists $async->{_conninfo}{$key},
    "async side: '$key' must not leak into the async backend's conninfo";
}

# --- Reproduce the MariaDB failure abstractly: a strict-DBD pool must not
# see the leaked 'async' attribute when it opens a connection -------------
lives_ok { $async->pool->acquire->get }
  'a strict-DBD pool does not choke on a leaked async attribute (karr #66)';

# --- TODO: where should quote_char/name_sep/quote_names actually land? -----
# Nothing today threads them into the async sql_maker seam: an async
# backend's _sql_maker_args (DBIO::Storage::Async, default empty) is
# hard-overridden per-driver with a STATIC quote_char, never sourced from
# connect_info. Fixing the leak (stripping these out of what reaches
# DBI->connect) must not silently drop the caller's quoting config -- but
# wiring the correct sink is out of scope for karr #66, so it is tracked
# here as a TODO rather than blocking the leak fix.
TODO: {
  local $TODO = 'karr #66 follow-up: quote_char/name_sep/quote_names from '
    . 'connect_info are not yet threaded into the async sql_maker seam '
    . '(_sql_maker_args) -- only their DBI->connect leak is fixed here';

  my %sm_args = $async->_sql_maker_args;
  is $sm_args{quote_char}, '`',
    'quote_char from connect_info reaches the async sql_maker args';
}

done_testing;
