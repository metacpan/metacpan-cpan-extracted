use strict;
use warnings;
use File::Basename qw/dirname/;
use File::Temp qw/tempdir/;
use FindBin qw/$RealBin/;
use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;
use Data::Dumper qw/Dumper/;

use Test::More tests => 17;

use lib "$RealBin/../lib";
use_ok 'Bio::Kmer';

# expected histogram
my @correctCounts=(
  0,
  16087,
  17621,
  12868,
  6857,
  3070,
  1096,
  380,
  105,
  17,
# 6,
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
  is $$hist[$i], $correctCounts[$i], "Freq of $i checks out";
}
for my $query(keys(%query)){
  is $query{$query}, $kmer->query($query), "Queried for $query{$query}";
}
$kmer->close();

# Test subsampling: a subsample should have fewer kmers than
# the full set but more than 0.
my $subsampleKmer=Bio::Kmer->new(dirname($0)."/../data/rand.fastq.gz",{kmerlength=>8,sample=>0.1});
my $subsampleHist=$kmer->histogram();
my $subsampleKmerHash=$subsampleKmer->kmers();
my $numSubsampledKmers = scalar(keys(%$subsampleKmerHash));
my $numKmers = scalar(keys(%{ $kmer->kmers() }));

ok(($numSubsampledKmers > 0), "Subsample kmers, and there are a nonzero count of results.");

ok(($numSubsampledKmers < $numKmers), "Subsample kmers fewer than full count of kmers");


