#!/usr/bin/env perl
# Writes concordance.truth.vcf and concordance.test.vcf, in this directory, for
# t/concordance.t; the tests only read what it wrote. Re-run from the
# distribution root as
#
#   perl t/data/make_concordance_vcf.pl
#
# and then t/data/concordance_reference.pl, as t/concordance.t's header says,
# for the expected values.
#
# @Pair holds a truth call and a test call for each of the 45 kinds of
# comparison that ~/Scripts/old/x.low_ram_local_concordance.pl's
# assay_concordance() tells apart, in the order of its @concordance_types.
# Every call is one that script accepted: unphased, its alleles in ascending
# order, and missing only as "./.". Every site has REF A and ALT G,T,C, so
# that alleles 1 to 3 all exist.
#
# The truth's samples are A, B and C, and the test's B, A and D, so that the
# two orders differ and each has a sample the other lacks. Site i (0 to 44) on
# chromosome 1 gives A the calls of pair i, and B those of pair i + 7 (modulo
# 45) where i is a multiple of 3 and of pair 9 (hom-REF in both) elsewhere, so
# that A's counts and B's differ; C and D are hom-REF throughout. Then come a
# site the test has and the truth lacks (ID "test_only"), which the script took
# as a no-call in the truth, and a site the truth has and the test lacks (ID
# "truth_only"), which it never compared.
use strict;
use warnings;
use FindBin;

chdir $FindBin::Bin or die "$FindBin::Bin: $!";
my @Pair = (
	['0/0', '0'],   ['1', '1'],     ['1', '1/1'],   ['0', '0'],     ['0', '0/0'],   ['1/2', '1/2'], ['0/1', '0/1'],
	['1/1', '1/1'], ['1/1', '1'],   ['0/0', '0/0'], ['./.', './.'],
	['1', '2'],     ['1', '0'],     ['1', '1/2'],   ['1', '0/1'],   ['1', '2/2'],   ['1', '0/0'],
	['0', '1'],     ['0', '1/2'],   ['0', '0/1'],   ['0', '1/1'],
	['1/2', '1'],   ['1/2', '0'],   ['1/2', '1/3'], ['1/2', '0/1'], ['1/2', '1/1'], ['1/2', '0/0'],
	['0/1', '1'],   ['0/1', '0'],   ['0/1', '1/2'], ['0/1', '0/2'], ['0/1', '1/1'], ['0/1', '0/0'],
	['1/1', '2'],   ['1/1', '0'],   ['1/1', '1/2'], ['1/1', '0/1'], ['1/1', '2/2'], ['1/1', '0/0'],
	['0/0', '1'],   ['0/0', '1/2'], ['0/0', '0/1'], ['0/0', '1/1'],
	['./.', '0/1'], ['0/1', './.'],
);
die 'make_concordance_vcf.pl: ' . scalar(@Pair) . " pairs, not 45\n" unless @Pair == 45;
my $head = "##fileformat=VCFv4.2\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n"
	. join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT));
my %vcf = (truth => "$head\tA\tB\tC\n", test => "$head\tB\tA\tD\n");
foreach my $i (0 .. $#Pair) {
	my $site = join("\t", 1, 1000 + 10 * $i, "rs$i", 'A', 'G,T,C', '.', 'PASS', '.', 'GT');
	my ($a, $b) = ($Pair[$i], $Pair[$i % 3 ? 9 : ($i + 7) % @Pair]);
	$vcf{truth} .= join("\t", $site, $a->[0], $b->[0], '0/0') . "\n";
	$vcf{test} .= join("\t", $site, $b->[1], $a->[1], '0/0') . "\n";
}
$vcf{test} .= join("\t", 2, 500, 'test_only', 'C', 'T', '.', 'PASS', '.', 'GT', '1/1', '0/1', '0/0') . "\n";
$vcf{truth} .= join("\t", 2, 600, 'truth_only', 'G', 'A', '.', 'PASS', '.', 'GT', '0/1', '1/1', '0/1') . "\n";
foreach my $which (qw(truth test)) {
	my $file = "concordance.$which.vcf";
	open my $fh, '>:raw', $file or die "$file: $!";
	print {$fh} $vcf{$which} or die "$file: $!";
	close $fh or die "$file: $!";
	print "wrote t/data/$file\n";
}
