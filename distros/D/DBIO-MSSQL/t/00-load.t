use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MSSQL
  DBIO::MSSQL::Adapter
  DBIO::MSSQL::Result
  DBIO::MSSQL::Storage
  DBIO::MSSQL::Storage::DateTime::Format
  DBIO::MSSQL::Storage::Sybase
  DBIO::MSSQL::Storage::Sybase::NoBindVars
  DBIO::MSSQL::Storage::Sybase::DateTime::Format
  DBIO::MSSQL::SQLMaker
  DBIO::MSSQL::DDL
  DBIO::MSSQL::Deploy
  DBIO::MSSQL::Diff
  DBIO::MSSQL::Diff::Column
  DBIO::MSSQL::Diff::ForeignKey
  DBIO::MSSQL::Diff::Index
  DBIO::MSSQL::Diff::Table
  DBIO::MSSQL::Introspect
  DBIO::MSSQL::Introspect::Columns
  DBIO::MSSQL::Introspect::ForeignKeys
  DBIO::MSSQL::Introspect::Indexes
  DBIO::MSSQL::Introspect::Tables
  DBIO::Shortcut::ms
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
