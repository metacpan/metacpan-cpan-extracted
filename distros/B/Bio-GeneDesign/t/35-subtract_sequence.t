#! /usr/bin/perl -T

use Test::More tests => 4;
use Test::Deep;

use Bio::GeneDesign;
use Bio::Seq;

use strict;
use warnings;

my $GD = Bio::GeneDesign->new();
$GD->set_organism(-organism_name => "yeast",
                  -table_path => "codon_tables/Standard.ct",
                  -rscu_path => "codon_tables/Saccharomyces_cerevisiae.rscu");

$GD->{conf} = 'blib/GeneDesign/';
# TESTING subtract_sequence sequence
if (1)
{
  my $mainseq = "GACAGATCT";
  my $seqobj = Bio::Seq->new( -seq => $mainseq, -id => "mainseq");

  my $loseseq = "CAGATCT";
  my $remobj = Bio::Seq->new( -seq => $loseseq, -id => "loseseq");

  my $trevorf = $GD->subtract_sequence(
    -sequence => $seqobj,
    -remove   => $remobj);

  my $rnewshort = "GATAGATCT";
  is ($trevorf->seq, $rnewshort, "substract sequence");
}

# TESTING subtract_sequence sequence
if (1)
{
  my $mainseq = "GACAGATCTA";
  my $seqobj = Bio::Seq->new( -seq => $mainseq, -id => "mainseq");

  my $loseseq = "CAGATCT";
  my $remobj = Bio::Seq->new( -seq => $loseseq, -id => "loseseq");

  my $trevorf = $GD->subtract_sequence(
    -sequence => $seqobj,
    -remove   => $remobj);

  my $rnewshort = "GATAGATCTA";
  is ($trevorf->seq, $rnewshort, "substract sequence non codon length");
}

# TESTING subtract_sequence sequence fail
if (1)
{
  my $mainseq = "TGG";
  my $seqobj = Bio::Seq->new( -seq => $mainseq, -id => "mainseq");

  my $loseseq = "TGG";
  my $remobj = Bio::Seq->new( -seq => $loseseq, -id => "loseseq");

  my $trevorf = $GD->subtract_sequence(
    -sequence => $seqobj,
    -remove   => $remobj);

  my $rnewshort = "TGG";
  is ($trevorf->seq, $rnewshort, "substract sequence fail");
}

# TESTING subtract_sequence enzyme
if (1)
{
  $GD->set_restriction_enzymes(-list_path => "enzymes/test");

  my $enz = $GD->enzyme_set->{BmgBI};

  my $mainseq = "GACACGTCT";
  my $seqobj = Bio::Seq->new( -seq => $mainseq, -id => "mainseq");

  my $trevorf = $GD->subtract_sequence(
    -sequence => $seqobj,
    -remove => $enz);

  my $rnewshort = "GACACATCT";
  is ($trevorf->seq, $rnewshort, "substract enzyme");
}
