#!perl

use 5.006;
use strict;
use warnings;

my $min = 10;
my $max = 14;

use Test::More 0.88 tests => 2;
use Crypt::GeneratePassword qw/ word3 /;

for (1 .. 2) {
    my $word = word3($min, $max);
    ok(length($word) >= $min && length($word) <= $max,
       "word3($min,$max) should generate a password between $min and $max chars");
}
