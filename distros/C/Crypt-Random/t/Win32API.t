##
##
##
## Copyright (c) 1999-2025, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##

use strict;
use warnings;
use Test2::V0 ;
use Crypt::Random qw(makerandom makerandom_itv);

SKIP: {
    skip ("Windows only tests", 1) if $^O !~ /Win32/;
    my $r = makerandom ( Provider => 'Win32API', Size => 512, Verbosity => 1, Strength => 1 );
    my $y = makerandom ( Provider => 'Win32API', Size => 512, Verbosity => 1, Strength => 1 );
    print "$r, $y\n";
    ok($r ne $y, "Random numbers are different");
}
done_testing;
