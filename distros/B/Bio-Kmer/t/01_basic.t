use strict;
use warnings;
use File::Basename qw/dirname/;
use File::Temp qw/tempdir/;
use FindBin qw/$RealBin/;
use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;
use Data::Dumper qw/Dumper/;

use Test::More tests => 19;

use lib "$RealBin/../lib";
use_ok 'Bio::Kmer';

# expected histogram
my @correctCounts=(
  0,      # histogram count of 0 instances
  16087,  # histogram count of 1 instance
  17621,  # histogram count of 2 instances
  12868,  # histogram count of 3 instances
  6857,   # histogram count of 4 instances
  3070,   # histogram count of 5 instances
  1096,   # histogram count of 6 instances
  380,    # histogram count of 7 instances
  105,    # histogram count of 8 instances
  17,     # histogram count of 9 instances
  6,      # histogram count of 10 instances
);

# expected query results
my %query=(
  TTGGAGCA => 3,
  TTGGAGCT => 6,
  TTGGAGCTA=> -1, # invalid
  AAAAAAAA => 0,  # not found
);

# Test pure perl
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
is $numKmers, 58107, "Expected 58107 kmers. Found $numKmers kmers.";

# Test subsampling: a subsample should have fewer kmers than
# the full set but more than 0.
my $subsampleKmer=Bio::Kmer->new(dirname($0)."/../data/rand.fastq.gz",{kmerlength=>8,sample=>0.1});
my $subsampleHist=$kmer->histogram();
my $subsampleKmerHash=$subsampleKmer->kmers();
my $numSubsampledKmers = scalar(keys(%$subsampleKmerHash));

note "Found $numSubsampledKmers subsampled kmers vs full count of kmers: $numKmers, of a requested frequency of 0.1";

cmp_ok($numSubsampledKmers, '>', 0, "Subsampled kmers are a nonzero count.");

cmp_ok($numSubsampledKmers, '<', $numKmers, "Subsample kmers are than the full count.");


