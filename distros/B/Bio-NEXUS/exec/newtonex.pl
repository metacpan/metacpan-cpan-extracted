#!/usr/bin/perl -w
use strict;
use Bio::NEXUS;
use Data::Dumper;
$Data::Dumper::Maxdepth = 3;

my $outfile = shift @ARGV;
my $newick = join(' ', "TREE", @ARGV);

my $nexus = {};
bless ($nexus, 'Bio::NEXUS');

my $TreesBlock = $nexus->create_block("trees", $newick);
$nexus->add_block($TreesBlock);

my $taxablock = new Bio::NEXUS::TaxaBlock('taxa',);
$taxablock->set_taxlabels($TreesBlock->get_taxlabels());
$nexus->set_blocks([$taxablock, @{$nexus->get_blocks()}]);

$nexus->write($outfile);


END;

# Execute at the command-line as follows:
# newtonex.pl new-nexus-file.nex "TreeName=NewickTree"
#
# Ex:
# ./newtonex.pl tmp.nex "Tree1=((((((A1122:1.000,FV1:1.000):0.977,E168695B:1.000):0.951,E168764B:1.000):0.910,CO92:1.000):0.905,Kenya:1.000):0.872,KIM:1.000):0.727;"
