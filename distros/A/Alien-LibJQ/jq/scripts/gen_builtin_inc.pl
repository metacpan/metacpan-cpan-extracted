#!/usr/bin/perl
use strict;
use warnings;

sub main {
    open my $input, '<', $ARGV[0] or die "cannot open file to read: $!";
    while (<$input>) {
        s/\\/\\\\/g;
        s/"/\\"/g;
        s/^/"/;
        s/$/\\n"/;
        print $_;
    }
}

&main;