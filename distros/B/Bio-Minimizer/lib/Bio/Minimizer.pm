#!/usr/bin/env perl

# Minimizer.pm: a minimizer package for kmers
# Author: Lee Katz <lkatz@cdc.gov>

package Bio::Minimizer;
require 5.12.0;
our $VERSION=0.6;

use strict;
use warnings;
use File::Basename qw/basename/;
use Data::Dumper;
use Carp qw/carp croak/;

use List::MoreUtils qw/uniq/;

# boolean for whether threads are loaded
our $iThreads; 
BEGIN{
  eval{
    require threads;
    require threads::shared;
    $iThreads = 1;
  };
  if($@){
    $iThreads = 0;
  }
}

my $startTime = time();
sub logmsg{
  local $0 = basename $0; 
  my $tid = 0;
  if($iThreads){
    $tid = threads->tid;
  }
  my $elapsedTime = time() - $startTime;
  print STDERR "$0.$tid $elapsedTime @_\n";
}

=pod

=head1 NAME

Bio::Minimizer - minimizer package

Based on the ideas put forth by Roberts et al 2004:
https://academic.oup.com/bioinformatics/article/20/18/3363/202143

=head1 SYNOPSIS

    my $minimizer = Bio::Minimizer->new($sequenceString);
    my $kmers     = $minimizer->{kmers};     # hash of minimizer => kmer
    my $minimizers= $minimizer->{minimizers};# hash of minimizer => [kmer1,kmer2,...]

    # With more options
    my $minimizer2= Bio::Minimizer->new($sequenceString,{k=>31,l=>21});

=head1 DESCRIPTION

Creates a set of minimizers from sequence

=head1 EXAMPLES

example: Sort a fastq file by minimizer, potentially 
shrinking gzip size.

    use Bio::Minimizer

    # Read fastq file via stdin, in this example
    while(my $id = <>){
      # Grab an entry
      ($seq,$plus,$qual) = (scalar(<>), scalar(<>), scalar(<>)); 
      chomp($id,$seq,$plus,$qual); 

      # minimizer object
      $MINIMIZER = Bio::Minimizer->new($seq); 
      # Get smallest minimizer in this entry
      $minMinimizer = (sort {$a cmp $b} values(%{$$MINIMIZER{minimizers}}))[0]; 

      # combine the minimum minimizer with the entry, for
      # sorting later.
      # Save the entry as a string so that we don't have to
      # parse it later.
      my $entry = [$minMinimizer, "$id\n$seq\n$plus\n$qual\n"];
      push(@entry,$entry);
    }
    
    for my $e(sort {$$a[0] cmp $$b[0]} @entry){
      print $$e[1];
    } 

=head1 VARIABLES

=over

=item $Bio::Minimizer::iThreads

Boolean describing whether the module instance is using threads

=back

=head1 METHODS

=over

=item Bio::Minimizer->new()

    Arguments:
      sequence     A string of ACGT
      settings     A hash
        k          Kmer length
        l          Minimizer length (some might call it lmer)
        numcpus    Number of threads to use. Currently might work against you.

=back

=cut

sub new{
  my($class,$sequence,$settings) = @_;

  # Extract from $settings or set defaults
  my $k = $$settings{k} || 31;
  my $l = $$settings{l} || 21;
  my $numcpus = $$settings{numcpus} || 1;

  # Alter the sequence a bit
  $sequence = uc($sequence); # work in uppercase only
  $sequence =~ s/\s+//g;     # Remove all whitespace

  my $self={
    sequence   => $sequence,
    k          => $k,        # kmer length
    l          => $l,        # minimizer length
    numcpus    => $numcpus,  
    
    # Filled in by _minimizers()
    minimizers => {},        # kmer      => minimizer
    kmers      => {},        # minimizer => [kmer1,kmer2,...]
  };

  bless($self,$class);

  if($numcpus > 1){
    carp "WARNING: cpus actually slow down this module at this time";
  }

  # Set $$self{minimizers} right away
  $self->_minimizers($sequence);

  return $self;
}

# Argument: string of nucleotides
sub _minimizers{
  my($self,$seq) = @_;
  my %MINIMIZER; 
  my %KMER;

  # Also reverse-complement the sequence
  my $revcom = reverse($seq);
  $revcom =~ tr/ATCGatcg/TAGCtagc/;

  # Length of kmers
  my $k = $$self{k};

  # Split the seq and revcom into numcpus x 2 parts
  # such that each thread will probably get > 1 subseq
  # and will hopefully balance out the load.
  my @subseq;
  # Ensure some overlap in the subseq lengths by adding in $k.
  for my $sequence($seq, $revcom){
    my $sequenceLength = length($sequence);
    push(@subseq,$sequence);
  }
  
  # If multithreading... 
  if($iThreads && $$self{numcpus} > 1){
    my @thr;
    my $numSubseqPerThread = int(@subseq / $$self{numcpus}) + 1;
    for(my $i=0;$i<$$self{numcpus};$i++){
      my @threadSubseq = splice(@subseq, 0, $numSubseqPerThread);
      $thr[$i] = threads->new(\&minimizerWorker, $self, \@threadSubseq);
    }

    # merge
    for my $t(@thr){
      my $m = $t->join;
      %MINIMIZER = (%MINIMIZER, %$m);
    }
  }
  # If not multithreading...
  else {
    my $minimizers = $self->minimizerWorker(\@subseq);
    %MINIMIZER = %$minimizers;
  }

  $$self{minimizers} = \%MINIMIZER;

  while(my($kmer,$minimizer) = each(%MINIMIZER)){
    push(@{ $KMER{$minimizer} }, $kmer);
  }
  # Deduplicate %KMER
  while(my($m, $kmers) = each(%KMER)){
    $kmers = [sort {$a cmp $b} uniq(@$kmers)];
  }
  $$self{kmers} = \%KMER;
}

sub minimizerWorker{
  my($self, $seqArr) = @_;

  my %MINIMIZER; # minimizers that this thread finds

  # Lengths of kmers and lmers
  my ($k,$l)=($$self{k}, $$self{l}); 

  # How many minimizers we'll get per kmer: the difference in lengths, plus 1
  my $minimizersPerKmer = $k-$l+1;

  for my $sequence(@$seqArr){
    # Number of kmers in the seq is the length of the seq, minus $k, plus 1
    my $numKmers = length($sequence) - $k + 1;

    # Create a small array of lmers along the way
    # so that they don't have to be recalculated
    # all the time between kmers.
    my @lmer;

    for(my $i=0; $i<$numKmers; $i++){

      # The kmer is the subsequence starting at $i, length $k
      my $kmer=substr($sequence,$i,$k);
      
      # Get lmers along the length of the sequence into the @lmer buffer.
      # The start counter $j how many lmers are already in the buffer.
      for(my $j=scalar(@lmer); $j < $minimizersPerKmer; $j++){
        # The lmer will start at $i plus how many lmers are already
        # in the buffer @lmer, for length $l.
        my $lmer = substr($sequence, $i+$j, $l);
        push(@lmer, $lmer);
      }

      # The minimizer is the lowest lmer lexicographically sorted.
      $MINIMIZER{$kmer} = (sort {$a cmp $b} @lmer)[0];

      # Remove one lmer to reflect the step size of one
      # for the next iteration of the loop.
      my $removedLmer = shift(@lmer);
    }
  }

  # Return kmer=>minimizer
  return \%MINIMIZER;
}
 
1;

