# -*- perl -*-

# t/long.t - check for max integer bitmasks

use Config;
use Test::More tests => 8;
use Test::NoWarnings;

use lib qw(t/lib);

use strict;
use warnings;

use_ok('Testmask7');

my $tm1 = Testmask7->new('value20');
my $tm2 = Testmask7->new('value64');
my $tm3 = Testmask7->new()->set_all;

if ($Config{use64bitint}) {
    isnt(ref $tm1->integer,'Math::BigInt'); 
    isnt(ref $tm2->integer,'Math::BigInt');
    isnt(ref $tm3->integer,'Math::BigInt');
} else {
    isa_ok($tm1->integer,'Math::BigInt');
    isa_ok($tm2->integer,'Math::BigInt');
    isa_ok($tm3->integer,'Math::BigInt');
}

my $tm1b = Testmask7->new($tm1->integer);
my $tm2b = Testmask7->new($tm2->integer);
my $tm3b = Testmask7->new($tm3->integer);

is($tm1->string,$tm1b->string);
is($tm2->string,$tm2b->string);
is($tm3->string,$tm3b->string);