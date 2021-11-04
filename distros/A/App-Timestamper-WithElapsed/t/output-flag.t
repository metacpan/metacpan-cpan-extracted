#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;

use File::Spec ();
use Path::Tiny qw/ path tempdir tempfile cwd /;

my $dir = tempdir();

my $fh = $dir->child("out.txt");

{
    # See https://github.com/shlomif/App-Timestamper/issues/1
    # for the need for $devnull .
    my $devnull = File::Spec->devnull();
    system(
qq#$^X -I lib bin/timestamper-with-elapsed -o "$fh" < t/data/nums.txt > $devnull#
    );

    my @lines = $fh->lines_utf8();

    # TEST
    like( shift(@lines), qr#\A[0-9\.]+\tone#ms, "first line", );

    # TEST
    like( shift(@lines), qr#\A[0-9\.]+\ttwo#ms, "2nd line", );
}
