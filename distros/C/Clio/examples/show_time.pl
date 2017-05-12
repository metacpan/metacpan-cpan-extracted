#!/usr/bin/env perl 

use strict;
use warnings;

$|=1;

while ( 1 ) {
    my $t = localtime;
    print "$t\n";
    sleep 1;
}


