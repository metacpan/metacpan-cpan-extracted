#!/usr/bin/perl -w

use Chart::StackedBars;

print "1..1\n";

$g = Chart::StackedBars->new( 600, 400 );
$g->add_dataset( '2007-10-01', '2007-10-02', '2007-10-03', '2007-10-04', '2007-10-05' );

my @dataset        = ( 74, 78, 75, 83, 78 );
my @first_dataset  = ();
my @second_dataset = ();

foreach my $dat (@dataset)
{

    if ( $dat > 75 )
    {
        push( @first_dataset,  75 );
        push( @second_dataset, $dat - 75 );
    }
    else
    {
        push( @first_dataset,  $dat );
        push( @second_dataset, 0 );
    }
}
$g->add_dataset(@first_dataset);
$g->add_dataset(@second_dataset);

$g->set(
    'title'           => 'Stacked Bar Chart',
    'legend'          => 'none',
    'grey_background' => 'false',
    'min_val'         => 70,

);
$g->set(
    'colors' => {
        'dataset1' => [ 220, 20,  60 ],
        'dataset0' => [ 0,   255, 0 ],
    }
);

$g->png("samples/stackedbars_4.png");

print "ok 1\n";

exit(0);
