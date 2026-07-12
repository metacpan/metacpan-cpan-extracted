use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::Async
  DBIO::Async::Pool
  DBIO::Async::Storage
  DBIO::Async::TransactionContext
);

plan tests => scalar(@modules) + 3;

for my $mod (@modules) {
  use_ok($mod);
}

isa_ok('DBIO::Async::Storage', 'DBIO::Storage::Async');
isa_ok('DBIO::Async::Pool', 'DBIO::Storage::PoolBase');
isa_ok('DBIO::Async', 'DBIO::Base');
