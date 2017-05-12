use Chart::PNGgraph::bars;
use GD::Graph::colour;

print STDERR "Processing sample 1-1\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
    [    1,    2,    5,    6,    3,  1.5,    1,     3,     4],
);

$my_graph = new Chart::PNGgraph::bars();

$my_graph->set( 
	x_label => 'X Label',
	y_label => 'Y label',
	title => 'A Simple Bar Chart',
	y_max_value => 8,
	y_tick_number => 8,
	y_label_skip => 2,
);

$my_graph->plot_to_png( "sample11.png", \@data );

exit;

