#!/usr/bin/env perl
# t/00-load.t — basic compile/use check for every DBIO::ClickHouse module.

use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::ClickHouse
  DBIO::ClickHouse::Test
  DBIO::ClickHouse::Test::Schema
  DBIO::ClickHouse::Test::Schema::Hit
  DBIO::ClickHouse::Test::Schema::HotHit
  DBIO::ClickHouse::Test::Schema::Probe
  DBIO::ClickHouse::Test::Schema::Reading
  DBIO::ClickHouse::Test::Schema::Snapshot
  DBIO::ClickHouse::Test::Schema::Unsorted
  DBIO::ClickHouse::Storage
  DBIO::ClickHouse::Storage::TxnScopeGuard
  DBIO::ClickHouse::SQLMaker
  DBIO::ClickHouse::Result
  DBIO::ClickHouse::DDL
  DBIO::ClickHouse::DDL::Emit
  DBIO::ClickHouse::Introspect
  DBIO::ClickHouse::Introspect::Tables
  DBIO::ClickHouse::Introspect::Columns
  DBIO::ClickHouse::Introspect::Indexes
  DBIO::ClickHouse::Introspect::Util
  DBIO::ClickHouse::Util
  DBIO::ClickHouse::Diff
  DBIO::ClickHouse::Diff::Table
  DBIO::ClickHouse::Diff::Column
  DBIO::ClickHouse::Diff::Index
  DBIO::ClickHouse::Diff::View
  DBIO::ClickHouse::Deploy
  DBIO::Shortcut::ch
);

use_ok($_) for @modules;

done_testing;
