use Chart::PNGgraph::pie;

print STDERR "Processing sample 9-1\n";

@data = ( 
    ["1st","2nd","3rd","4th","5th","6th"],
    [    4,    2,    3,    4,    3,  3.5]
);

$my_graph = new Chart::PNGgraph::pie( 250, 200 );
#$my_graph = new Chart::PNGgraph::pie( );

$my_graph->set( 
	title => 'A Pie Chart',
	label => 'Label',
	axislabelclr => 'black',
	pie_height => 36,
);

$my_graph->plot_to_png( "sample91.png", \@data );

exit;

