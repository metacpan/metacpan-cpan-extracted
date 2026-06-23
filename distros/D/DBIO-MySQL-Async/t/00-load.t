use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MySQL::Async
  DBIO::MySQL::Async::Storage
  DBIO::MySQL::Async::Pool
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}