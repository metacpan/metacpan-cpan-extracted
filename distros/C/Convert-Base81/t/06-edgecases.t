#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 9;

use Convert::Base81 qw(:pack);

my $b81str;
my $b3chars = "01-";
my $b9chars = "012345678";
my $b27chars = "0123456789abcdefghijklmnopq";

#
# Test the base 3 pack with strings that are short.
#
$b81str = b3_pack81($b3chars, q(1));
ok($b81str eq q(R), "1: Base81 string should be 'R', but is '$b81str'");

$b81str = b3_pack81($b3chars, q(11));
ok($b81str eq q(a), "2: Base81 string should be 'a', but is '$b81str'");

$b81str = b3_pack81($b3chars, q(110));
ok($b81str eq q(a), "3: Base81 string should be 'a', but is '$b81str'");

$b81str = b3_pack81($b3chars, q(011));
ok($b81str eq q(C), "4: Base81 string should be 'C', but is '$b81str'");

#
# Test the pack with a base3 string that is odd-numbered in length.
#
$b81str = b3_pack81($b3chars, q(1-10--011));
ok($b81str eq q(m?R), "5: Base81 string should be 'm?R', but is '$b81str'");


#
# Test the base 9 pack with a string that is short.
#
$b81str = b9_pack81($b9chars, q(4));
ok($b81str eq q(a), "6: Base81 string should be 'a', but is '$b81str'");

#
# Test the pack with a base9 string that is odd-numbered in length.
#
$b81str = b9_pack81($b9chars, q(53813));
ok($b81str eq q(m?R), "7: Base81 string should be 'm?R', but is '$b81str'");

#
# Test the base 27 pack with a string that is short.
#
$b81str = b27_pack81($b27chars, q(4));
ok($b81str eq q(C), "8: Base81 string should be 'C', but is '$b81str'");

$b81str = b27_pack81($b27chars, q(44));
ok($b81str eq q(Ca), "9: Base81 string should be 'Ca', but is '$b81str'");


