#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

use Path::Tiny qw/ path tempdir tempfile cwd /;

{
    my $dir = tempdir();

    my $fh = $dir->child("foo.m3u");
    my $in = cwd->child(qw( t data test1.xspf ));

    system( $^X, "-Ilib", "bin/xspf2m3u", "convert", "-o", "$fh", "$in" );

    # TEST
    is_deeply(
        scalar( $fh->slurp_utf8 ),
        scalar( cwd->child( "t", "data", "test1.m3u" )->slurp_utf8 ),
        "Good output",
    );
}
