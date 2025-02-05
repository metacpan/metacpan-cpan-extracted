##
##
##
## Copyright (c) 1999-2025, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##

use strict;
use warnings;
use Crypt::Random qw(makerandom makerandom_itv);

print "1..1\n";

my $r = makerandom ( Size => 512, Verbosity => 1, Strength => 0 );
my $y = makerandom ( Size => 512, Verbosity => 1, Strength => 0 );
print "$r, $y\n";
print $r == $y ? "not ok 1" : "ok 1";
print "\n";


