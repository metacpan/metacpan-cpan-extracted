#!/usr/bin/env perl

# Minimizer.pm: a minimizer package for kmers
# Author: Lee Katz <lkatz@cdc.gov>

package Bio::Minimizer;
require 5.12.0;
our $VERSION=0.8;

use strict;
use warnings;
use File::Basename qw/basename/;
use Data::Dumper;
use Carp qw/carp croak/;

use List::MoreUtils qw/uniq/;

sub logmsg{
  local $0 = basename $0; 
  print STDERR "$0: @_\n";
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

    # hash of minimizer => [start1,start2,...] 
    # Start coordinates are on the fwd strand even when
    # matched against the rev strand.
    my $starts    = $minimizer->{starts}; 

    # With more options
    my $minimizer2= Bio::Minimizer->new($sequenceString,{k=>31,l=>21});

=head1 DESCRIPTION

Creates a set of minimizers from sequence

=head1 EXAMPLES

example: Sort a fastq file by minimizer, potentially 
shrinking gzip size.

This is implemented in this package's scripts/sort*.pl scripts.

    use Bio::Minimizer

    # Read fastq file via stdin, in this example
    while(my $id = <>){
      # Grab an entry
      ($seq,$plus,$qual) = (scalar(<>), scalar(<>), scalar(<>)); 
      chomp($id,$seq,$plus,$qual); 

      # minimizer object
      $MINIMIZER = Bio::Minimizer->new($seq,{k=>length($seq)}); 
      # The only minimizer in this entry because k==length(seq)
      $minMinimizer = (values(%{$$MINIMIZER{minimizers}}))[0]; 

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

=head1 METHODS

=over

=item Bio::Minimizer->new()

    Arguments:
      sequence     A string of ACGT
      settings     A hash
        k          Kmer length
        l          Minimizer length (some might call it lmer)
        numcpus    Number of threads to use. (not used)

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
    revcom     => "",        # revcom of sequence filled in by _minimizers()
    k          => $k,        # kmer length
    l          => $l,        # minimizer length
    numcpus    => $numcpus,
    
    # Filled in by _minimizers()
    minimizers => {},        # kmer      => minimizer
    kmers      => {},        # minimizer => [kmer1,kmer2,...]
    starts     => {},        # minimizer => [start1,start2,...]
  };

  bless($self,$class);

  # Set $$self{minimizers} right away
  $self->_minimizers($sequence);

  return $self;
}

# Argument: string of nucleotides
sub _minimizers{
  my($self,$seq) = @_;

  my $seqLength = length($seq);

  # Also reverse-complement the sequence
  my $revcom = reverse($seq);
  $revcom =~ tr/ATCGatcg/TAGCtagc/;
  $$self{revcom} = $revcom;

  # Length of kmers
  my $k = $$self{k};

  # All sequence segments. Probably only seq and revcom.
  my $fwdMinimizers = $self->minimizerWorker([$seq]);
  my $revMinimizers = $self->minimizerWorker([$revcom]);

  # Merge minimizer hashes
  my %MINIMIZER = (%{$$fwdMinimizers{minimizers}}, %{$$revMinimizers{minimizers}});
  $$self{minimizers} = \%MINIMIZER;

  # Merge start site hashes
  my %START;
  for my $m(uniq(values(%MINIMIZER))){
    # Add all start sites for fwd site minimizers
    for my $pos(@{ $$fwdMinimizers{starts}{$m} }){
      push(@{ $START{$m} }, $pos);
    }
    # recalculate rev minimizer positions
    for my $pos(@{ $$revMinimizers{starts}{$m} }){
      my $revPos = $pos;
      #my $revPos = $seqLength - $pos - $k + 1;
      push(@{ $START{$m} }, $revPos);
    }

    $START{$m} = [sort {$a <=> $b} @{$START{$m}}];
  }
  $$self{starts} = \%START;

  # Get a hash %KMER of minimizer=>[kmer1,kmer2,...]
  my %KMER;
  while(my($kmer,$minimizer) = each(%MINIMIZER)){
    push(@{ $KMER{$minimizer} }, $kmer);
  }

  # Deduplicate %KMER
  while(my($m, $kmers) = each(%KMER)){
    $kmers = [sort {$a cmp $b} uniq(@$kmers)];
  }
  #die Dumper $$self{kmers}{ACGTA};
  $$self{kmers} = \%KMER;
}

sub minimizerWorker{
  my($self, $seqArr) = @_;

  my %MINIMIZER; # minimizers that this thread finds
  my %START;     # minimizer => [start1,start2,...]

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

    for(my $kmerPos=0; $kmerPos<$numKmers; $kmerPos++){

      # The kmer is the subsequence starting at $kmerPos, length $k
      my $kmer=substr($sequence,$kmerPos,$k);
      
      # Get lmers along the length of the sequence into the @lmer buffer.
      # The start counter $lmerPos how many lmers are already in the buffer.
      for(my $lmerPos=scalar(@lmer); $lmerPos < $minimizersPerKmer; $lmerPos++){
        # The lmer will start at $kmerPos plus how many lmers are already
        # in the buffer @lmer, for length $l.
        my $lmer = substr($sequence, $kmerPos+$lmerPos, $l);
        push(@lmer, [$lmerPos, $lmer]);
      }

      # The minimizer is the lowest lmer lexicographically sorted.
      my $minimizerStruct = (sort {$$a[1] cmp $$b[1]} @lmer)[0];
      $MINIMIZER{$kmer} = $$minimizerStruct[1];

      # Record the start position
      my $minimizerStart = $$minimizerStruct[0] + $kmerPos;
      #push(@{ $START{$$minimizerStruct[1]} }, $minimizerStart);
      $START{$$minimizerStruct[1]}{$minimizerStart}=1;

      #logmsg join("\t", $minimizerStart,$$minimizerStruct[1], $kmer);

      # Remove one lmer to reflect the step size of one
      # for the next iteration of the loop.
      my $removedLmer = shift(@lmer);
      for(@lmer){
        $$_[0]--; # lmer position decrement
      }
    }
  }

  # Change index to array of unique sites
  while(my($m, $starts) = each(%START)){
    #$START{$m} = [sort {$a <=> $b} uniq(@$starts)];
    $START{$m} = [sort {$a<=>$b} keys(%$starts)];
  }

  # Return kmer=>minimizer, minimizer=>[start1,start2,...]
  return {minimizers=>\%MINIMIZER, starts=>\%START};
}

1;

