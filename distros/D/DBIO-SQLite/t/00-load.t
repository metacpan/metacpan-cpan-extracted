use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::SQLite
  DBIO::SQLite::Adapter
  DBIO::SQLite::DDL
  DBIO::SQLite::Deploy
  DBIO::SQLite::Diff
  DBIO::SQLite::Diff::Column
  DBIO::SQLite::Diff::Index
  DBIO::SQLite::Diff::Rebuild
  DBIO::SQLite::Diff::Table
  DBIO::SQLite::Diff::View
  DBIO::SQLite::Extension
  DBIO::SQLite::Extension::FTS5
  DBIO::SQLite::Extension::RTree
  DBIO::SQLite::Extension::VirtualTable
  DBIO::SQLite::Introspect
  DBIO::SQLite::Introspect::Columns
  DBIO::SQLite::Introspect::ForeignKeys
  DBIO::SQLite::Introspect::Indexes
  DBIO::SQLite::Introspect::Tables
  DBIO::SQLite::Introspect::Triggers
  DBIO::SQLite::Result
  DBIO::Shortcut::sqlite
  DBIO::SQLite::SQLMaker
  DBIO::SQLite::Storage
  DBIO::SQLite::Test
  DBIO::SQLite::Util
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
