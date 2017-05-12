use warnings;
use strict;

do "t/setup_pp.pl" or die $@ || $!;
do "t/ad_ii.t" or die $@ || $!;

1;
