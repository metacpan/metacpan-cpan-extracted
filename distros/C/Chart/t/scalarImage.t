#!/usr/bin/perl -w

use Chart::Lines;
use strict;

# bytewise comparision of scalar
sub imgCompare
{
    my $scalarImage = shift;
    my $fileName    = shift;
    my $result      = 0;       # assume error

    # do a bytewise compare
    if ( !open( FH, $fileName ) ) { return $result; }

    my $idx        = 0;
    my $fileChar   = '';
    my $scalarChar = '';
    my $bEqual     = 1;
    while ( read FH, $fileChar, 1, $idx )
    {
        my $length = length $fileChar;
        if ( $length > 1 )
        {
            my $c = substr $scalarImage, $length - 1, 1;
            $fileChar = $c;
        }
        $scalarChar = substr $scalarImage, $idx, 1;
        if ( $scalarChar ne $fileChar )
        {
            $bEqual = 0;
            last;
        }
        $idx++, $fileChar = '';
    }
    close FH;
    $result = $bEqual;
    return $result;
}

my $g;

print "1..1\n";

$g = Chart::Lines->new( 600, 400 );
$g->add_dataset( 'foo', 'bar', 'whee', 'ding', 'bat',    'bit' );
$g->add_dataset( 3.2,   4.34,  9.456,  10.459, 11.24234, 14.0234 );
$g->add_dataset( -1.3,  8.4,   5.34,   3.234,  4.33,     13.09 );
$g->add_dataset( 5,     7,     2,      10,     12,       2.3445 );

$g->set( 'title'     => 'LINES' );
$g->set( 'sub_title' => 'Lines Chart' );
$g->set(
    'colors' => {
        'y_label'      => [ 0,   0,   255 ],
        y_label2       => [ 0,   255, 0 ],
        'y_grid_lines' => [ 127, 127, 0 ],
        'dataset0'     => [ 127, 0,   0 ],
        'dataset1'     => [ 0,   127, 0 ],
        'dataset2'     => [ 0,   0,   127 ]
    }
);
$g->set( 'y_label'      => 'y label 1' );
$g->set( 'y_label2'     => 'y label 2' );
$g->set( 'y_grid_lines' => 'true' );
$g->set( 'legend'       => 'bottom' );

my $FileName = "samples/scalarImage.png";
$g->png($FileName);

my $dataref     = $g->get_data();
my $scalarimage = $g->scalar_png($dataref);

if ( imgCompare( $scalarimage, $FileName ) )
{
    unlink $FileName;
    print "ok 1\n";
    exit(0);
}
unlink $FileName;
print "Error 1\n";
exit(1);
