#!/usr/bin/perl -w
######################################################
# extract_taxset.pl - part of the Bio::NEXUS package
######################################################
# Author: arlin 
# $Id: extract_taxset.pl,v 1.1 2010/08/19 20:16:59 astoltzfus Exp $
################# POD Documentation ##################
=head1 NAME

extract_taxset.pl - create a new NEXUS from OTU set of another NEXUS file

=head1 DESCRIPTION

Given named taxset in input_file, extract only OTUs in taxset, including a pruned tree, character matrix, etc (may not be fully implemented for all blocks).

=head1 SYNOPSIS

extract_taxset.pl <input_file> <named_taxset_in_input> <output_file>
=cut

use strict;
use Bio::NEXUS;

my $file = shift;
my $setname = shift; 
my $outfile = shift; 

my $nexus = Bio::NEXUS->new($file);
my $setsblock = $nexus->get_block("sets"); 
my $names = $setsblock->get_taxset($setname);

my $new_nexus = $nexus->select_otus($names);
$new_nexus->write($outfile); 

exit;
