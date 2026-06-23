use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::DB2
  DBIO::Shortcut::db2
  DBIO::DB2::Storage
  DBIO::DB2::SQLMaker
  DBIO::DB2::Type
  DBIO::DB2::DDL
  DBIO::DB2::Deploy
  DBIO::DB2::Diff
  DBIO::DB2::Diff::Column
  DBIO::DB2::Diff::ForeignKey
  DBIO::DB2::Diff::Index
  DBIO::DB2::Diff::Table
  DBIO::DB2::Introspect
  DBIO::DB2::Introspect::Columns
  DBIO::DB2::Introspect::ForeignKeys
  DBIO::DB2::Introspect::Indexes
  DBIO::DB2::Introspect::Tables
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
