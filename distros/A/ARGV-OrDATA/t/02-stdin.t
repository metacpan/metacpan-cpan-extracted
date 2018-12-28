#!/usr/bin/perl
use warnings;
use strict;

use FindBin;

my $PIPE;
if ('MSWin32' eq $^O && $] < 5.022) {
    open $PIPE, '|-', "$^X $FindBin::Bin/pipe.pl" or die $!;
} else {
    open $PIPE, '|-', $^X, "$FindBin::Bin/pipe.pl" or die $!;
}

print {$PIPE} << '__PIPE__';
pipe 1
pipe 2
__PIPE__
close $PIPE;
