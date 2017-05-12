#/usr/bin/perl

use strict;
use warnings;

if ($^O eq 'MSWin32') {

    for my $fn (qw(Makefile)) {

        open my $in, '<', $fn or die "unable to open $fn: $!";
        open my $out, '>', "$fn.new" or die "unable to open $fn.new: $!";

        while (<$in>) {
            s/install-data-hook(?!:)//;
            print $out $_;
        }

        close $in; close $out;
        rename $fn, "$fn.bak" or die $!;
        rename "$fn.new", $fn or die $!;
    }
}
