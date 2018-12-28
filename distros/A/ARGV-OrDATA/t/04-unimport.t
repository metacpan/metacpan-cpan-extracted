#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 4;

use FindBin;

use ARGV::OrDATA;

SKIP: {
    skip "Can't run the test when stdin is not the terminal", 4
        unless -t;

    my $file = "$FindBin::Bin/input.txt";

    is scalar <>, "data 1\n", 'read line 1 from data';

    @ARGV = $file;
    is scalar <>, "data 2\n", 'changes to @ARGV ignored';

    'ARGV::OrDATA'->unimport;
    @ARGV = $file;
    is scalar <>, "file 1\n", 'unimport works';

    'ARGV::OrDATA'->import;
    is scalar <>, "data 3\n", 'switching back to data';
}

__DATA__
data 1
data 2
data 3
