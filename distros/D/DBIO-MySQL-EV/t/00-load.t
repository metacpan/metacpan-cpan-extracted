use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MySQL::EV
  DBIO::MySQL::EV::Storage
  DBIO::MySQL::EV::Pool
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}