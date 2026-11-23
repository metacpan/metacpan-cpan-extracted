#!/usr/bin/env perl
# Writes parent.vcf, and parent.C.vcf, parent.F.vcf, parent.S.vcf and
# parent.U.vcf, in this directory, for t/parent.t; the tests only read what it
# wrote. Re-run from the distribution root as
#
#   perl t/data/make_parent_vcf.pl
#
# and then t/data/parent_reference.py and PLINK 2, as t/parent.t's header
# says, for the expected values. The genotypes are drawn with Wichmann and
# Hill's generator (Applied Statistics 31:188, 1982, algorithm AS 183), not
# perl's rand, so that any perl writes the same files: it needs no integer
# above 30323 * 172. A single linear congruential generator modulo 2^31, tried
# first, gave one of five seeds a parent and child with an IBS0 rate of 0.016
# where 0.005 was expected, from the correlation between its successive draws.
#
# parent.vcf is a made-up family of seven: F and M are the parents of C and S,
# U is unrelated to them, D is C again (each with its own genotyping errors),
# and G is the child of C and U, so F's grandchild. It has 2,000 biallelic
# SNVs on the autosomes, their ALT frequencies uniform on 0.05 to 0.95, with
# a genotype error rate of 0.5% for every sample and a DP below 10 for 8% of
# genotypes; then the records parent skips or reads specially, each with
# "edge" as its ID.
#
# parent.X.vcf is sample X's own VCF, as a pipeline that lists only its
# sample's variant sites writes it: the records of parent.vcf where X's call
# is not hom-REF, X's column alone. parent.C.vcf names its chromosomes chr1
# to chr22 and the others 1 to 22, and parent.F.vcf lists its chromosomes as
# 1, 10, 11, ... 19, 2, 20, 21, 22, 3, ..., so that the comparison can depend
# on neither. parent.C.vcf and parent.F.vcf each have, after that, records of
# their own (ID "own"): two SNVs at one position, a REF that the other
# file disagrees with, and an ALT that it disagrees with.
use strict;
use warnings;
use FindBin;

chdir $FindBin::Bin or die "$FindBin::Bin: $!";
my @state = (2026, 10, 18); # the seed, each 1 to 30000
sub uniform { # on [0, 1)
	$state[0] = 171 * $state[0] % 30269;
	$state[1] = 172 * $state[1] % 30307;
	$state[2] = 170 * $state[2] % 30323;
	my $u = $state[0] / 30269 + $state[1] / 30307 + $state[2] / 30323;
	$u - int $u;
}
sub allele { uniform() < $_[0] ? 1 : 0 }
sub child_of { # one allele from each parent's pair
	my ($a, $b) = @_;
	[$a->[uniform() < 0.5 ? 0 : 1], $b->[uniform() < 0.5 ? 0 : 1]];
}
# the genotype as written, after an error has turned it, at 0.5%, into one of
# the other two
sub observed {
	my ($g) = @_;
	my $alt = $g->[0] + $g->[1];
	$alt = ($alt + 1 + (uniform() < 0.5 ? 1 : 0)) % 3 if uniform() < 0.005;
	('0/0', '0/1', '1/1')[$alt];
}

my @samples = qw(F M C S U D G);
my @bases = qw(A C G T);
my @lines;
my $sites = 2000;
foreach my $i (0 .. $sites - 1) {
	my $chrom = 1 + int($i * 22 / $sites);
	my $pos = 100000 + 1000 * $i;
	my $p = 0.05 + 0.9 * uniform();
	my $ref = int(4 * uniform());
	my $alt = ($ref + 1 + int(3 * uniform())) % 4;
	my %g;
	$g{$_} = [allele($p), allele($p)] foreach qw(F M U);
	$g{C} = child_of($g{F}, $g{M});
	$g{S} = child_of($g{F}, $g{M});
	$g{D} = $g{C};
	$g{G} = child_of($g{C}, $g{U});
	my @calls = map {
		my $gt = observed($g{$_});
		my $dp = uniform() < 0.08 ? 3 + int(7 * uniform()) : 10 + int(50 * uniform());
		"$gt:$dp";
	} @samples;
	push @lines, join("\t", "chr$chrom", $pos, '.', $bases[$ref], $bases[$alt], '.', 'PASS', '.', 'GT:DP', @calls);
}
# Each is read as the comment says, by parent for the pair C and F; the other
# samples are 0/0 or as given.
my @edge = (
	["chrX\t5000000\tedge\tA\tG\t.\tPASS\t.\tGT\t1/1\t0/0", 'X: not an autosome'],
	["23\t5000100\tedge\tA\tG\t.\tPASS\t.\tGT\t1/1\t0/0", '23 is X'],
	["chrY\t5000000\tedge\tA\tG\t.\tPASS\t.\tGT\t1/1\t0/0", 'Y'],
	["chrM\t500\tedge\tA\tG\t.\tPASS\t.\tGT\t1/1\t0/0", 'MT'],
	["chr1_gl000191_random\t500\tedge\tA\tG\t.\tPASS\t.\tGT\t1/1\t0/0", 'an unplaced contig'],
	["chr01\t600\tedge\tA\tG\t.\tPASS\t.\tGT\t1/1\t0/0", '"01" is not chromosome 1'],
	["chr3\t50\tedge\tAT\tA\t.\tPASS\t.\tGT\t1/1\t0/0", 'an indel'],
	["chr3\t60\tedge\tA\tC,G\t.\tPASS\t.\tGT\t1/1\t0/0", 'more than one ALT'],
	["chr3\t70\tedge\tA\t.\t.\tPASS\t.\tGT\t1/1\t0/0", 'an ALT of "."'],
	["chr3\t80\tedge\tA\t*\t.\tPASS\t.\tGT\t1/1\t0/0", 'an ALT of "*"'],
	["chr3\t90\tedge\tA\tG\t.\tPASS\t.\tDP\t30\t30", 'no GT'],
	["chr3\t100\tedge\tA\tG\t.\tPASS\t.\tGT\t./.\t1/1", 'C missing'],
	["chr3\t110\tedge\tA\tG\t.\tPASS\t.\tGT\t./1\t0/0", 'C partly missing'],
	["chr3\t120\tedge\tA\tG\t.\tPASS\t.\tGT\t1\t0/0", 'C haploid'],
	["chr3\t130\tedge\tA\tG\t.\tPASS\t.\tGT\t0/1/1\t0/0", 'C triploid'],
	["chr3\t140\tedge\tA\tG\t.\tPASS\t.\tGT\t0/2\t0/0", 'C has an allele the site lacks'],
	["chr3\t150\tedge\tA\tG\t.\tPASS\t.\tGT:DP\t1/1:9\t0/0:30", 'C of DP 9'],
	["chr3\t160\tedge\tA\tG\t.\tPASS\t.\tGT:DP\t1/1:.\t0/0:30", 'C of DP ".": counted, IBS0'],
	["chr3\t170\tedge\tA\tG\t.\tPASS\t.\tGT:DP\t1/1\t0/0", 'no DP given: counted, IBS0'],
	["chr3\t180\tedge\tA\tG\t.\tPASS\t.\tDP:GT\t30:0/0\t30:1|1", 'GT after DP, phased: counted, IBS0'],
	["chr3\t190\tedge\tc\tt\t.\tPASS\t.\tGT\t0/1\t0/1", 'lower case: counted, het-het'],
	["chr3\t200\tedge\tA\tG\t.\tPASS\t.\tGT:DP\t0/0:30\t0/0:30", 'both hom-REF: not a site compared'],
);
my %column = map { $samples[$_] => $_ } 0 .. $#samples;
foreach my $e (@edge) {
	my @f = split /\t/, $e->[0];
	my ($c, $f) = @f[9, 10];
	my $other = $f[8] eq 'DP' ? '30' : $f[8] eq 'DP:GT' ? '30:0/0' : $f[8] eq 'GT:DP' ? '0/0:30' : '0/0';
	my @calls = map { $_ eq 'C' ? $c : $_ eq 'F' ? $f : $other } @samples;
	push @lines, join("\t", @f[0 .. 8], @calls);
}
my $head = "##fileformat=VCFv4.2\n"
	. "##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n"
	. "##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read depth\">\n";
sub spew {
	my ($file, $text) = @_;
	open my $fh, '>:raw', $file or die "$file: $!";
	print {$fh} $text or die "$file: $!";
	close $fh or die "$file: $!";
}
spew('parent.vcf', $head . join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT), @samples) . "\n" . join('', map { "$_\n" } @lines));

my %own = (
	C => ["chr5\t50\town\tA\tC\t.\tPASS\t.\tGT\t0/1", "chr5\t50\town\tA\tG\t.\tPASS\t.\tGT\t0/1", "chr5\t60\town\tA\tG\t.\tPASS\t.\tGT\t1/1",
		"chr5\t70\town\tA\tG\t.\tPASS\t.\tGT\t1/1"],
	F => ["5\t60\town\tC\tG\t.\tPASS\t.\tGT\t0/0", "5\t70\town\tA\tT\t.\tPASS\t.\tGT\t1/1"],
);
foreach my $x (qw(C F S U)) {
	my $col = 9 + $column{$x};
	my @mine;
	foreach my $line (@lines) {
		my @f = split /\t/, $line;
		next if $f[$col] =~ m{\A0[/|]0(?::|\z)};
		$f[0] =~ s/\Achr// unless $x eq 'C';
		push @mine, join("\t", @f[0 .. 8], $f[$col]);
	}
	if ($x eq 'F') { # chromosomes in the order of their names as strings
		@mine = map { $_->[1] } sort { $a->[0] cmp $b->[0] || $a->[2] <=> $b->[2] } map { my @f = split /\t/; [$f[0], $_, $f[1]] } @mine;
	}
	push @mine, @{ $own{$x} || [] };
	spew("parent.$x.vcf", $head . join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT), $x) . "\n" . join('', map { "$_\n" } @mine));
}
