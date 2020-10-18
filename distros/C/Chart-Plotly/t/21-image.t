#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Path::Tiny;
use Test::More;
use Test::File::ShareDir -share => { -dist => { 'Chart-Plotly' => 'share' } };

use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Scatter;
use Chart::Plotly::Image;

BEGIN {
    use_ok( 'Chart::Plotly::Image', qw(save_image) );
}

my $x       = [ 1 .. 15 ];
my $y       = [ map { rand 10 } @$x ];
my $scatter = Chart::Plotly::Trace::Scatter->new( x => $x, y => $y );
my $plot    = Chart::Plotly::Plot->new();
$plot->add_trace($scatter);

my $has_kaleido = Chart::Plotly::Image::_has_kaleido();
my $has_orca    = Chart::Plotly::Image::_has_orca();

SKIP: {
    skip( "Have not Chart::Kaleido::Plotly", 1 ) unless $has_kaleido;

    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.png' );
    save_image( plot => $plot, file => $tempfile, engine => 'kaleido' );
    my $size = ( stat($tempfile) )[7];
    ok( $size > 0, 'save_image(engine => "kaleido", ...)' );
}

SKIP: {
    skip( "Have not Alien::Plotly::Orca", 1 ) unless $has_orca;

    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.png' );
    save_image( plot => $plot, file => $tempfile, engine => 'orca' );
    my $size = ( stat($tempfile) )[7];
    ok( $size > 0, 'save_image(engine => "orca", ...)' );
}

if ( $has_kaleido or $has_orca ) {
    my $tempfile = Path::Tiny->tempfile( SUFFIX => '.png' );
    save_image( plot => $plot, file => $tempfile, engine => 'auto' );
    my $size = ( stat($tempfile) )[7];
    ok( $size > 0, 'save_image(engine => "auto", ...)' );
}

done_testing;
