#!/usr/bin/perl -w

use Chart::Mountain;
use File::Spec;

print "1..2\n";

my $a = ( 10**(-6) );

my @data = (
    [ "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th" ],
    [ ( 3 * $a ), ( 7 * $a ), ( 8 * $a ), ( 2 * $a ), ( 4 * $a ),   ( 8.5 * $a ), ( 2 * $a ), ( 5 * $a ), ( 9 * $a ) ],
    [ ( 4 * $a ), ( 2 * $a ), ( 5 * $a ), ( 6 * $a ), ( 3 * $a ),   ( 2.5 * $a ), ( 3 * $a ), ( 3 * $a ), ( 4 * $a ) ],
    [ ( 7 * $a ), ( 3 * $a ), ( 2 * $a ), ( 8 * $a ), ( 8.5 * $a ), ( 2 * $a ),   ( 9 * $a ), ( 4 * $a ), ( 5 * $a ) ],
);

my @hex_colors = qw(0099FF 00CC00 FFCC33 FF0099 3333FF);
my @colors     = map {
    [ map { hex($_) } unpack( "a2 a2 a2", $_ ) ]
} @hex_colors;

my @patterns = ();
foreach ( 1 .. @data - 1 )
{
    open( PNG, '<' . File::Spec->catfile( File::Spec->curdir, 'patterns', "PATTERN$_.PNG" ) ) || die "Can't load pattern $_";
    push( @patterns, GD::Image->newFromPng( \*PNG ) );
    close(PNG);
}

my @opts = (
    {},
    {
        'x_label'    => 'X Label',
        'y_label'    => 'Y label',
        'title'      => 'Mountain Chart',
        'grid_lines' => 'true',
        'colors'     => { map { ( "dataset$_" => $colors[$_] ) } 0 .. @colors - 1 },
        'precision'  => 6,

        #'integer_ticks_only'      => 'true',
    },
    {
        'x_label'    => 'X Label',
        'y_label'    => 'Y label',
        'title'      => 'Mountain Chart with Patterns',
        'grid_lines' => 'true',
        'colors'     => { map { ( "dataset$_" => $colors[$_] ) } 0 .. @colors - 1 },
        'patterns'   => \@patterns,
        'precision'  => 5,
    },
);

foreach my $i ( 1 .. @opts - 1 )
{
    my $newpath = File::Spec->catfile( File::Spec->curdir, 'samples', "mountain_2-$i.png" );
    my $opts    = $opts[$i];
    my $g       = new Chart::Mountain();
    $g->set(%$opts);
    my $Image = $g->png( $newpath, \@data );
    print "ok $i\n";
}

exit(0);

