#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 3;

use FindBin;

open *STDIN, '<&', IO::Pty->new
    if ! -t && eval { require IO::Pty };

SKIP: {
    skip "Can't run the test when stdin is not the terminal", 3
        unless -t;

    my $PIPE;
    if ('MSWin32' eq $^O && $] < 5.022) {
        open $PIPE, '-|', "$^X $FindBin::Bin/script.pl" or die $!;
    } else {
        open $PIPE, '-|', $^X, "$FindBin::Bin/script.pl" or die $!;
    }

    is $_, "data $.\n", "Read line $. from DATA" while <$PIPE>;

    ok eof $PIPE, 'closed DATA';
}
