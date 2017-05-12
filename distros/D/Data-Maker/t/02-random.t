#!perl -w
use strict;
use warnings; 

use Test::More tests => 4;

BEGIN { use_ok('Data::Maker'); }

my @list = (1,2,3,4,5);
my $picked = seeded(sub { $list[rand @list] });

is(seeded(sub { Data::Maker->random(@list) }), $picked, "random from list");
is(seeded(sub { Data::Maker->random(\@list) }), $picked, "random from arrayref");

ok(Data::Maker->random([],[]), "treats two arrayrefs as individual list members");

sub seeded {
  my $code = shift;
  srand(42);
  return &$code;
}
