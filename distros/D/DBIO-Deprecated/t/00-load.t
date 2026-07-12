use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::Deprecated
);

plan tests => scalar @modules;

for my $mod (@modules) {
  use_ok($mod);
}
