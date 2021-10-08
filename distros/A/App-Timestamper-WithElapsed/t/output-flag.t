#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

use Path::Tiny qw/ path tempdir tempfile cwd /;

my $dir = tempdir();

my $fh = $dir->child("out.txt");

{
    system(
        qq#$^X -I lib bin/timestamper-with-elapsed -o "$fh" < t/data/nums.txt#);

    my @lines = $fh->lines_utf8();

    # TEST
    like( shift(@lines), qr#\A[0-9\.]+\tone#ms, "first line", );

    # TEST
    like( shift(@lines), qr#\A[0-9\.]+\ttwo#ms, "2nd line", );
}
