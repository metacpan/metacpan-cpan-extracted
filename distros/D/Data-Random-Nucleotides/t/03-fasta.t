use strict;
use warnings;

use Test::More ;

plan tests => 4;

use Data::Random::Nucleotides qw/rand_fasta/;

## Fixed size - shorter than 70 nt, not wrapped.
my $fasta = rand_fasta(size=>50);
my @lines = split /\n/, $fasta;
my $id = shift @lines;
my $seq = join("", @lines);
like ( $id, qr/^>[\w\-]+$/, "short_fasta_id");
like ( $seq, qr/^[ACGT]{50}/, "short_fasta_seq");

## Fixed size - longer than 70 nt, wrapped.
$fasta = rand_fasta(size=>713);
@lines = split /\n/, $fasta;
$id = shift @lines;
$seq = join("", @lines);
like ( $id, qr/^>[\w\-]+$/, "long_fasta_id");
like ( $seq, qr/^[ACGT]{713}/, "long_fasta_seq");
