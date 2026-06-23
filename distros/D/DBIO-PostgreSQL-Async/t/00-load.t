use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::PostgreSQL::Async
  DBIO::PostgreSQL::Async::ConnectInfo
  DBIO::PostgreSQL::Async::Pool
  DBIO::PostgreSQL::Async::Storage
  DBIO::PostgreSQL::Async::TransactionContext
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
