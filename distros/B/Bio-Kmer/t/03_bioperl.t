use strict;
use warnings;
use File::Basename qw/dirname/;
use File::Temp qw/tempdir/;
use FindBin qw/$RealBin/;
use IO::Uncompress::Gunzip qw/gunzip $GunzipError/;
use Data::Dumper qw/Dumper/;

use Test::More tests => 15;

use lib "$RealBin/../lib";
use_ok 'Bio::Kmer';

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
);

# expected query results
my %query=(
  TTGGAGCA => 3,
  TTGGAGCT => 6,
  TTGGAGCTA=> -1, # invalid
  AAAAAAAA => 0,  # not found
);

# Test reading a BioPerl object
SKIP:{
  if(! $Bio::Kmer::iThreads){
    skip("No perl threads loaded. Skipping", 14);
    print $Bio::Kmer::iThreads; # avoid only used once warning
  }

  eval{
    require Bio::SeqIO;
  };
  if($@){
    diag "BioPerl not found. Skipping BioPerl tests.";
    skip("Bio::Perl test.", 14);
  } else {
    my $tempdir=tempdir("biokmertest.XXXXXX",TMPDIR=>1,CLEANUP=>1);

    # Make the bioperl input file
    gunzip (dirname($0)."/../data/rand.fastq.gz" => "$tempdir/bp.fastq") or die "ERROR: could not decompress rand.fastq.gz with gunzip: $!";
    my $seqin=Bio::SeqIO->new(-file=>"$tempdir/bp.fastq");
    my $kmerBP=Bio::Kmer->new($seqin,{kmerlength=>8});
    my $histBP=$kmerBP->histogram();
    for(my $i=0;$i<@correctCounts;$i++){
      is $$histBP[$i], $correctCounts[$i], "Freq of $i checks out";
    }
    for my $query(keys(%query)){
      is $query{$query}, $kmerBP->query($query), "Queried for $query{$query}";
    }
  }
}

