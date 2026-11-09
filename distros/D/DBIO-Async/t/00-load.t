use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::Async
  DBIO::Async::Future
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
# Pins the entry point's NEUTRAL base (karr k13): DBIO::Base carries no driver
# component's connection() hook, so loading this dist decides no storage_type
# -- the same base every entry point in the family uses. It does not pin a
# load_components('Async'); there is none. Rationale: lib/DBIO/Async.pm.
isa_ok('DBIO::Async', 'DBIO::Base');
