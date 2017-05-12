use strict;
use warnings;

use Test::More tests => 15;
use Test::Builder;

use B::Size2;
use B::Size2::Terse;

sub f { 'dummy' }

foreach my $pkg (qw(main B::Size2 B::Size2::Terse Test::More Test::Builder)) {
    my($subs, $opcount, $opsize) = B::Size2::Terse::package_size($pkg);
    is ref($subs), 'HASH', $pkg;
    cmp_ok $opcount, ">", 0;
    cmp_ok $opcount, ">", 0;
}

