##
## Copyright (c) 2000-2025, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##

use strict;
use warnings;
use Crypt::Random qw(makerandom_itv);

print "1..6\n";
my $sample = 100;
my $i = 1;

for my $limit ( '10', '1000', '10000', '100000', '1000000000', '1000000000000' ) { 
    my $success = 1;
    for ( 1 .. $sample ) { 
        my $num = makerandom_itv ( Lower=>0, Upper=>$limit, Uniform => 1 );
        print "generated random in interval 0 - $limit -> $num\n";
        unless ($num >= 0 and $num < $limit) {
            $success = 0;
        }
    }
    print "ok ". $i++."\n" if $success;
}
