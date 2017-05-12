#!/usr/bin/perl -w
# Arlin Stoltzfus, 8 Dec 2006
use strict;
use warnings; 

# remove the 'skip_all' line and uncomment the following line
#use Test::More 'no_plan';
use Test::More skip_all => "The notes block implementation is not complete";

use Bio::NEXUS;
# use Data::Dumper;

#############################################################################
# 
# This file tests the implementation of NOTES block commands following 
# the published NEXUS format standard of Swofford, et al., 1997
#
#############################################################################
#
# This test has one or more associated input files:
#
#      t/data/compliant/02_notes-text.nex
#
# BEGIN NOTES;
# 	text taxon=(1-3) text='these taxa from the far north';
# 	text taxon=5 character=2 text='4 specimens observed';
# 	text taxon=Pan text='This genus lives in Africa';
# 	text character=2 text='Perhaps this character should be deleted';
# 	text character=1 state=0 text='This state is hard to detect';
# END;
#
#############################################################################

my ($nexus, $block, @result);
my @notes = (
	'these taxa from the far north',
	'4 specimens observed',
	'This genus lives in Africa',
	'Perhaps this character should be deleted',
	'This state is hard to detect' 
);

# Read in the test input
$nexus = new Bio::NEXUS("t/data/compliant/02_notes-text.nex");
$block = $nexus->get_block("notes");

# here is what we want in our interface: 
# set_note( taxa => , char => , states => )
# get_notes( taxa => all|any|<list>, char => all|any|<list>, states => all|any|<list> ); 
#    e.g., get_notes( taxon => 'Pan', char => any, states => all ) 
#         get notes for Pan, including any character-specific note not restricted by state
#    e.g., get_notes( taxa => 'Pan', char => all, states => all ) 
#         get notes for Pan, top-level only, excluding any character-specific or state-specific note
# search_notes( pattern => /regex/ )

# Check if it matches the expected value
# get the uniq note for char 2
@result = @{ $block->get_notes( taxa  => 'all', char => 2 ) }; 
ok($result[1] eq $notes[4], 'return unique note for char');

# get the taxon-level note for taxon 1, assigned originally to the set 1-3
@result = @{ $block->get_notes( taxa => '1', char => 'all' ) }; 
ok($result[1] eq $notes[1], 'return note for one taxon from set');

# get the taxon-level note that applies to 3 taxa
@result = @{ $block->get_notes( taxa => ('1','2','3'), char => 'all' ) }; 
ok($result[1] eq $notes[1], 'return note for three taxa from set');

# 
@result = @{ $block->get_notes( taxa => 'Pan', char => 'all') }; 
set_ok(@result, @notes[1,3], 'return two notes for taxon');

@result = @{ $block->get_notes( taxa => ('1','2','3'), char => 'all' ) }; 
ok($result[1] eq 'these taxa from the far north', 'return note for three taxa from set');



# print Dumper $notes;


