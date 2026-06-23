use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::Firebird
  DBIO::Shortcut::fb
  DBIO::Firebird::Storage
  DBIO::Firebird::Storage::InterBase
  DBIO::Firebird::Storage::Common
  DBIO::Firebird::SQLMaker
  DBIO::Firebird::DateTime::Format
  DBIO::Firebird::Type
  DBIO::Firebird::DDL
  DBIO::Firebird::Deploy
  DBIO::Firebird::Diff
  DBIO::Firebird::Diff::Column
  DBIO::Firebird::Diff::Index
  DBIO::Firebird::Diff::Table
  DBIO::Firebird::Introspect
  DBIO::Firebird::Introspect::Columns
  DBIO::Firebird::Introspect::ForeignKeys
  DBIO::Firebird::Introspect::Indexes
  DBIO::Firebird::Introspect::Uniques
  DBIO::Firebird::Introspect::Tables
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
