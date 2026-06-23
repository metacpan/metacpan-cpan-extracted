#!/usr/bin/env perl
# t/00-load.t — basic compile/use check for every DBIO::DuckDB module.

use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::DuckDB
  DBIO::DuckDB::Test
  DBIO::DuckDB::Storage
  DBIO::DuckDB::SQLMaker
  DBIO::DuckDB::DDL
  DBIO::DuckDB::DDL::Emit
  DBIO::DuckDB::Deploy
  DBIO::DuckDB::Introspect
  DBIO::DuckDB::Introspect::Tables
  DBIO::DuckDB::Introspect::Columns
  DBIO::DuckDB::Introspect::Indexes
  DBIO::DuckDB::Introspect::ForeignKeys
  DBIO::DuckDB::Diff
  DBIO::DuckDB::Diff::Table
  DBIO::DuckDB::Diff::Column
  DBIO::DuckDB::Diff::Index
  DBIO::Shortcut::du
);

use_ok($_) for @modules;

done_testing;
