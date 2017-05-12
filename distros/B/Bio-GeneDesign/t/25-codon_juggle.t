#! /usr/bin/perl -T

use Test::More tests => 5;
use Test::Deep;

use Bio::GeneDesign;
use Bio::Seq;

use strict;
use warnings;

my $GD = Bio::GeneDesign->new();
$GD->set_organism(-organism_name => "Escherichia_coli",
                  -table_path => "codon_tables/Standard.ct",
                  -rscu_path => "codon_tables/Escherichia_coli.rscu");

my $reps = 10000;

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

my $shortseq = "ATGGGGATCGACTTG";
my $shortobj = Bio::Seq->new( -seq => $shortseq, -id => "tshortseq");

# TESTING codon_juggle high algorithm
if (1)
{
  my $trevorf = $GD->codon_juggle(
    -sequence=> $seqobj,
    -algorithm => "high");
  my $rrevorf = "ATGGACCGTTCTTGGAAACAGAAACTGAACCGTGACACCGTTAAACTGACCGAAGTTATGA";
  $rrevorf .= "CCTGGCGTCGTCCGGCTGCTAAATGGTTCTACACCCTGATCAACGCTAACTACCTGCCGCCGT";
  $rrevorf .= "GCCCGCCGGACCACCAGGACCACCGTCAGCAGCAGCTGCCGGAACCGGACCAGCCGGAACACC";
  $rrevorf .= "AGCGTCCGGAACAGCCGCACCAGGCTGCTCCGCCGGACCGTCTGGCTGCTCAGGCTGGTCCGC";
  $rrevorf .= "ACCTGCTGCTGCCGCCGGGTGACCCGCCGGCTCGTGAAGGTCCGGCTCTGCCGGCTGGTGAAG";
  $rrevorf .= "GTCTGGAAGACCACCTGTCTGGTCAGCGTCCGGAAGAAGCTGGTTGGCGTGGTCACCCGGACC";
  $rrevorf .= "AGCGTCAGGACCGTCTGCCGGCTCAGGGTGACCAGGAAGGTCAGGGTGGTCCGCTGCACCCGG";
  $rrevorf .= "ACCAGGGTCAGGACCCGGCTGGTGGTGCTGAACACTCTGAACACCTGCGTCCGCAGCGTCCGC";
  $rrevorf .= "GTCGTCACCTGCACCAGGGTCACCCGCGTGAAGCTGAAGGTCCGCACCGTTCTCCGCACCACC";
  $rrevorf .= "ACCGTCGTCGTCCGGAACACCCGCCGGAACAG";
  is ($trevorf->seq, $rrevorf, "codon juggle high");
}

# TESTING codon_juggle most different sequence algorithm
if (1)
{
  my $trevorf = $GD->codon_juggle(
    -sequence=> $seqobj,
    -algorithm => "most_different_sequence");
  my $rrevorf = "ATGGATCGCAGCTGGAAACAAAAATTAAATAGAGATACGGTCAAATTAACGGAAGTCATGACGTGGCGCCGCCCAGCGGCAAAGTGGTTCTACACGCTTATAAACGCAAACTACCTTCCTCCTTGTCCTCCAGATCATCAGGACCATAGACAACAGCAGTTGCCAGAACCAGACCAACCAGAGCACCAGAGACCAGAGCAACCACACCAGGCCGCCCCTCCAGATAGGTTAGCAGCCCAGGCCGGCCCACATTTGTTACTTCCACCTGGCGATCCTCCAGCCAGGGAGGGCCCTGCCTTGCCAGCCGGGGAGGGCTTAGAGGATCACTTGAGTGGGCAGAGACCAGAGGAGGCCGGGTGGAGAGGGCACCCAGACCAAAGGCAGGACAGGTTGCCTGCGCAGGGGGACCAGGAGGGCCAGGGCGGCCCTTTGCACCCAGACCAGGGCCAGGACCCAGCCGGCGGCGCAGAACACAGCGAGCACTTGAGACCACAGAGACCTAGAAGACATTTGCACCAGGGCCATCCAAGAGAGGCAGAGGGGCCTCACAGAAGTCCTCATCACCACAGAAGAAGGCCAGAGCATCCACCAGAACAA";
  is ($trevorf->seq, $rrevorf, "codon juggle most different sequence");
}

# TESTING codon_juggle least different rscu algorithm
if (1)
{
  my $trevorf = $GD->codon_juggle(
    -sequence=> $seqobj,
    -algorithm => "least_different_rscu");
  my $rrevorf = "ATGGATAGGTCCTGGAAGCAGAAGCTGAACCGCGATACTGTCAAGCTGACTGAGGTCATGACTTGGAGGAGGCCTGCGGCAAAATGGTTTTATACCTTGATAAATGCAAATTATTTACCTCCTTGTCCTCCTGATCACCAAGACCACAGACAGCAACAATTACCCGAGCCCGACCAGCCCGAACATCAAAGACCCGAACAGCCTCATCAAGCAGCGCCGCCCGATAGACTGGCAGCGCAAGCGGGGCCTCACCTCCTGTTACCCCCTGGGGATCCTCCCGCAAGAGAAGGGCCGGCGTTACCCGCAGGCGAAGGACTGGAAGATCATCTCTCGGGTCAAAGACCCGAAGAAGCGGGTTGGCGTGGTCATCCCGACCAGAGACAAGACAGACTCCCTGCGCAAGGCGACCAAGAAGGGCAAGGGGGACCTCTCCATCCCGACCAAGGACAAGACCCCGCGGGGGGGGCAGAGCATTCCGAACATTTACGCCCTCAACGCCCGCGCCGCCACCTCCATCAAGGGCACCCCCGTGAAGCAGAAGGTCCTCATCGCTCTCCTCACCATCATCGTAGAAGACCCGAACACCCTCCCGAGCAG";
  is ($trevorf->seq, $rrevorf, "codon juggle least different rscu");
}

# TESTING codon_juggle balanced algorithm
if (1)
{
  my $rhshref =
  {
    ATA => num(0.01, 0.021), ATC => num(0.83, 0.021), ATG => num(1.00, 0.021),
    ATT => num(0.16, 0.021), CTA => num(0.01, 0.021), CTC => num(0.03, 0.021),
    CTG => num(0.92, 0.021), CTT => num(0.02, 0.021), GAC => num(0.75, 0.021),
    GAT => num(0.26, 0.021), GGC => num(0.42, 0.021), GGG => num(0.01, 0.021),
    GGT => num(0.56, 0.021), TTA => num(0.01, 0.021), TTG => num(0.01, 0.021),
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