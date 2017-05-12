#!/usr/bin/env perl

use warnings;
use strict;

use Data::Dumper;
use Carp;

for my $a (@ARGV) {
    print $a, "\n";
    if(-f $a) {
        open my $afh, '<', $a or confess "Can't open filehandle: $!";
        while(<$afh>) {
            print;
        }
        $afh->close;
    }
}
