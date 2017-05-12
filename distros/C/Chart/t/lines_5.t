#!/usr/bin/perl -w

use Chart::Lines;
print "1..1\n";

$g = Chart::Lines->new( 600, 300 );

@x_values = ();
@y_values = ();
for ( $i = 0 ; $i <= 16 ; $i += 0.05 )
{
    $j  = sin($i);
    $j2 = cos($i);
    push( @x_values,  $i );
    push( @y_values,  $j );
    push( @y2_values, $j2 );
}

$g->add_dataset(@x_values);
$g->add_dataset(@y_values);
$g->add_dataset(@y2_values);

%hash = (
    'title'              => 'The trigonometric functions sinus and cosinus',
    'grid_lines'         => 'true',
    'legend'             => 'left',
    'xy_plot'            => 'true',
    'skip_x_ticks'       => 20,
    'legend_labels'      => [ 'y = sin x', 'y = cos x' ],
    'precision'          => 2,
    'integer_ticks_only' => 'true',

    #'custom_x_ticks' => [0,3],
    'colors' => {
        'title'    => 'plum',
        'dataset0' => 'mauve',
    },
    'f_x_tick' => \&formatter,
);

$g->set(%hash);

$g->png("samples/lines_5.png");

sub formatter
{
    my $d = shift;
    $d = sprintf "%1.2f", $d;
    if ( $d =~ /^0.00/ ) { return 0 }
    return $d;
}
print "ok 1\n";

exit(0);
