use 5.010;
use strict;
use warnings;

use Test::More tests => 12;
use Test::NoWarnings;

use Business::DPD;
my $dpd = Business::DPD->new;
my ($map, $char) = $dpd->iso7064_mod37_36_checksum_map;

is($map->{0},'0','0->0');
is($map->{8},'8','8->8');
is($map->{D},'13','D->13');
is($map->{K},'20','D->20');
is($map->{M},'22','D->22');
is($map->{L},'21','D->21');
is($map->{'*'},'36','*->36');

is($map->{x},undef,'no lowercase');

is($char->[0],0,'char 0');
is($char->[8],8,'char 8');
is($char->[13],'D','char D');

