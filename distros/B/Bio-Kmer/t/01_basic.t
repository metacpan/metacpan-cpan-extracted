use strict;
use warnings;
use File::Basename qw/dirname/;
use File::Temp qw/tempdir/;
use FindBin qw/$RealBin/;
use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;
use Data::Dumper qw/Dumper/;

use Test::More tests => 2;

use lib "$RealBin/../lib";
use_ok 'Bio::Kmer';

#die Dumper $Bio::Kmer::VERSION, $Bio::Kmer::iThreads;

# expected histogram
my @correctCounts=(
  0,      # histogram count of 0 instances
  16184,  # histogram count of 1 instance
  17684,  # histogram count of 2 instances
  12763,  # histogram count of 3 instances
  6797,   # histogram count of 4 instances
  2989,   # histogram count of 5 instances
  1080,   # histogram count of 6 instances
  361,    # histogram count of 7 instances
  103,    # histogram count of 8 instances
  15,     # histogram count of 9 instances
  6,      # histogram count of 10 instances
);

# expected query results
my %query=(
  TTGGAGCA => 3,
  TTGGAGCT => 6,
  TTGGAGCTA=> -1, # invalid
  AAAAAAAA => 0,  # not found
);

# Total number of nucleotides expected in rand.fastq.gz
my $ntcount = 150000;

# Test pure perl
subtest "pure perl kmer counting" => sub{
  if(!$Bio::Kmer::iThreads){
    plan skip_all => "No perl threads detected. Will not test.";
    diag $Bio::Kmer::iThreads; # avoid "only used once warning"
  }

  plan tests => 19;

  my $infile = dirname($0)."/../data/rand.fastq.gz";
  my $kmer=Bio::Kmer->new(dirname($0)."/../data/rand.fastq.gz",{kmerlength=>8,kmercounter=>"perl"});
  my $hist=$kmer->histogram() || die Dumper $kmer;
  for(my $i=0;$i<@correctCounts;$i++){
    #diag "Expecting $correctCounts[$i]. Found $$hist[$i]";
    note "Expecting $correctCounts[$i]. Found $$hist[$i]";
    is $$hist[$i], $correctCounts[$i], "Freq of $i checks out";
  }
  for my $query(keys(%query)){
    #diag "Expecting $query{$query}. Found ".$kmer->query($query);
    note "Expecting $query{$query}. Found ".$kmer->query($query);
    is $query{$query}, $kmer->query($query), "Queried for $query{$query}";
  }
  $kmer->close();
  my $numKmers = scalar(keys(%{ $kmer->kmers() }));
  is $numKmers, 57982, "Expected 57982 kmers. Found $numKmers kmers.";

  # Test subsampling: a subsample should have fewer kmers than
  # the full set but more than 0.
  my $subsampleKmer=Bio::Kmer->new(dirname($0)."/../data/rand.fastq.gz",{kmerlength=>8,sample=>0.1});
  my $subsampleHist=$kmer->histogram();
  my $subsampleKmerHash=$subsampleKmer->kmers();
  my $numSubsampledKmers = scalar(keys(%$subsampleKmerHash));

  note "Found $numSubsampledKmers subsampled kmers vs full count of kmers: $numKmers, of a requested frequency of 0.1.";
  note "This subsample probably will be higher than 0.1 because I am just counting unique kmers but the sampling method will sample overall kmers.";

  cmp_ok($numSubsampledKmers, '>', 0, "Subsampled kmers are a nonzero count.");

  cmp_ok($numSubsampledKmers, '<', $numKmers, "Subsample kmers are than the full count.");

  is($kmer->ntcount(), $ntcount, "total number of bp");
};
