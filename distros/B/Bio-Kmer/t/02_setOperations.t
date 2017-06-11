use strict;
use warnings;
use File::Basename qw/dirname/;
use FindBin qw/$RealBin/;

use Test::More tests => 5;

use lib "$RealBin/../lib";
use_ok 'Bio::Kmer';

# Pure perl
my $kmer1=Bio::Kmer->new(dirname($0)."/../data/rand.fastq.gz",{kmerlength=>8});
my $kmer2=Bio::Kmer->new(dirname($0)."/../data/rand2.fastq.gz",{kmerlength=>8});
my $kmer3=Bio::Kmer->new(dirname($0)."/../data/rand2.fastq.gz",{kmerlength=>7});

my $subtraction = $kmer1->subtract($kmer2);
is scalar(@$subtraction), 24159, "Subtraction of kmers";

my $intersection = $kmer1->intersection($kmer2);
is scalar(@$intersection), 33948, "Intersection of all kmers";

my $union = $kmer1->union($kmer2);

is scalar(@$union), 62362, "Union of all kmers";

warn "Testing to make sure there is a warning\n";
my $invalidKmer = ["-1"];
eval{
  $invalidKmer = $kmer2->intersection($kmer3);
};
is $$invalidKmer[0], "-1", "Correctly identified incompatible kmer objects";

