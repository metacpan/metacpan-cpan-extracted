use strict;
use warnings;
use File::Basename qw/dirname/;
use FindBin qw/$RealBin/;

use Test::More tests => 29;

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

# Pure perl
my $kmer=Bio::Kmer->new(dirname($0)."/../data/rand.fastq.gz",{kmerlength=>8});
my $hist=$kmer->histogram();
for(my $i=0;$i<@correctCounts;$i++){
  is $$hist[$i], $correctCounts[$i], "Freq of $i checks out";
}
for my $query(keys(%query)){
  is $query{$query}, $kmer->query($query);
}

# Test JF
my $kmerJf=Bio::Kmer->new(dirname($0)."/../data/rand.fastq.gz",{kmerlength=>8, kmercounter=>"jellyfish"});
my $histJf=$kmerJf->histogram();
for(my $i=0;$i<@correctCounts;$i++){
  is $$histJf[$i], $correctCounts[$i], "Freq of $i checks out";
}
for my $query(keys(%query)){
  is $query{$query}, $kmerJf->query($query);
}

