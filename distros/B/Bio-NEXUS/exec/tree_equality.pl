#! /usr/bin/perl -w

# two kinds of behavior depending on how its called: 
#
#   1.  If passed a file name, it does the read/write/re-read/compare test. 
#   2.  If not, it does a read test on all *.nex files in the working directory. 
#

use strict;

use lib '../lib';
use Bio::NEXUS;
use Data::Dumper;

my $file_1 = shift @ARGV;
my $file_2 = shift @ARGV;
if ($file_1 && $file_2) {
		#print "read $file, write, read again, compare object with original\n";
    my $nexus_1 = new Bio::NEXUS($file_1, 0);
    my $nexus_2 = new Bio::NEXUS($file_2, 0);
	my $treesblock_1 = $nexus_1->get_block('trees');
	my $treesblock_2 = $nexus_2->get_block('trees');
	#print Dumper $treesblock_1;
	#print Dumper $treesblock_2;
	
	print "new and improved equals: \n";
    if ($treesblock_1->_equals_test($treesblock_2)) { print "trees are equal\n"; }
   	else {print "==> ERROR, trees blocks are not the same\n"; }
	
	print "the original method: \n";
    if ($treesblock_1->equals($treesblock_2)) { print "trees are equal\n"; }
	else { print "==> ERROR, trees blocks are not the same\n"; }
}

exit;
