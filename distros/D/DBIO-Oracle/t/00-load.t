use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::Oracle
  DBIO::Oracle::DDL
  DBIO::Oracle::Deploy
  DBIO::Oracle::Diff
  DBIO::Oracle::Diff::Column
  DBIO::Oracle::Diff::Index
  DBIO::Oracle::Diff::Table
  DBIO::Oracle::Identifier
  DBIO::Shortcut::ora
  DBIO::Oracle::Introspect
  DBIO::Oracle::Introspect::Columns
  DBIO::Oracle::Introspect::ForeignKeys
  DBIO::Oracle::Introspect::Indexes
  DBIO::Oracle::Introspect::Keys
  DBIO::Oracle::Introspect::Tables
  DBIO::Oracle::Storage
  DBIO::Oracle::Storage::AutoIncrement
  DBIO::Oracle::Storage::ConnectSetup
  DBIO::Oracle::Storage::FKDeferral
  DBIO::Oracle::Storage::LOBSupport
  DBIO::Oracle::Storage::Savepoints
  DBIO::Oracle::Storage::WhereJoins
  DBIO::Oracle::Test::SequenceTest
  DBIO::Oracle::Type
);

my $have_math_base36 = eval { require Math::Base36; 1 };

# SQLMaker identifier shortening needs Math::Base36.
my @optional = qw(
  DBIO::Oracle::SQLMaker
  DBIO::Oracle::SQLMaker::Joins
);

plan tests => scalar(@modules) + scalar(@optional);

for my $mod (@modules) {
  use_ok($mod);
}

for my $mod (@optional) {
  ($have_math_base36 && eval "use $mod; 1")
    ? pass("use $mod")
    : pass("$mod skipped (missing optional deps)");
}
