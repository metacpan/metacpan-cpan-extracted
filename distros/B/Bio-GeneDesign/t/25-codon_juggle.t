#! /usr/bin/perl -T

use Test::More tests => 5;
use Test::Deep;

use Bio::GeneDesign;
use Bio::Seq;

use strict;
use warnings;

my $GD = Bio::GeneDesign->new();
$GD->set_organism(-organism_name => "yeast",
                  -table_path => "codon_tables/Standard.ct",
                  -rscu_path => "codon_tables/Saccharomyces_cerevisiae.rscu");

my $reps = 10000;

my $orf = 'ATGGACAGATCTTGGAAGCAGAAGCTGAACCGCGACACCGTGAAGCTGACCGAGGTGATGACCTGGAGAAGACCCGCCGCTAAATGGTTTTATACTTTAATTAATGCTAATTATTTGCCACCATGCCCACCCGACCACCAAGATCACCGGCAGCAACAACTACCTGAGCCTGATCAGCCTGAACATCAACGGCCTGAACAGCCCCATCAAGCGGCACCGCCTGACCGACTGGCTGCACAAGCAGGACCCCACCTTCTGTTGCCTCCAGGAGACCCACCTGCGCGAGAAGGACCGGCACTACCTGCGGGTGAAGGGCTGGAAGACCATCTTTCAGGCCAACGGCCTGAAGAAGCAGGCTGGCGTGGCCATCCTGATCAGCGACAAGATCGACTTCCAGCCCAAGGTGATCAAGAAGGACAAGGAGGGCCACTTCATCCTGATCAAGGGCAAGATCCTGCAGGAGGAGCTGAGCATTCTGAACATCTACGCCCCCAACGCCCGCGCCGCCACCTTCATCAAGGACACCCTCGTGAAGCTGAAGGCCCACATCGCTCCCCACACCATCATCGTCGGCGACCTGAACACCCCCCTGAGCAGTGA';
my $seqobj = Bio::Seq->new( -seq => $orf, -id => "torf");
my $shortseq = 'ATGGGGATCGACTTG';
my $shortobj = Bio::Seq->new( -seq => $shortseq, -id => "tshortseq");

# TESTING codon_juggle high algorithm
if (1)
{
  my $trevorf = $GD->codon_juggle(
    -sequence=> $seqobj,
    -algorithm => 'high');
  my $rrevorf = 'ATGGACAGATCTTGGAAGCAAAAGTTGAACAGAGACACCGTTAAGTTGACCGAAGTTATGACCTGGAGAAGACCAGCTGCTAAGTGGTTCTACACCTTGATCAACGCTAACTACTTGCCACCATGTCCACCAGACCACCAAGACCACAGACAACAACAATTGCCAGAACCAGACCAACCAGAACACCAAAGACCAGAACAACCACACCAAGCTGCTCCACCAGACAGATTGGCTGCTCAAGCTGGTCCACACTTGTTGTTGCCACCAGGTGACCCACCAGCTAGAGAAGGTCCAGCTTTGCCAGCTGGTGAAGGTTTGGAAGACCACTTGTCTGGTCAAAGACCAGAAGAAGCTGGTTGGAGAGGTCACCCAGACCAAAGACAAGACAGATTGCCAGCTCAAGGTGACCAAGAAGGTCAAGGTGGTCCATTGCACCCAGACCAAGGTCAAGACCCAGCTGGTGGTGCTGAACACTCTGAACACTTGAGACCACAAAGACCAAGAAGACACTTGCACCAAGGTCACCCAAGAGAAGCTGAAGGTCCACACAGATCTCCACACCACCACAGAAGAAGACCAGAACACCCACCAGAACAATAA';
  is ($trevorf->seq, $rrevorf, 'codon juggle high');
}

# TESTING codon_juggle most different sequence algorithm
if (1)
{
  my $trevorf = $GD->codon_juggle(
    -sequence=> $seqobj,
    -algorithm => 'most_different_sequence');
  my $rrevorf = 'ATGGATCGTAGCTGGAAACAAAAATTAAATAGGGATACGGTCAAATTAACGGAAGTCATGACGTGGCGTCGTCCGGCAGCAAAGTGGTTCTACACGCTTATAAACGCAAACTACCTTCCTCCTTGTCCTCCGGATCATCAGGACCATAGACAACAGCAGTTGCCGGAACCGGACCAACCGGAGCACCAGAGACCGGAGCAACCGCACCAGGCCGCCCCCCCGGATAGGTTAGCAGCCCAGGCCGGCCCGCATTTATTACTTCCGCCTGGCGATCCTCCGGCCAGGGAGGGCCCCGCCTTGCCGGCCGGGGAGGGCTTAGAGGATCACTTAAGTGGGCAGAGACCGGAGGAGGCCGGGTGGAGGGGGCACCCGGACCAAAGGCAGGACAGGTTACCTGCACAGGGGGACCAGGAGGGCCAGGGCGGCCCTTTACACCCGGACCAGGGCCAGGACCCGGCCGGCGGCGCAGAACACAGCGAGCACTTGAGGCCGCAGAGGCCCAGGAGGCATTTACACCAGGGCCATCCGAGGGAGGCAGAGGGGCCTCACAGGAGTCCTCATCACCACAGGAGAAGGCCGGAGCATCCGCCGGAACAATAG';
  is ($trevorf->seq, $rrevorf, 'codon juggle most different sequence');
}

# TESTING codon_juggle least different rscu algorithm
if (1)
{
  my $trevorf = $GD->codon_juggle(
    -sequence=> $seqobj,
    -algorithm => 'least_different_rscu');
  my $rrevorf = 'ATGGATAGATCCTGGAAGCAGAAGCTTAACAGGGATACTGTAAAGCTTACTGAGGTAATGACTTGGAGAAGACCGGCAGCTAAATGGTTTTATACCCTAATCAATGCTAATTATTTGCCACCATGCCCACCGGATCACCAAGACCACAGGCAGCAACAACTGCCCGAGCCCGACCAGCCCGAACATCAAAGGCCCGAACAGCCGCATCAAGCAGCGCCCCCCGATAGGCTTGCTGCGCAAGCGGGGCCGCACCTGCTTTTGCCCCCAGGGGATCCACCCGCAAGGGAAGGGCCCGCGCTGCCCGCAGGTGAAGGACTTGAAGATCATCTGAGTGGGCAAAGGCCCGAAGAAGCGGGGTGGAGGGGGCATCCCGACCAGAGGCAAGACAGGCTGCCAGCACAAGGTGACCAAGAAGGGCAAGGGGGACCACTGCATCCCGACCAAGGACAAGACCCCGCGGGGGGGGCTGAGCATTCCGAACATCTGAGGCCGCAAAGGCCCAGGAGGCACCTGCATCAAGGGCACCCCAGGGAAGCTGAAGGGCCACATAGGTCTCCACACCATCATAGGAGGAGGCCCGAACACCCGCCCGAGCAGTAG';
  is ($trevorf->seq, $rrevorf, 'codon juggle least different rscu');
}

# TESTING codon_juggle balanced algorithm
if (1)
{
  my $rhshref =
  {
    TTA => num(0.081, 0.021),  TTG => num(0.890, 0.021),  CTT => num(0.003, 0.021),  
    #CTC => num(0.000, 0.021),  
    CTA => num(0.025, 0.021),  CTG => num(0.003, 0.021),
    ATT => num(0.420, 0.021),  ATC => num(0.580, 0.021),  #ATA => num(0.000, 0),
    ATG => num(1.000, 0),
    GAT => num(0.350, 0.021),  GAC => num(0.650, 0.021),
    GGT => num(0.980, 0.021),  GGC => num(0.015, 0.021),  #GGA => num(0.000, 00),  
    GGG => num(0.005, 0.021),
  };
  my $thshref = {};
  for my $x (1..$reps)
  {
    my $torf = $GD->codon_juggle(
      -sequence => $shortobj,
      -algorithm => "balanced");
    my $offset = 0;
    my $tseq = $torf->seq;
    my $len = length($tseq);
    while ($offset < $len)
    {
      $thshref->{substr($tseq, $offset, 3)}++;
      $offset += 3;
    }
  }
  foreach my $key (keys %$thshref)
  {
    my $ratio = $thshref->{$key} / $reps || 0;
    $thshref->{$key} = sprintf("%.2f", $ratio);
  }
  cmp_deeply($thshref, $rhshref, "codon juggle balanced");
}

# TESTING codon_juggle random algorithm
if (1)
{
  my $rhshref =
  {
    ATA => num(0.33, 0.021), ATC => num(0.33, 0.021), ATG => num(1.00, 0.021),
    ATT => num(0.33, 0.021), CTA => num(0.17, 0.021), CTC => num(0.17, 0.021),
    CTG => num(0.17, 0.021), CTT => num(0.17, 0.021), GAC => num(0.50, 0.021),
    GAT => num(0.50, 0.021), GGA => num(0.25, 0.021), GGC => num(0.25, 0.021),
    GGG => num(0.25, 0.021), GGT => num(0.25, 0.021), TTA => num(0.17, 0.021),
    TTG => num(0.17, 0.021),
  };
  my $thshref = {};
  for my $x (1..$reps)
  {
    my $torf = $GD->codon_juggle(
      -sequence=> $shortobj,
      -algorithm => "random");
    my $offset = 0;
    my $tseq = $torf->seq;
    my $len = length($tseq);
    while ($offset < $len)
    {
      $thshref->{substr($tseq, $offset, 3)}++;
      $offset += 3;
    }
  }
  foreach my $key (keys %$thshref)
  {
    my $ratio = $thshref->{$key} / $reps || 0;
    $thshref->{$key} = sprintf("%.2f", $ratio);
  }
  cmp_deeply($thshref, $rhshref, "codon juggle random");
}