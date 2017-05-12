use Chart::Pareto;

print "1..1\n";

$g = Chart::Pareto->new( 500, 400 );
$g->add_dataset(
    '1st week',
    '2nd week',
    '3rd week',
    '4th week',
    '5th week',
    '6th week',
    '7th week',
    '8th week',
    '9th week',
    '10th week'
);
$g->add_dataset( 37, 15, 9, 4, 3.5, 2.1, 1.2, 1.5, 6.2, 16 );

%hash = (
    'colors' => {
        'dataset0' => 'mauve',
        'dataset1' => 'light_blue',
        'title'    => 'orange',
    },
    'title'              => 'Visitors at the Picasso Exhibition',
    'integer_ticks_only' => 'true',
    'skip_int_ticks'     => 5,
    'grey_background'    => 'false',
    'max_val'            => 100,
    'y_label'            => 'Visitors in Thousands',
    'x_ticks'            => 'vertical',
    'spaced_bars'        => 'true',
    'legend'             => 'none',
);

$g->set(%hash);
$g->png("samples/pareto_2.png");

print "ok 1\n";

exit(0);

