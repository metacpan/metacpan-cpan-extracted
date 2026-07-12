use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::PostgreSQL::EV
  DBIO::PostgreSQL::EV::ConnectInfo
  DBIO::PostgreSQL::EV::Pool
  DBIO::PostgreSQL::EV::Storage
  DBIO::PostgreSQL::EV::TransactionContext
  DBIO::PostgreSQL::EV::TestHarness
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
