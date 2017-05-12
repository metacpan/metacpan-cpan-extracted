use strict;
use warnings;

use Test::More tests => 4;

use Math::BigInt;
use Math::BigFloat;

use B::Size2;
use B::Size2::Terse;

foreach my $pkg (qw(Math::BigInt Math::BigFloat)) {
    my($subs, $opcount, $opsize) = B::Size2::Terse::package_size($pkg);
    cmp_ok $opcount, ">", 0, "$pkg opcount";
    cmp_ok $opsize, ">", 0, "$pkg opsize";
}
