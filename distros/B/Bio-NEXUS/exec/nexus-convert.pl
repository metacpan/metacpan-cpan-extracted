#! /usr/bin/perl -w

use strict;
use Data::Dumper;
use Bio::NEXUS;

my ($infile, $outfile) = @ARGV;
if (!$outfile) {$outfile = "test.nex";}
print "$infile\n";

my $nexus = new Bio::NEXUS($infile, 1);
#print $nexus->get_block('trees')->get_tree->get_rootnode->printall();exit;
#$nexus->write($outfile, 1);exit;

if (! $nexus->get_block("span")) {
    my $spanblock = new Bio::NEXUS::SpanBlock("span");
    $spanblock->set_title("\"metadata for this family\"");
    $spanblock->add_link('taxa', $nexus->get_name());
    $spanblock->set_command('spandex', {version=>'0.1'});
    my $taxa = $nexus->get_name();
    my @taxlabels = @{$nexus->get_block('taxa')->get_taxlabels()};
    my @data;
    foreach my $label (@taxlabels) {
	$label =~ /^(.+)_(.+)$/;
	push @data, [$label, $1, $2],;
    }
    $spanblock->{add} = {
	taxa => {
	    attributes => ['pfam_id'],
	    source => 'pfam',
	    data => [[$taxa, '000000']],
	},
	taxlabels => {
	    attributes => ['species', 'accession'],
	    source => 'GENBANK',
	    data => \@data,
	},
    };
    $spanblock->{method} = {
	alignment => {
	    program => 'clustalw',
	},
	phylogeny => {
	    program => 'MrBayes',
	    version => '2',
	},
    };
    $nexus->add_block($spanblock);
}

$nexus->write($outfile, 1);
