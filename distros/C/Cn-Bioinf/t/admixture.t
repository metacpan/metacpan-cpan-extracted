require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use IO::Compress::Gzip qw(gzip $GzipError);
use Cn::Bioinf qw(admixture);
# admixture needs nothing outside the module, so this runs everywhere.
#
# The reference is ADMIXTURE 1.3.0 (Alexander, Novembre and Lange 2009), whose
# model admixture fits: t/data/popgen.3.Q and t/data/popgen.3.P are its fit of
# t/data/popgen.vcf (60 people of YRI, CEU and CHB at 270 SNVs, written by
# t/data/make_popgen_vcf.pl) at K 3, from seed 43 and -C=1e-12, and it printed
# a log-likelihood of -15257.557473; t/data/make_admixture_reference.pl wrote
# them on 2026-11-17 and says how. Its .P gives each population's frequency of
# the REF allele, where admixture gives the ALT's, so one is checked against 1
# less the other. Its populations come in an order of their own, so they are
# matched to admixture's by the permutation that fits best.
#
# Measured on 2026-11-17 (perl 5.44.0): of the starts of seeds 1 and 3 to 12
# that reached the greater maximum, at admixture's default tolerance of 1e-10,
# the worst came within 1.86e-5 of ADMIXTURE's q; at 1e-12 the worst was
# 1.75e-5, which is ADMIXTURE's own convergence and its six printed decimals,
# not admixture's. (At 1e-8, the default first chosen, one start was 1.4e-4
# off, though its log-likelihood was within 1e-6.) The frequencies agreed to
# 4.5e-6, and the log-likelihood to ADMIXTURE's six printed decimals. q and
# the frequencies are compared within 5e-5, about 2.7 times the worst, and the
# log-likelihood within 1e-5, ten times the rounding of ADMIXTURE's figure.
#
# ADMIXTURE found two maxima of this likelihood: -15257.557473, and
# -15321.242786 from seeds 1 and 2 (of 1, 2, 3, 7, 43 and 99). admixture's
# starts from seeds 1 and 2 happen to find one each, the greater from 1; its
# starts are drawn from integers alone (SplitMix64), and so are the same on
# every platform.
#
# A fit is slow on a quadmath perl, whose __float128 arithmetic is done in
# software: on 2026-11-17 this file took 190 s on 5.44.0-quadmath, and 2.5 s
# on 5.44.0, when its first fit had the default ten starts. So only the fits
# whose numbers are compared run to the default tolerance, from no more starts
# than they need, and the rest stop early, which took it to 60 s and 0.8 s.

my $vcf = catfile($FindBin::Bin, 'data', 'popgen.vcf');
my $dir = tempdir(CLEANUP => 1);
sub table {
	my ($file) = @_;
	open my $fh, '<', $file or die "$file: $!";
	my @rows = map { [split] } <$fh>;
	close $fh;
	\@rows;
}
my $Q = table(catfile($FindBin::Bin, 'data', 'popgen.3.Q'));
my $P = table(catfile($FindBin::Bin, 'data', 'popgen.3.P'));
my (@samples, %pop); # the VCF's samples in order; each one's population
{
	open my $fh, '<', $vcf or die "$vcf: $!";
	while (my $line = <$fh>) {
		next unless $line =~ /\A#CHROM/;
		chomp $line;
		@samples = (split /\t/, $line)[9 .. 68];
		last;
	}
	close $fh;
	my $pheno = catfile($FindBin::Bin, 'data', 'popgen.pheno.tsv');
	open $fh, '<', $pheno or die "$pheno: $!";
	<$fh>;
	while (my $line = <$fh>) {
		my ($id, $p) = split /\t/, $line;
		$pop{$id} = $p;
	}
	close $fh;
}
is scalar @samples, 60, 'the VCF names its 60 samples';
is_deeply [scalar @{ $Q }, scalar @{ $P }], [60, 270], 'ADMIXTURE\'s fit has a row for each sample and each variant';
# A file of the VCF's lines, its header kept, with $edit applied to each record.
sub vcf_with {
	my ($name, $edit) = @_;
	open my $in, '<', $vcf or die "$vcf: $!";
	my $file = catfile($dir, $name);
	open my $out, '>', $file or die "$file: $!";
	my $n = 0;
	while (my $line = <$in>) {
		$line = $edit->($line, ++$n) if $line !~ /\A#/;
		print {$out} $line if defined $line;
	}
	close $in;
	close $out or die "$file: $!";
	$file;
}
sub warnings_of {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = $code->();
	($r, \@w);
}

my $fit = admixture(vcf => $vcf, k => 3, starts => 2);
is_deeply [sort keys %{ $fit }], [qw(converged iterations k loglik samples starts variants)], 'the fields returned';
is $fit->{k}, 3, 'k';
is $fit->{converged}, 1, 'the best start converged';
ok $fit->{iterations} >= 1, 'and took iterations';
ok abs($fit->{loglik} - -15257.557473) <= 1e-5, 'the log-likelihood is ADMIXTURE\'s, -15257.557473' or diag sprintf '%.6f', $fit->{loglik};
is scalar @{ $fit->{starts} }, 2, 'starts 2 fits twice';
ok abs($fit->{starts}[0] - $fit->{loglik}) < 1e-5 && abs($fit->{starts}[1] - -15321.242786) < 0.01,
	'and finds both of the maxima that ADMIXTURE found, the greater from seed 1 and -15321.242786 from seed 2';
is scalar keys %{ $fit->{samples} }, 60, 'every sample has its fractions';
is scalar @{ $fit->{variants} }, 270, 'every variant has its frequencies';
is_deeply [sort keys %{ $fit->{variants}[0] }], [qw(alt chrom freq id pos ref)], 'the fields of a variant';
is_deeply [@{ $fit->{variants}[0] }{qw(chrom pos id ref alt)}], [1, 30028088, '.', 'A', 'G'], 'a variant is named by its record';

# ADMIXTURE's populations matched to admixture's
my @perms = ([0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]);
my ($perm, $least);
foreach my $pm (@perms) {
	my $d = 0;
	foreach my $i (0 .. $#samples) {
		$d += abs($fit->{samples}{ $samples[$i] }[$_] - $Q->[$i][ $pm->[$_] ]) foreach 0 .. 2;
	}
	($perm, $least) = ($pm, $d) if !defined $least || $d < $least;
}
my ($q_off, $p_off) = (0, 0);
foreach my $i (0 .. $#samples) {
	foreach my $l (0 .. 2) {
		my $d = abs($fit->{samples}{ $samples[$i] }[$l] - $Q->[$i][ $perm->[$l] ]);
		$q_off = $d if $d > $q_off;
	}
}
foreach my $j (0 .. $#{ $P }) {
	foreach my $l (0 .. 2) {
		my $d = abs($fit->{variants}[$j]{freq}[$l] - (1 - $P->[$j][ $perm->[$l] ]));
		$p_off = $d if $d > $p_off;
	}
}
ok $q_off <= 5e-5, 'every sample\'s fractions are ADMIXTURE\'s' or diag "off by $q_off";
ok $p_off <= 5e-5, 'every variant\'s ALT frequencies are 1 less ADMIXTURE\'s REF frequencies' or diag "off by $p_off";

my ($sums, $bounded) = (1, 1);
foreach my $q (values %{ $fit->{samples} }) {
	my $s = 0;
	$s += $_ foreach @{ $q };
	$sums = 0 if abs($s - 1) > 1e-12;
	# clamped to 1e-5 and then made to sum to 1 again, which can take a
	# fraction below it by a factor of 1 / (1 + 3e-5) at most
	$bounded = 0 if grep { $_ < 1e-5 / (1 + 3e-5) || $_ > 1 } @{ $q };
}
is $sums, 1, 'each sample\'s fractions sum to 1';
is $bounded, 1, 'and none is below ADMIXTURE\'s bound of 1e-5';
my @share = (0, 0, 0);
foreach my $q (values %{ $fit->{samples} }) {
	$share[$_] += $q->[$_] foreach 0 .. 2;
}
ok $share[0] >= $share[1] && $share[1] >= $share[2], 'the populations come largest first';
# each of the three populations of 1000 Genomes is mostly one of the three
my %mean;
foreach my $s (@samples) {
	$mean{ $pop{$s} }[$_] += $fit->{samples}{$s}[$_] / 20 foreach 0 .. 2;
}
my %top = map { my $m = $mean{$_}; ($_ => (sort { $m->[$b] <=> $m->[$a] } 0 .. 2)[0]) } keys %mean;
is scalar(keys %{ { reverse %top } }), 3, 'YRI, CEU and CHB are each mostly a population of their own';
ok $mean{YRI}[ $top{YRI} ] > 0.85 && $mean{CHB}[ $top{CHB} ] > 0.85 && $mean{CEU}[ $top{CEU} ] > 0.7,
	'by 0.89, 0.88 and 0.75 in ADMIXTURE\'s fit' or diag join ' ', map { sprintf '%s %.3f', $_, $mean{$_}[ $top{$_} ] } sort keys %mean;

#  the starts

my $one = admixture(vcf => $vcf, k => 3, starts => 1, seed => 2);
is scalar @{ $one->{starts} }, 1, 'starts 1 fits once';
ok abs($one->{loglik} - -15321.242786) < 0.01, 'and from seed 2 stops at the lesser maximum';
# Each of these warns that it did not converge; caught, so that the warnings
# stay off the terminal.
my @again = map { (warnings_of(sub { admixture(vcf => $vcf, k => 3, starts => 1, seed => 2, max_iterations => 3, tolerance => 1e-300) }))[0] } 1, 2;
is_deeply $again[1], $again[0], 'the same seed gives the same fit';
my ($short, $w) = warnings_of(sub { admixture(vcf => $vcf, k => 3, max_iterations => 1) });
is scalar @{ $short->{starts} }, 10, 'ten starts by default';
is $short->{converged}, 0, 'max_iterations 1 does not converge';
is $short->{iterations}, 1, 'and stops after 1';
is scalar @{ $w }, 1, 'with one warning';
like $w->[0], qr/^admixture: the best of the 10 starts stopped after 1 iterations without converging \(its log-likelihood still rising by 1e-10 or more\); give a larger "max_iterations"/,
	'which says so';
# Strawberry Perl 5.24.4's C runtime writes 1e-10 as "1e-010", which the
# warning above gave there in 0.03-TRIAL (CPAN Testers report
# 363318e0-e362-11f1-808f-855b4a25bcf6, 2026-11-18). A tolerance given as that
# text shows the same thing on any perl.
(undef, $w) = warnings_of(sub { admixture(vcf => $vcf, k => 3, starts => 1, max_iterations => 1, tolerance => '1e-010') });
like $w->[0], qr/ \(its log-likelihood still rising by 1e-10 or more\);/,
	'the tolerance is shown with a two-digit exponent, rather than as "1e-010" from a C runtime that writes three';
my $loose = admixture(vcf => $vcf, k => 3, starts => 1, tolerance => 1);
ok $loose->{converged} && $loose->{iterations} < $fit->{iterations}, 'a loose tolerance converges sooner';

#  what is read

my $gz = catfile($dir, 'popgen.vcf.gz');
gzip($vcf => $gz) or die "gzip: $GzipError";
ok abs(admixture(vcf => $gz, k => 3, starts => 1)->{loglik} - $fit->{loglik}) < 1e-5, 'a .vcf.gz is read as the VCF is';
# chromosome 1 moved to X, chromosome 2's ALTs given a second allele, and
# chromosome 3's first sample made haploid
my $odd = vcf_with('odd.vcf', sub {
	my ($line) = @_;
	$line =~ s/\A1\t/X\t/;
	$line =~ s/\A(2\t[0-9]+\t\.\t[ACGT]\t)([ACGT])\t/$1$2,T\t/;
	$line =~ s/\A(3\t(?:[^\t]*\t){8})[01][|][01]\t/${1}1\t/;
	$line;
});
my $o = admixture(vcf => $odd, k => 3, starts => 1, tolerance => 1);
is scalar @{ $o->{variants} }, 250, 'X and multi-allelic records are left out';
is $o->{variants}[0]{chrom}, 3, 'so that the first variant is on 3';
# the sample's genotypes, each made missing: an even share of each population
my $blank = vcf_with('blank.vcf', sub {
	my ($line) = @_;
	$line =~ s/\A((?:[^\t]*\t){9})[^\t]+/${1}.|./;
	$line;
});
my ($blank_fit, $bw) = warnings_of(sub { admixture(vcf => $blank, k => 3, starts => 1, tolerance => 1) });
ok !(grep { abs($_ - 1 / 3) > 1e-12 } @{ $blank_fit->{samples}{NA06984} }), 'a sample with no called genotype gets an even share of each population';
is scalar @{ $bw }, 1, 'with one warning';
like $bw->[0], qr/^admixture: 1 sample has no called genotype, and so an even share of each population: "NA06984"/, 'which names it';
dies_like(sub { admixture(vcf => vcf_with('x.vcf', sub { (my $l = $_[0]) =~ s/\A[0-9]+\t/X\t/; $l }), k => 3) },
	qr/^admixture: "vcf" .+x\.vcf has no biallelic variant on the autosomes \(1 to 22\), which are all that admixture reads/,
	'a VCF of X alone dies');
sub dies_like {
	my ($code, $re, $name) = @_;
	eval { $code->(); 1 } and return fail($name);
	like $@, $re, $name;
}

done_testing;
