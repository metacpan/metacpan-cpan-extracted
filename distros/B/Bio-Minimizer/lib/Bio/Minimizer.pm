#!/usr/bin/env perl

# Minimizer.pm: a minimizer package for kmers
# Author: Lee Katz <lkatz@cdc.gov>

package Bio::Minimizer;
require 5.10.0;
our $VERSION=0.1;

use strict;
use warnings;

our $iThreads; # boolean for whether threads are loaded
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

# TODO if 'die' is imported by a script, redefine
# sig die in that script as this function.
local $SIG{'__DIE__'} = sub { my $e = $_[0]; $e =~ s/(at [^\s]+? line \d+\.$)/\nStopped $1/; die("$0: ".(caller(1))[3].": ".$e); };

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
    my $kmers     = $minimizer->kmers;     # hash of minimizer => kmer
    my $minimizers= $minimizer->minimizers;# hash of minimizer => [kmer1,kmer2,...]

    # With more options
    my $lmer      = Bio::Minimizer->new($sequenceString,{k=>31,l=>21});

=head1 DESCRIPTION

Creates a set of minimizers from sequence

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

=back

=cut

sub new{
  my($class,$sequence,$settings) = @_;

  # Extract from $settings or set defaults
  my $k = $$settings{k} || 31;
  my $l = $$settings{l} || 21;

  # Alter the sequence a bit
  $sequence = uc($sequence); # work in uppercase only
  $sequence =~ s/\s+//g;     # Remove all whitespace

  my $self={
    sequence   => $sequence,
    k          => $k,        # kmer length
    l          => $l,        # minimizer length
    
    # Filled in by _minimizers()
    minimizers => {},        # kmer      => minimizer
    kmers      => {},        # minimizer => [kmer1,kmer2,...]
  };

  bless($self,$class);

  # Set $$self{minimizers} right away
  $self->_minimizers($sequence);

  return $self;
}

# Argument: string of nucleotides
sub _minimizers{
  my($self,$seq) = @_;
  my %LMER; 
  my %KMER;

  my ($k,$l)=($$self{k}, $$self{l}); 
  my $defaultSmallestMinimizer = 'Z' x $l;

  # How many minimizers we'll get per ker: the difference in lengths, plus 1
  my $minimizersPerKmer = $k-$l+1;

  # Number of kmers in the seq is the length of the seq, minus $k, plus 1
  my $numKmers = length($seq) - $k + 1;
  for(my $i=0; $i<$numKmers; $i++){
    # Extract the kmer before getting all the minimizers
    my $kmer=substr($seq,$i,$k);
    # Start the 'smallest minimizer' as a very 'large' minimizer
    # so that all real minimizers are smaller than it.
    my $smallestMinimizer = $defaultSmallestMinimizer;
    for(my $j=0; $j<$minimizersPerKmer; $j++){
      # Test each substr of the kmer (minimizer) to find
      # the alphabetically lowest one.
      my $minimizer = substr($kmer, $j, $l);
      if($minimizer lt $smallestMinimizer){
        $smallestMinimizer = $minimizer;
      } 

      # Record the real minimizer for this kmer
      $LMER{$kmer} = $minimizer;
      # Record the kmers for which this minimizer indexes
      push(@{ $KMER{$minimizer} }, $kmer);
    } 
  } 

  $$self{minimizers} = \%LMER;
  $$self{kmers}      = \%KMER;

  # Go ahead and return kmer=>minimizer
  return \%LMER;
}
 
