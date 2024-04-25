use strict;
use warnings;
use File::Basename qw/dirname/;
use File::Temp qw/tempdir/;
use FindBin qw/$RealBin/;
use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;
use Data::Dumper qw/Dumper/;
use File::Which qw/which/;

use Test::More tests => 16;

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

# Test JellyFish
SKIP:{
  my $jellyfish = which("jellyfish");
  if(!defined($jellyfish) or ! -e $jellyfish){
    #diag "Jellyfish not found in PATH. Skipping.";
    skip("Jellyfish not found in PATH.", 15);
  }
    
  my $jfVersion=`$jellyfish --version 2>/dev/null`; chomp($jfVersion);
  if($?){
    #diag "Jellyfish error and/or jellyfish version < 2. Skipping Jellyfish tests.";
    skip("Jellyfish error and/or jellyfish version < 2.", 15);
  }

  # e.g., jellyfish 2.2.6
  if($jfVersion =~ /(jellyfish\s+)?(\d+)?/){
    my $majorVersion=$2;
    if($majorVersion < 2){
      diag "Jellyfish v2 or greater is required for Jellyfish counting. Skipping Jellyfish tests.";
      skip("Jellyfish test", 15);
    }
  }
  if(!$jfVersion){
    diag "Jellyfish version was not found. Skipping Jellyfish tests.";
    skip("Jellyfish test.", 15);
  }

  my $kmerJf=Bio::Kmer->new($RealBin."/data/rand.fastq.gz",{kmerlength=>8, kmercounter=>"jellyfish"});
  my $histJf=$kmerJf->histogram();
  for(my $i=0;$i<@correctCounts;$i++){
    is $$histJf[$i], $correctCounts[$i], "Freq of $i checks out";
  }
  for my $query(keys(%query)){
    is $query{$query}, $kmerJf->query($query), "Queried for $query{$query}";
  }

  is($kmerJf->ntcount, 58107, "estimated length by jellyfish");
}

