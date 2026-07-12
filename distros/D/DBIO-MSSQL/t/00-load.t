use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MSSQL
  DBIO::MSSQL::Adapter
  DBIO::MSSQL::Result
  DBIO::MSSQL::Storage
  DBIO::MSSQL::Storage::ODBC
  DBIO::MSSQL::Storage::DateTime::Format
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

my $have_sybase = eval { require DBIO::Sybase::Storage; 1 };

# These inherit from DBIO::Sybase::Storage (DBIO::Sybase is an optional dep).
my @optional = qw(
  DBIO::MSSQL::Storage::Sybase
  DBIO::MSSQL::Storage::Sybase::NoBindVars
);

plan tests => scalar(@modules) + scalar(@optional);

for my $mod (@modules) {
  use_ok($mod);
}

for my $mod (@optional) {
  ($have_sybase && eval "use $mod; 1")
    ? pass("use $mod")
    : pass("$mod skipped (missing optional deps)");
}
