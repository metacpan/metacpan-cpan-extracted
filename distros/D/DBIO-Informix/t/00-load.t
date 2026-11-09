use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::Informix
  DBIO::Shortcut::ix
  DBIO::Informix::Storage
  DBIO::Informix::SQLMaker
  DBIO::Informix::DDL
  DBIO::Informix::ColumnDef
  DBIO::Informix::Types
  DBIO::Informix::Deploy
  DBIO::Informix::Diff
  DBIO::Informix::Diff::Table
  DBIO::Informix::Diff::Column
  DBIO::Informix::Diff::Index
  DBIO::Informix::Diff::UniqueConstraint
  DBIO::Informix::Diff::PrimaryKey
  DBIO::Informix::Introspect
  DBIO::Informix::Introspect::Tables
  DBIO::Informix::Introspect::Columns
  DBIO::Informix::Introspect::Indexes
  DBIO::Informix::Introspect::ForeignKeys
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
