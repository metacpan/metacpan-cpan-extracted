#!/usr/bin/env perl

######################################################
# 
# $Id: command_unknown_exception.t,v 1.2 2012/02/07 22:22:00 astoltzfus Exp $
#
use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use Bio::NEXUS;
use Bio::NEXUS::Util::Logger;

my $logger = Bio::NEXUS::Util::Logger->new( '-level' => 0 );

##############################################
#
#	Testing exception-generation when parsing unknown commands 
#
##############################################

print "\n--- Testing if exception is thrown on parsing unknown command ---\n";

#
# first we define some strings to use in constructing test files 
# 
my $taxa_block = "
#NEXUS
BEGIN TAXA;
	DIMENSIONS NTAX=3;
	TAXLABELS
		a b c;
END;
";

my $rogue_command = "	ROGUECOMMAND arg1 arg2;\n"; 

my $char_block = "
BEGIN CHARACTERS;
	DIMENSIONS nchar=3;
	ROGUECOMMAND arg1 arg2;
	FORMAT datatype=standard gap=- missing=?;
	MATRIX
	a	000
	b	000
	c	010
	;
END;
"; 

my @other_block_names = ( 
	"CODONS",  # this one isn't implemented yet
	"NOTES",  # this one isn't implemented yet
	"ASSUMPTIONS", 
	"DISTANCES", 
	"SETS", 
	"TREES",
	"UNALIGNED"
); 

my $other_block_text = "\nBEGIN OTHER_BLOCK;\n" . $rogue_command . "END;\n"; 

#
#
# first we test a file with just a TAXA block with a rogue command
#
my $nexus_file1 = $taxa_block; 
$nexus_file1 =~ s/END;/$rogue_command END;\n/; 
my $nex_obj1 = new Bio::NEXUS();
eval { 
	$nex_obj1->read( { 'format' => 'string', 'param' => $nexus_file1 } );
};
like($@, qr/UnknownMethod/, 'Unknown command in TAXA block generates error');

#
#
# now we test a file with TAXA and CHARACTERS blocks 
#
my $nexus_file2 = $char_block; 
$nexus_file2 = $taxa_block . $nexus_file2; 
my $nex_obj2 = new Bio::NEXUS();
eval { 
	$nex_obj2->read( { 'format' => 'string', 'param' => $nexus_file2 } );
};
like($@, qr/UnknownMethod/, 'Unknown command in CHARACTERS block generates error');

#
#
# now we test a file with just a DATA block 
#
my $nexus_file3 = "#NEXUS" . $char_block; 
$nexus_file3 =~ s/CHARACTERS/DATA/;

my $nex_obj3 = new Bio::NEXUS();
eval { 
	$nex_obj3->read( { 'format' => 'string', 'param' => $nexus_file3 } );
};
like($@, qr/UnknownMethod/, 'Unknown command in DATA block generates error');

#
#
# finally we test all the other block parsers to see if they throw an exception
#
my $other_nex_obj = new Bio::NEXUS(); 
foreach my $blockname (@other_block_names) { 
	my $block_text = $other_block_text; 
	$block_text =~ s/OTHER_BLOCK/$blockname/; 
	my $nexus_file4 = $taxa_block . $block_text; 
	TODO: { 
		local $TODO = "this block ($blockname) not implemented" if ( $blockname eq "CODONS" | $blockname eq "NOTES" ); 
		
		eval { 
			$other_nex_obj->read( { 'format' => 'string', 'param' => $nexus_file4 } );
		};
	#	print $@; 
		like($@, qr/UnknownMethod/, "Unknown command in $blockname block generates error");
	}
};
exit; 
# end of file 