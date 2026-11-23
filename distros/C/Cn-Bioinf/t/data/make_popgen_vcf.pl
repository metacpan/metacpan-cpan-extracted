#!/usr/bin/env perl
# Writes t/data/popgen.vcf and t/data/popgen.pheno.tsv, the fixtures of
# t/popgen.t and t/admixture.t. The tests never run this; the two files are
# committed. Re-run it, from the distribution's root, as
#
#   perl t/data/make_popgen_vcf.pl 1000genomes.bcf integrated_call_samples_v3.20130502.ALL.panel
#
# where the first is 1000 Genomes phase 3 as one indexed BCF (the 22 files
# ALL.chr<n>.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz
# of https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/, joined with
# bcftools concat) and the second is the panel beside them, whose first three
# columns are the sample, its population and its super-population. It needs
# bcftools on PATH (1.21 wrote the files, on 2026-11-13).
#
# The VCF holds 60 people, the first 20 of each of YRI (Yoruba in Ibadan), CEU
# (Utah residents of northern and western European ancestry) and CHB (Han
# Chinese in Beijing) in the panel's order, three populations far enough apart
# that a few hundred variants tell them apart, and 270 biallelic SNVs whose
# minor allele's frequency among those 60 is 0.1 or more:
#
#   - the first 10 such on each of chromosomes 1 to 21 from position
#     30,000,000 on that are at least 20,000 bases from the one before, 210
#     variants for pca, fst and admixture. They were meant to be in no linkage
#     disequilibrium to speak of, and are not: on 2026-11-17 PLINK 2's
#     --r2-unphased found 233 pairs of them (all within a chromosome's 10) at
#     r^2 0.2 or more, 97 at 0.5 or more, and some at 1, such as 5:30140659 and
#     5:30182596. That is strong LD over 20 to 60 kb in 60 people of three
#     populations, and t/popgen.t's tests count on it as it is;
#   - the first 60 such on chromosome 22 from position 20,000,000 on, which lie
#     within a few thousand bases of one another, for ld.
#
# The genotypes are phased, as 1000 Genomes has them, and the IDs are ".", as
# that BCF has them. 1000 Genomes has no missing genotype, so six are made
# missing here, at the variants and samples %Missing names, for the tests to
# have some.
#
# The phenotypes are made up, from the genotypes and the numbers of rand31()
# below, so that an association test has something to find: "quant" is 0.8 for
# each ALT allele of variant 101 (counting from 1, in the VCF's order) plus
# noise, "binary" is 2 (a case) for the 30 people highest on 1.2 for each ALT
# allele of variant 151 plus noise, and 1 (a control) for the rest, and "age"
# is noise alone, between 20 and 69, for a covariate.
use 5.044;
no source::encoding;
use warnings FATAL => 'all';
use autodie ':default';

my ($bcf, $panel) = @ARGV;
die "usage: $0 1000genomes.bcf panel\n" unless defined $panel && -f $bcf && -f $panel;
my @Pops = qw(YRI CEU CHB);
my $Per_pop = 20;     # people of each population
my $Min_maf = 0.1;    # the least frequency of the minor allele among the people kept
my $Spacing = 20_000; # the least distance between two of a chromosome's unlinked variants
my $Per_chrom = 10;   # unlinked variants from each of chromosomes 1 to 21
my $Linked = 60;      # variants of the block on chromosome 22
# variant (counting from 0, in the VCF's order) => the samples (counting from 0) whose genotype is made missing
my %Missing = (37 => [11], 74 => [22], 111 => [33], 148 => [44], 185 => [55], 222 => [6]);

my (%pop_of, %taken, @samples);
open my $p, '<', $panel;
while (my $line = <$p>) {
	my ($sample, $pop) = split /\t/, $line;
	next unless grep { $_ eq $pop } @Pops;
	next if ($taken{$pop} // 0) >= $Per_pop;
	$taken{$pop}++;
	$pop_of{$sample} = $pop;
}
close $p;
# in the BCF's order, which is the order bcftools writes them in
open my $q, '-|', 'bcftools', 'query', '-l', $bcf;
chomp(my @all = <$q>);
close $q;
@samples = grep { defined $pop_of{$_} } @all;
die 'found ' . scalar(@samples) . ' of the ' . @Pops * $Per_pop . " samples in $bcf\n" unless @samples == @Pops * $Per_pop;

# The biallelic SNVs of $region whose minor allele is frequent enough, as
# [CHROM, POS, REF, ALT, genotypes], at least $spacing apart, $want of them.
sub variants {
	my ($region, $spacing, $want) = @_;
	my @kept;
	open my $v, '-|', 'bcftools', 'view', '-H', '-v', 'snps', '-m2', '-M2', '-s', join(',', @samples), '-r', $region, $bcf;
	while (my $line = <$v>) {
		chomp $line;
		my ($chrom, $pos, undef, $ref, $alt, undef, undef, undef, undef, @gt) = split /\t/, $line;
		next unless $ref =~ /\A[ACGT]\z/ && $alt =~ /\A[ACGT]\z/;
		next if @kept && $pos - $kept[-1][1] < $spacing;
		my $alts = () = join('', @gt) =~ /1/g;
		my $freq = $alts / (2 * @gt);
		next if $freq < $Min_maf || $freq > 1 - $Min_maf;
		push @kept, [$chrom, $pos, $ref, $alt, \@gt];
		last if @kept == $want;
	}
	# bcftools is stopped part-way through the region, so its exit status says nothing
	eval { close $v };
	die "only " . scalar(@kept) . " variants in $region\n" unless @kept == $want;
	@kept;
}
my @variants = map { variants("$_:30000000-", $Spacing, $Per_chrom) } 1 .. 21;
push @variants, variants('22:20000000-', 1, $Linked);

my %length;
open my $h, '-|', 'bcftools', 'view', '-h', $bcf;
while (my $line = <$h>) {
	$length{$1} = $2 if $line =~ /\A##contig=<ID=([0-9]+),assembly=b37,length=([0-9]+)>/;
}
close $h;

open my $out, '>', 't/data/popgen.vcf';
print {$out} "##fileformat=VCFv4.2\n", "##source=t/data/make_popgen_vcf.pl, from 1000 Genomes phase 3\n",
	(map { "##contig=<ID=$_,assembly=b37,length=$length{$_}>\n" } 1 .. 22),
	"##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n",
	join("\t", '#CHROM', qw(POS ID REF ALT QUAL FILTER INFO FORMAT), @samples), "\n";
foreach my $i (0 .. $#variants) {
	my ($chrom, $pos, $ref, $alt, $gt) = @{ $variants[$i] };
	$gt->[$_] = '.|.' foreach @{ $Missing{$i} // [] };
	print {$out} join("\t", $chrom, $pos, '.', $ref, $alt, '.', 'PASS', '.', 'GT', @{ $gt }), "\n";
}
close $out;

# The generator of C's rand() in the C standard's example (ISO C99 7.20.2.2),
# kept to 31 bits, so that the numbers are the same wherever this is run.
my $seed = 20261113; # the date this was written
sub rand31 { $seed = ($seed * 1103515245 + 12345) % 2**31 }
# about normal, with mean 0 and standard deviation 1: twelve uniform numbers less 6
sub noise { my $s = 0; $s += rand31() / 2**31 foreach 1 .. 12; $s - 6 }
sub dosage { my ($i, $s) = @_; my $n = () = $variants[$i][4][$s] =~ /1/g; $n }
my (@quant, @liability, @age);
foreach my $s (0 .. $#samples) {
	push @quant, sprintf '%.4f', 0.8 * dosage(100, $s) + noise();
	push @liability, 1.2 * dosage(150, $s) + noise();
	push @age, 20 + rand31() % 50;
}
my @by_liability = sort { $liability[$b] <=> $liability[$a] } 0 .. $#samples;
my %case = map { $_ => 1 } @by_liability[0 .. @samples / 2 - 1];
open my $ph, '>', 't/data/popgen.pheno.tsv';
print {$ph} "#IID\tpop\tquant\tbinary\tage\n";
print {$ph} join("\t", $samples[$_], $pop_of{ $samples[$_] }, $quant[$_], $case{$_} ? 2 : 1, $age[$_]), "\n" foreach 0 .. $#samples;
close $ph;
