#!perl

use 5.006;
use strict;
use warnings;

my $min = 10;
my $max = 14;

use Test::More 0.88 tests => 10;
use Crypt::GeneratePassword qw/ chars /;

for (1 .. 10) {
    my $word = chars($min, $max);
    ok(length($word) >= $min && length($word) <= $max,
       "chars($min,$max) should generate a password between $min and $max chars");
}

