# -*- perl -*-

# t/testmask2.t - check testmask 2

use Test::More tests=>9;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask2' );


my $tm = Testmask2->new();
my $tm2 = Testmask2->new('r');

isa_ok($tm,'Bitmask::Data');
isa_ok($tm,'Testmask2');
is($tm->length,2);
is($tm2->length,1);
is($tm->string,'101');
is($tm2->string,'100');
$tm2->reset();
is($tm2->string,'101');

