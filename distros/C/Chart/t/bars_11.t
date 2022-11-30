#!/usr/bin/perl -w

BEGIN { unshift @INC, 'lib', '../lib'}
use Chart::Bars;
use strict;
use POSIX;
use File::Temp 0.19;
my $samples = File::Temp->newdir();

print "1..1\n";

my $file = File::Spec->catfile( File::Spec->curdir, 't', 'data', "in.tsv" );

my $g = Chart::Bars->new( 600, 400 );
$g->add_datafile( $file );

$g->set(
    colors          => { dataset0 => [ 25, 220, 147 ], },
    graph_border    => 0,
    grey_background => 'false',
    grid_lines      => 'true',
    include_zero    => 'true',

    # integer_ticks_only => 'true',
    legend         => 'none',
    png_border     => 4,
    precision      => 1,
    skip_int_ticks => 1000,
    text_space     => 3,
    title          => "Tickets",
    title_font     => GD::Font->Giant,
    transparent    => 'false',
    x_ticks        => 'vertical',
    y_axes         => 'both',
    y_label        => '# Tickets',
    x_label        => 'Date',
);

$g->png("$samples/bars_11.png");
print "ok 1\n";

exit(0);

