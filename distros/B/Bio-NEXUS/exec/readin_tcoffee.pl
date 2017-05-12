#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use Bio::NEXUS;

## This is a parser to convert a T-COFFEE ascii output file into a NEXUS 
## CharactersBlock object.  This was the first step in including residue scores
## in NEXUS files (currently, we only include column scores, in an
## AssumptionsBlock.


my ($filename) = @ARGV;  # Get the name of the T-Coffee output file

## Check to make sure that everything looks good ...
unless ($filename) { die "\n\tUsage: readin_tcoffee.pl <tcoffee_file.score_ascii>\n\n"; }
my $tcoff = slurp($filename);
if ($tcoff =~ /<html>/i) { die "\n\tError: Expecting ascii (simple text) version of T-COFFEE output rather than HTML\n\n"; }
if (! $tcoff =~ /^T-COFFEE/i) { die "\n\tError: File does not start with 'T-COFFEE'; does not appear to be a T-COFFEE file\n\n"; }

## Match some of the metadata at the beginning
my ($version, $date, $overall_score) = $tcoff =~ /^T-COFFEE, Version_([\d\.]+)\((.+?)\).*SCORE=(\d+)/si;

my (@otu_avg_scores) = $tcoff =~ /\n(\S+\s{3}:\s{1,3}\d+)(?=\n)/g;

my $scores = {
              'overall' => $overall_score,
              'column'  => [],
              'row'     => {},
              'otu'     => {}
};


for my $taxon_score (@otu_avg_scores) {
    my ($taxon, $score) = $taxon_score =~ /(\S+)\s+:\s+(\d+)/;
    $scores->{'row'}{$taxon} = $score;
}

my $metadata = {
                 'tcoffee_version' => $version,
                 'tcoffee_rundate' => $date,
                 'alignment_score' => $overall_score,
                 'row_scores'      => $scores->{'row'}
                };

## Get rid of the header
$tcoff =~ s/^.+:\s+\d+\n//s;

## Loop through the interleaved "blocks"
while ($tcoff =~ s/^(.*?\n)\n\n//s) {
    my $block = $1;
#        print Dumper $block;

    $block =~ s/Cons\s+([-\d]+)\s*$//i;
#    $scores->{'column'} .= $1;
    push(@{ $scores->{'column'} }, split(//, $1));

    while( $block =~ s/^(\S+)\s+(\S+)\n// ) {
        my $taxon = $1;
        my $seq = $2;
        $seq =~ s/[A-Z]/\?/g;
        push(@{ $scores->{'otu'}{$taxon} }, split(//, $seq));
    }
}

## Construct a NEXUS CharactersBlock object
my $charblock = new Bio::NEXUS::CharactersBlock();

$charblock->set_title('tcoffee');
#$charblock->add_link();
$charblock->set_format( { 'datatype' => 'standard', 'gap' => '-', 'missing' => '?' } );

my $otuset;
for my $taxon (keys %{ $scores->{'otu'} }) {
    push @$otuset, Bio::NEXUS::TaxUnit->new($taxon, $scores->{'otu'}{$taxon});
}
$charblock->get_otuset()->set_otus($otuset);

$charblock->set_taxlabels(keys %{ $scores->{'row'} });
$charblock->write();


## Subroutines ##

sub slurp {
    my ($filename) = @_;
    my $file_contents = do{ local(@ARGV, $/) = $filename; <>};
    return $file_contents;
}