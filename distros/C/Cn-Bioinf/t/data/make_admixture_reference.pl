#!/usr/bin/env perl
# Writes t/data/popgen.3.Q and t/data/popgen.3.P, ADMIXTURE's fit of
# t/data/popgen.vcf at K 3, against which t/admixture.t checks admixture. The
# tests never run this; the two files are committed as ADMIXTURE wrote them.
# Re-run it, from the distribution's root, as
#
#   perl t/data/make_admixture_reference.pl /path/to/plink2 /path/to/admixture
#
# with ADMIXTURE 1.3.0's Linux build (admixture_linux-1.3.0.tar.gz, SHA-256
# 353e8b170c81f8d95946bf18bc78afda5d6bd32645b2a68658bd6781ff35703c, from
# https://dalexander.github.io/admixture/binaries/), which is free for
# academic use but not open source, so is not in Alien::Bioinf. PLINK 2 makes
# its .bed input, keeping the biallelic variants of the autosomes, as
# admixture reads them: PLINK v2.0.0-a.7.15LM (7 Nov 2026), Alien::Bioinf's, on
# 2026-11-17. Both write their files in a temporary directory.
#
# ADMIXTURE was run with seed 43, its default, and -C=1e-12, its convergence
# criterion far below its default of 1e-4, and printed a log-likelihood of
# -15257.557473. Of the seeds 1, 2, 3, 7, 43 and 99 run at its default
# criterion that day, 1 and 2 stopped at a lesser maximum, -15321.242786.
# Each line of .Q is a sample's three ancestry fractions, in the VCF's order;
# each line of .P a variant's three frequencies, in the VCF's order, of its REF
# allele, as t/admixture.t found (one less the ALT frequency that admixture
# gives, to 4.5e-6).
use 5.012;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Copy 'copy';
use File::Spec;
use File::Spec::Functions qw(catfile rel2abs);

my ($plink2, $admixture) = map { defined $_ ? rel2abs($_) : $_ } @ARGV;
die "usage: $0 plink2 admixture\n" unless defined $admixture && -x $plink2 && -x $admixture;
my $vcf = rel2abs(catfile('t', 'data', 'popgen.vcf'));
die "$0: run it from the distribution's root, where $vcf is\n" unless -f $vcf;
my %to = map { $_ => rel2abs(catfile('t', 'data', "popgen.3.$_")) } qw(Q P); # made absolute before the chdir below
my $dir = tempdir(CLEANUP => 1);
chdir $dir or die "$dir: $!";
system($plink2, '--silent', '--vcf', $vcf, '--vcf-half-call', 'missing', '--autosome', '--min-alleles', 2, '--max-alleles', 2,
	'--set-all-var-ids', '@:#', '--make-bed', '--out', 'popgen') == 0 or die "$0: plink2 failed: $?\n";
# ADMIXTURE writes its .Q and .P in the working directory
system($admixture, '-s', 43, '-C=1e-12', 'popgen.bed', 3) == 0 or die "$0: admixture failed: $?\n";
foreach my $ext (sort keys %to) {
	copy("popgen.3.$ext", $to{$ext}) or die "$0: can't write $to{$ext}: $!\n";
}
chdir File::Spec->rootdir or die "can't leave $dir: $!"; # so that it can be removed
