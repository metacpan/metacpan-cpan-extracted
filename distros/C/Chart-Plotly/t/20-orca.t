#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Path::Tiny;
use Test::More;
use Test::File::ShareDir -share => { -dist => { 'Chart-Plotly' => 'share' } };

use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Scatter;

BEGIN {
    use_ok('Chart::Plotly::Image::Orca');
}

SKIP: {
    my $has_orca = Chart::Plotly::Image::Orca::_check_alien();
    skip( "Have not Alien::Plotly::Orca", 2 ) unless $has_orca;

    diag("Found Alien::Plotly::Orca");
    ok( Chart::Plotly::Image::Orca::orca_available(), "orca_available()" );
    like( Chart::Plotly::Image::Orca::orca_version(), qr/^\d+/, "orca_version()" );

    # try create an image
    my $x       = [ 1 .. 15 ];
    my $y       = [ map { rand 10 } @$x ];
    my $scatter = Chart::Plotly::Trace::Scatter->new( x => $x, y => $y );
    my $plot    = Chart::Plotly::Plot->new();
    $plot->add_trace($scatter);

    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.png' );
    Chart::Plotly::Image::Orca::orca( plot => $plot, file => $tempfile );
    my $size = ( stat($tempfile) )[7];
    ok( $size > 0, 'orca()' );
}

done_testing;
