#!/usr/bin/perl
use warnings;
use strict;

use FindBin;
use Test::More tests => 4;

my %SCRIPT = (0 => 'is_using.pl',
              1 => 'is_using_package.pl');
sub run {
    my ($argument, $package, $expected) = @_;
    my $PIPE;
    if ('MSWin32' eq $^O && $] < 5.022) {
        open $PIPE, '-|',
                "$^X $FindBin::Bin/$SCRIPT{$package}"
                . ($argument ? "$FindBin::Bin/input.txt" : "")
            or die $!;
    } else {
        open $PIPE, '-|', $^X, "$FindBin::Bin/$SCRIPT{$package}",
                               $argument ? "$FindBin::Bin/input.txt" : ()
            or die $!;
    }

    chomp( my $output = <$PIPE> );

    is $output, $expected, join ' ', $package ? 'package' : 'main',
                                     $argument ? 'argv' : 'data';
}

run(1, 0, '10');
run(0, 0, '01');
run(1, 1, '10');
run(0, 1, '01');
