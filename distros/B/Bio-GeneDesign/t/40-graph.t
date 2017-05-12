#! /usr/bin/perl -T

use Test::More;
use Bio::GeneDesign;
use Bio::Seq;
use Digest::MD5 qw(md5_hex);

use strict;
use warnings;

eval {require GD::Graph::lines};

if($@)
{
    plan skip_all => 'GD::Graph::lines not installed';
}
else
{
    plan tests => 1;
}

my $GD = Bio::GeneDesign->new();
$GD->set_organism(-organism_name => "yeast",
                  -table_path => "codon_tables/Standard.ct",
                  -rscu_path => "codon_tables/Saccharomyces_cerevisiae.rscu");


my $tCT = $GD->codontable;
my $tRSCU = $GD->rscutable;

my $orf = "ATGGACAGATCTTGGAAGCAGAAGCTGAACCGCGACACCGTGAAGCTGACCGAGGTGATGACCTGGA";
$orf .= "GAAGACCCGCCGCTAAATGGTTTTATACTTTAATTAATGCTAATTATTTGCCACCATGCCCACCCGACC";
$orf .= "ACCAAGATCACCGGCAGCAACAACTACCTGAGCCTGATCAGCCTGAACATCAACGGCCTGAACAGCCCC";
$orf .= "ATCAAGCGGCACCGCCTGACCGACTGGCTGCACAAGCAGGACCCCACCTTCTGTTGCCTCCAGGAGACC";
$orf .= "CACCTGCGCGAGAAGGACCGGCACTACCTGCGGGTGAAGGGCTGGAAGACCATCTTTCAGGCCAACGGC";
$orf .= "CTGAAGAAGCAGGCTGGCGTGGCCATCCTGATCAGCGACAAGATCGACTTCCAGCCCAAGGTGATCAAG";
$orf .= "AAGGACAAGGAGGGCCACTTCATCCTGATCAAGGGCAAGATCCTGCAGGAGGAGCTGAGCATTCTGAAC";
$orf .= "ATCTACGCCCCCAACGCCCGCGCCGCCACCTTCATCAAGGACACCCTCGTGAAGCTGAAGGCCCACATC";
$orf .= "GCTCCCCACACCATCATCGTCGGCGACCTGAACACCCCCCTGAGCAG";
my $seqobj = Bio::Seq->new( -seq => $orf, -id => "torf");

my $tbuffer = q{};
my ($graph, $tformat) = $GD->make_graph(-sequences => [$seqobj],
                                         -window    => 10);
open   (my $TFH, '>', \$tbuffer) or die "can't create test filehandle, $!";
binmode $TFH;
print   $TFH $graph;
close $TFH;
open   (my $UFH, '<', \$tbuffer) or die "can't read test filehandle, $!";
my $tgraph = do {local $/; <$UFH>};
close $UFH;
my $tdigest = md5_hex($tgraph);

open   (my $OUT, '>', "t/testr_GRV_yeast.gif") or die "can't write test filehandle, $!";
binmode $OUT;
print   $OUT $graph;
close $OUT;

open (my $IMG, '<', "t/testr_GRV_yeast.gif") or die "can't parse rgraph file, $!";
binmode $IMG;
my $rgraph = do {local $/; <$IMG>};
close   $IMG;
my $rdigest = md5_hex($rgraph);
is ($tdigest, $rdigest, "codon juggle most different sequence");



