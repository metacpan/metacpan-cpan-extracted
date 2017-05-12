#!/usr/bin/perl

use Data::Xtab;
use GIFgraph::linespoints;
use CGI;
$query = new CGI;
print $query->header("image/gif");

my @data = ( ['A', 'FEB', 3.4],
             ['A', 'FEB', 1.3],
             ['A', 'MAR', 1.7],
             ['A', 'MAR', 2.8],
             ['A', 'APR', 1.3],
             ['B', 'FEB', 2.9],
             ['B', 'FEB', 1.6],
             ['B', 'MAR', 1.4],
             ['B', 'APR', 3.7],
             ['C', 'MAR', 2.3],
             ['C', 'MAR', 1.0],
             ['C', 'APR', 1.0] );
my @outputcols = ('FEB', 'MAR', 'APR');
my $xtab = new Data::Xtab(\@data, \@outputcols);
 
my @graph_data = $xtab->graph_data;

$my_graph = new GIFgraph::linespoints();

$my_graph->set( 'x_label' => 'Month',
                'y_label' => 'Sales (in thousands)',
                'title' => 'Monthly Sales By Sales Unit',
                'y_max_value' => 10,
                'y_tick_number' => 10,
                'y_label_skip' => 1 );

foreach (@graph_data) {
    my @frob = @$_;
}

pop @graph_data;
print $my_graph->plot( \@graph_data );

