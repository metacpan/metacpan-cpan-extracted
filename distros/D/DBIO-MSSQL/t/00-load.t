use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MSSQL
  DBIO::MSSQL::Adapter
  DBIO::MSSQL::Result
  DBIO::MSSQL::Storage
  DBIO::MSSQL::Storage::ODBC
  DBIO::MSSQL::Storage::StopAtFirstError
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

# The two cases are kept apart on purpose (karr k29). The old form answered
# both with pass(): a module that failed to load reported
# "skipped (missing optional deps)" whether or not DBIO::Sybase was actually
# there, so a syntax error in OUR OWN Sybase storage read as an absent
# optional dep and this file stayed green on a box that had DBIO::Sybase
# installed. Dep missing -> a real skip that says the module was not loaded;
# dep present -> use_ok, which goes red and prints the error it died of.
for my $mod (@optional) {
  SKIP: {
    skip "DBIO::Sybase not installed (optional dep), so $mod was NOT loaded", 1
      unless $have_sybase;

    use_ok($mod);
  }
}
