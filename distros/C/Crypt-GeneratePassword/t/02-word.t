#!perl

use 5.006;
use strict;
use warnings;

my $min = 8;
my $max = 12;

use Test::More 0.88 tests => 10;
use Crypt::GeneratePassword qw/ word /;

for (1 .. 10) {
    my $word = word($min, $max);
    ok(length($word) >= $min && length($word) <= $max,
       "word($min,$max) should generate a password between $min and $max chars");
}
