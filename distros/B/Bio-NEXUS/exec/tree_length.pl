#! /usr/bin/perl -w


use strict;

use lib '../lib';
use Bio::NEXUS;
use Data::Dumper;

my $file_1 = shift @ARGV;
if ($file_1) {
		#print "read $file, write, read again, compare object with original\n";
    my $nexus_1 = new Bio::NEXUS($file_1, 0);
	my $treesblock_1 = $nexus_1->get_block('trees');
	#print Dumper $treesblock_1;
	
# get trees, print out name and length for each
foreach my $tree (@{$treesblock_1->get_trees}) { 
	printf( "%s\t%s\n", $tree->get_name, $tree->get_tree_length ); 
	}
}

exit;
