use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MySQL::Adapter
  DBIO::MySQL::Introspect
  DBIO::MySQL::Introspect::Tables
  DBIO::MySQL::Introspect::Columns
  DBIO::MySQL::Introspect::Indexes
  DBIO::MySQL::Introspect::ForeignKeys
  DBIO::MySQL::Introspect::Util
  DBIO::MySQL::DDL
  DBIO::MySQL::Diff
  DBIO::MySQL::Diff::Table
  DBIO::MySQL::Diff::Column
  DBIO::MySQL::Diff::Index
  DBIO::MySQL::Diff::ForeignKey
  DBIO::MySQL::Deploy
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
