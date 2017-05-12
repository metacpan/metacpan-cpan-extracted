# Dummy RRDs lib for testing
package RRDs;

use warnings;
use strict;
require Exporter;
our @EXPORT = qw(error graph);

my $simulate_graph_generation;
my $error;
sub error {
	if (@_) { $error = shift }
	else { $error }
}

my $graph_input;
sub graph { 
	$graph_input = [@_]; 
	if ($simulate_graph_generation) { 
		open F, ">", $_[0]; 
		print F "stuff"; 
		close F 
	} 
}
sub graph_input { $graph_input };

sub simulate_graph_generation { shift; $simulate_graph_generation = shift };

1;
