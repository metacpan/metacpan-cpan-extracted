#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 3;

use FindBin;
use lib $FindBin::Bin;

use My;

BEGIN {
    open *STDIN, '<&', IO::Pty->new
        if ! -t && eval { require IO::Pty };
}

use ARGV::OrDATA qw{ My };

SKIP: {
    skip "Can't run the test when stdin is not the terminal", 3
        unless -t;

    is $_, "package $.\n", "Read line $. from package" while <>;

    ok eof, 'end of package';
}

__DATA__
data 1
data 2

