require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use Cn::Bioinf qw(fst gwas hardy_weinberg ld ld_prune pca);
my $plink2 = eval { require Alien::Bioinf; Alien::Bioinf->plink2 };
plan skip_all => 'pca, fst, hardy_weinberg, ld, ld_prune and gwas run PLINK 2, which Alien::Bioinf installs, and it is not installed here'
	unless defined $plink2 && -x $plink2;
# t/data/popgen.vcf and t/data/popgen.pheno.tsv are 60 people of 1000 Genomes
# (20 each of YRI, CEU and CHB) at 270 biallelic SNVs, with six genotypes made
# missing and three phenotypes made up from the genotypes, as
# t/data/make_popgen_vcf.pl describes; that script wrote them on 2026-11-13.
#
# The expected values are what PLINK v2.0.0-a.7.15LM (7 Nov 2026), Alien::Bioinf's,
# printed when run by hand on 2026-11-17 on the same filtering of the same
# files as the functions make, from the distribution's root:
#
#   plink2 --vcf t/data/popgen.vcf --vcf-half-call missing --autosome --min-alleles 2 --max-alleles 2 \
#     --set-all-var-ids '@:#' --make-pgen --out g
#   plink2 --pfile g --pca 3 --out pca
#   plink2 --pfile g --pheno t/data/popgen.pheno.tsv --fst pop report-variants --out fh
#   plink2 --pfile g --pheno t/data/popgen.pheno.tsv --fst pop method=wc --out fw
#   plink2 --pfile g --hardy --out h                  (and --hardy midp)
#   plink2 --pfile g --r2-unphased --out lu           (and --r2-phased cols=+dprime, and
#                                                      --r2-unphased --ld-window 2 --ld-window-r2 0)
#   plink2 --pfile g --indep-pairwise 50 5 0.5 --out pr    (and 200kb 1 0.2)
#   plink2 --pfile g --pheno t/data/popgen.pheno.tsv --pheno-name quant binary \
#     --glm omit-ref hide-covar allow-no-covars cols=a1freq,firth,test,nobs,beta,se,tz,p,err --out g0
#   plink2 --pfile g --pheno t/data/popgen.pheno.tsv --pheno-name quant --covar t/data/popgen.pheno.tsv \
#     --covar-name age,pop --covar-variance-standardize --glm omit-ref hide-covar cols=... --out gc
#
# t/data/popgen_reference.py computed the same values from the two files
# without PLINK, from the formulas each command cites (its header names them),
# under numpy 2.5.2, scipy 1.18.1 and statsmodels 0.14.6 on 2026-11-17. It
# agreed with PLINK 2 to every figure PLINK 2 printed for the Hudson and Weir
# and Cockerham Fst, the Hardy-Weinberg counts, p and mid-p, the unphased and
# phased r^2 and D', the PCA's eigenvalues, and every linear regression. The
# logistic regression at 16:30000330 differed in its fifth figure: statsmodels'
# Logit gave a standard error of 0.698398 and p of 1.4788e-05, where PLINK 2
# gave 0.698389 and 1.47841e-05; the coefficients agreed (3.025338 against
# 3.02534). Where the reference differs from PLINK 2 in method, as in signing
# D', its header says so.
#
# PLINK 2 prints 6 significant figures. Another build of PLINK 2 could round
# one differently, so a value is compared within 2e-5 of its size, two units in
# the sixth figure of a value that begins with a 1; the same build gives the
# same figures. A principal component's sign is arbitrary, and is compared up
# to sign.

my $vcf = catfile($FindBin::Bin, 'data', 'popgen.vcf');
my $pheno = catfile($FindBin::Bin, 'data', 'popgen.pheno.tsv');
my $dir = tempdir(CLEANUP => 1);
sub close_to {
	my ($got, $want, $name) = @_;
	return ok(!defined $got, "$name is undef") unless defined $want;
	ok defined $got && abs($got - $want) <= 2e-5 * abs($want), "$name is $want" or diag 'got ' . ($got // 'undef');
}
sub dies_like {
	my ($code, $re, $name) = @_;
	eval { $code->(); 1 } and return fail($name);
	like $@, $re, $name;
}
my (%pop, @rows); # sample => population; the phenotype file's rows, as hashes
{
	open my $fh, '<', $pheno or die "$pheno: $!";
	chomp(my $head = <$fh>);
	my @cols = split /\t/, $head;
	while (my $line = <$fh>) {
		chomp $line;
		my %row;
		@row{@cols} = split /\t/, $line;
		push @rows, \%row;
		$pop{ $row{'#IID'} } = $row{pop};
	}
	close $fh;
}
is scalar @rows, 60, 'the phenotype file has its 60 people';
# A file of the given lines of t/data/popgen.vcf, its header kept, with $edit
# applied to each record.
sub vcf_with {
	my ($name, $keep, $edit) = @_;
	open my $in, '<', $vcf or die "$vcf: $!";
	my $file = catfile($dir, $name);
	open my $out, '>', $file or die "$file: $!";
	my $n = 0;
	while (my $line = <$in>) {
		if ($line !~ /\A#/) {
			next unless $keep->(++$n);
			$line = $edit->($line) if $edit;
		}
		print {$out} $line;
	}
	close $in;
	close $out or die "$file: $!";
	$file;
}

#  pca

{
	my $p = pca(vcf => $vcf, n => 3);
	is_deeply [sort keys %{ $p }], [qw(eigenvalues samples variants)], 'pca: the fields returned';
	is $p->{variants}, 270, 'pca: every variant is read';
	is scalar @{ $p->{eigenvalues} }, 3, 'pca: n => 3 gives 3 eigenvalues';
	close_to $p->{eigenvalues}[$_], (10.7888, 6.01183, 5.40098)[$_], 'pca: eigenvalue ' . ($_ + 1) foreach 0 .. 2;
	is scalar keys %{ $p->{samples} }, 60, 'pca: every sample has its components';
	my %want = (NA06984 => [-0.0847253, -0.0160094, 0.0837411], NA18486 => [0.189547, 0.0719208, 0.0741194],
		NA18525 => [-0.091873, -0.0839138, 0.0968328]);
	# each component's sign taken from NA18486, whose components are all far from 0
	my @sign = map { $p->{samples}{NA18486}[$_] * $want{NA18486}[$_] < 0 ? -1 : 1 } 0 .. 2;
	foreach my $s (sort keys %want) {
		close_to $sign[$_] * $p->{samples}{$s}[$_], $want{$s}[$_], "pca: $s PC" . ($_ + 1) foreach 0 .. 2;
	}
	is scalar @{ pca(vcf => $vcf)->{eigenvalues} }, 10, 'pca: 10 components by default, as PLINK 2 has';
}

#  fst

{
	my $f = fst(vcf => $vcf, populations => \%pop);
	is_deeply [sort keys %{ $f }], [qw(fst method populations variants)], 'fst: the fields returned';
	is $f->{method}, 'hudson', 'fst: Hudson by default';
	is_deeply $f->{populations}, { CEU => 20, CHB => 20, YRI => 20 }, 'fst: each population\'s samples';
	ok exists $f->{variants} && !defined $f->{variants}, 'fst: no variants without per_variant';
	my %hudson = (CEU => { CHB => 0.10763, YRI => 0.170396 }, CHB => { YRI => 0.179347 });
	foreach my $x (sort keys %hudson) {
		foreach my $y (sort keys %{ $hudson{$x} }) {
			close_to $f->{fst}{$x}{$y}, $hudson{$x}{$y}, "fst: Hudson $x-$y";
			close_to $f->{fst}{$y}{$x}, $hudson{$x}{$y}, "fst: Hudson $y-$x";
		}
	}
	my $w = fst(vcf => $vcf, populations => \%pop, method => 'wc');
	is $w->{method}, 'wc', 'fst: method wc';
	close_to $w->{fst}{CEU}{CHB}, 0.107083, 'fst: Weir and Cockerham CEU-CHB';
	close_to $w->{fst}{CEU}{YRI}, 0.169527, 'fst: Weir and Cockerham CEU-YRI';
	close_to $w->{fst}{CHB}{YRI}, 0.178432, 'fst: Weir and Cockerham CHB-YRI';

	my $v = fst(vcf => $vcf, populations => \%pop, per_variant => 1);
	close_to $v->{fst}{CEU}{CHB}, 0.10763, 'fst: per_variant leaves the pairs\' Fst as they are';
	is scalar @{ $v->{variants}{CEU}{CHB} }, 270, 'fst: per_variant gives each variant of a pair';
	is $v->{variants}{CHB}{CEU}, $v->{variants}{CEU}{CHB}, 'fst: a pair\'s variants are one list both ways round';
	my $first = $v->{variants}{CEU}{CHB}[0];
	is_deeply [@{ $first }{qw(chrom pos id ref alt)}], [1, 30028088, '.', 'A', 'G'], 'fst: a variant is named by its record';
	close_to $first->{fst}, 0.171329, 'fst: CEU-CHB at 1:30028088';
	close_to $v->{variants}{CEU}{CHB}[100]{fst}, 0.0211492, 'fst: CEU-CHB at 11:30001500';

	# PLINK 2 would take a population named by a number as a quantitative
	# value, and one with a space as two fields
	my %odd = (CEU => '1', CHB => '2', YRI => 'Yoruba in Ibadan');
	my $n = fst(vcf => $vcf, populations => { map { $_ => $odd{ $pop{$_} } } keys %pop });
	close_to $n->{fst}{1}{2}, 0.10763, 'fst: populations named "1" and "2"';
	close_to $n->{fst}{2}{'Yoruba in Ibadan'}, 0.179347, 'fst: a population whose name has spaces';

	my %two = map { $pop{$_} eq 'CHB' ? () : ($_ => $pop{$_}) } keys %pop;
	$two{NOBODY} = 'Absent';
	my $t = fst(vcf => $vcf, populations => \%two);
	is_deeply $t->{populations}, { CEU => 20, YRI => 20 },
		'fst: a sample left out of "populations" is left out, and a population with no sample in the VCF is not counted';
	is_deeply [sort keys %{ $t->{fst} }], [qw(CEU YRI)], 'fst: only the pair of the two populations';
	close_to $t->{fst}{CEU}{YRI}, 0.170396, 'fst: CEU-YRI is as it was with CHB there';
	dies_like sub { fst(vcf => $vcf, populations => { NOBODY => 'A', NOONE => 'B' }) },
		qr/^fst: none of the 2 populations of "populations" has a sample in "vcf", and Fst is between two or more/,
		'fst: populations of samples the VCF does not have die';
}

#  hardy_weinberg

{
	my $h = hardy_weinberg(vcf => $vcf);
	is scalar @{ $h }, 270, 'hardy_weinberg: a record for each variant';
	my @fields = qw(alt chrom expected_het het hom_alt hom_ref id observed_het p pos ref);
	is_deeply [sort keys %{ $h->[0] }], \@fields, 'hardy_weinberg: the fields returned';
	# 1:30028088's A1 is its REF, A, and 4:30144820's is its ALT, C, which is
	# the one with a missing genotype
	my %want = (0 => [1, 30028088, 'A', 'G', 13, 23, 24, 0.383333, 0.483194, 0.113585],
		37 => [4, 30144820, 'T', 'C', 38, 18, 3, 0.305085, 0.324045, 0.687286]);
	foreach my $i (sort { $a <=> $b } keys %want) {
		my ($chrom, $pos, $ref, $alt, @n) = @{ $want{$i} };
		is_deeply [@{ $h->[$i] }{qw(chrom pos ref alt hom_ref het hom_alt)}], [$chrom, $pos, $ref, $alt, @n[0 .. 2]],
			"hardy_weinberg: $chrom:$pos genotype counts, REF to ALT";
		close_to $h->[$i]{observed_het}, $n[3], "hardy_weinberg: $chrom:$pos observed_het";
		close_to $h->[$i]{expected_het}, $n[4], "hardy_weinberg: $chrom:$pos expected_het";
		close_to $h->[$i]{p}, $n[5], "hardy_weinberg: $chrom:$pos p";
	}
	my $m = hardy_weinberg(vcf => $vcf, midp => 1);
	close_to $m->[0]{p}, 0.0865626, 'hardy_weinberg: midp at 1:30028088';
	close_to $m->[37]{p}, 0.556988, 'hardy_weinberg: midp at 4:30144820';
}

#  ld

{
	my $l = ld(vcf => $vcf);
	is scalar @{ $l }, 806, 'ld: 806 pairs at r2 0.2 or more within 1000 kb, by default';
	my ($pair) = grep { $_->{a}{chrom} eq '22' } @{ $l };
	is_deeply [sort keys %{ $pair }], [qw(a b dprime r2)], 'ld: the fields returned';
	is_deeply [map { @{ $pair->{$_} }{qw(chrom pos)} } qw(a b)], [22, 20000428, 22, 20003731], 'ld: the first pair on 22';
	close_to $pair->{r2}, 0.287761, 'ld: its r2, of the genotypes';
	ok exists $pair->{dprime} && !defined $pair->{dprime}, 'ld: no dprime unphased';
	is scalar(grep { $_->{a}{chrom} eq '22' } @{ $l }), 573, 'ld: 573 of the pairs on 22';
	my $p = ld(vcf => $vcf, phased => 1);
	is scalar @{ $p }, 792, 'ld: phased, 792 pairs';
	($pair) = grep { $_->{a}{chrom} eq '22' } @{ $p };
	close_to $pair->{r2}, 0.303721, 'ld: phased r2 of the first pair on 22';
	close_to $pair->{dprime}, 1, 'ld: and its dprime';
	# 10 variants on each of 1 to 21 and 60 on 22, each within 1000 kb of the next
	is scalar @{ ld(vcf => $vcf, window => 1, min_r2 => 0) }, 21 * 9 + 59, 'ld: window 1 and min_r2 0 give every adjacent pair';
	my $near = ld(vcf => $vcf, window_kb => 5, min_r2 => 0);
	ok !(grep { $_->{a}{chrom} ne $_->{b}{chrom} || $_->{b}{pos} - $_->{a}{pos} > 5000 } @{ $near }) && @{ $near } > 59,
		'ld: window_kb 5 gives only pairs within 5 kb, and some';
}

#  ld_prune

{
	my $r = ld_prune(vcf => $vcf);
	is_deeply [sort keys %{ $r }], [qw(keep remove)], 'ld_prune: the fields returned';
	is scalar @{ $r->{keep} }, 169, 'ld_prune: 169 kept, with 50 5 0.5';
	is scalar @{ $r->{remove} }, 101, 'ld_prune: 101 removed';
	is_deeply [map { "$_->{chrom}:$_->{pos}" } @{ $r->{remove} }[0 .. 2]], [qw(1:30048912 1:30130464 3:30143604)], 'ld_prune: the first removed';
	my $k = ld_prune(vcf => $vcf, window_kb => 200, r2 => 0.2);
	is_deeply [scalar @{ $k->{keep} }, scalar @{ $k->{remove} }], [114, 156], 'ld_prune: 114 kept and 156 removed with 200kb 1 0.2';
}

#  gwas

{
	my $g = gwas(vcf => $vcf, phenotypes => $pheno, phenotype => 'quant');
	is_deeply [sort keys %{ $g }], [qw(model samples variants)], 'gwas: the fields returned';
	is $g->{model}, 'linear', 'gwas: a quantitative phenotype is tested by linear regression';
	is $g->{samples}, 60, 'gwas: every sample has a phenotype';
	is scalar @{ $g->{variants} }, 270, 'gwas: every variant is tested';
	my @fields = qw(alt alt_freq beta chrom error firth id n p pos ref se stat);
	is_deeply [sort keys %{ $g->{variants}[0] }], \@fields, 'gwas: the fields of a variant';
	my $check = sub {
		my ($v, $name, %want) = @_;
		foreach my $k (sort keys %want) {
			if ($k eq 'n' || $k eq 'firth') {
				is $v->{$k}, $want{$k}, "$name $k";
			} else {
				close_to $v->{$k}, $want{$k}, "$name $k";
			}
		}
		ok !defined $v->{error}, "$name has no error";
	};
	# the phenotype was made up from 11:30001500 (t/data/make_popgen_vcf.pl)
	$check->($g->{variants}[100], 'gwas: quant at 11:30001500', n => 60, alt_freq => 0.141667, beta => 0.940412, se => 0.240544,
		stat => 3.90952, p => 0.000244711, firth => 0);
	$check->($g->{variants}[37], 'gwas: quant at 4:30144820, with a missing genotype', n => 59, alt_freq => 0.20339, beta => -0.0340348,
		se => 0.211518, stat => -0.160908, p => 0.872735);
	my $c = gwas(vcf => $vcf, phenotypes => $pheno, phenotype => 'quant', covariates => [qw(age pop)]);
	$check->($c->{variants}[100], 'gwas: quant at 11:30001500, adjusted for age and pop', n => 60, beta => 0.981827, se => 0.288159,
		stat => 3.40725, p => 0.00123359);

	my $b = gwas(vcf => $vcf, phenotypes => $pheno, phenotype => 'binary');
	is $b->{model}, 'logistic', 'gwas: a phenotype of 1 and 2 is tested by logistic regression';
	$check->($b->{variants}[150], 'gwas: binary at 16:30000330', n => 60, alt_freq => 0.333333, beta => 3.02534, se => 0.698389,
		stat => 4.33188, p => 1.47841e-05, firth => 0);
	$check->($b->{variants}[37], 'gwas: binary at 4:30144820', n => 59, beta => 0.0402096, se => 0.444648, stat => 0.0904301, p => 0.927945);

	# the same phenotype as 0 and 1, from a data frame whose ID column is
	# "#IID", as a file's header gives it
	my @frame = map { { '#IID' => $_->{'#IID'}, y => $_->{binary} - 1 } } @rows;
	my $z = gwas(vcf => $vcf, phenotypes => \@frame, phenotype => 'y');
	is $z->{model}, 'logistic', 'gwas: a phenotype of 0 and 1 is case-control too';
	close_to $z->{variants}[150]{beta}, 3.02534, 'gwas: and its test is the one of 1 and 2';
	is gwas(vcf => $vcf, phenotypes => $pheno, phenotype => 'binary', model => 'linear')->{model}, 'linear', 'gwas: model linear is taken';

	# PLINK 2 takes a column of 0, 1 and 2 as case-control, 0 being missing,
	# whatever is meant; moved up by 5, the same values are plainly
	# quantitative, and the slopes, their errors and p cannot differ
	my @counts = map { { IID => $_->{'#IID'}, y => $_->{age} % 3, y5 => $_->{age} % 3 + 5 } } @rows;
	my ($y, $y5) = map { gwas(vcf => $vcf, phenotypes => \@counts, phenotype => $_) } qw(y y5);
	is $y->{model}, 'linear', 'gwas: a phenotype of 0, 1 and 2 is quantitative';
	is_deeply [map { [@{ $_ }{qw(n beta se p)}] } @{ $y->{variants} }[0 .. 9]], [map { [@{ $_ }{qw(n beta se p)}] } @{ $y5->{variants} }[0 .. 9]],
		'gwas: a phenotype of 0, 1 and 2 is tested as the same one moved up by 5 is, rather than as case-control with its 0s missing';
	is $y->{variants}[0]{n}, 60, 'gwas: its 0s are not taken as missing';

	my $half = gwas(vcf => $vcf, phenotypes => [@rows[0 .. 29]], phenotype => 'quant');
	is $half->{samples}, 30, 'gwas: samples with no row in "phenotypes" are left out';
	is $half->{variants}[0]{n}, 30, 'gwas: and a variant is tested in the rest';
	dies_like sub { gwas(vcf => $vcf, phenotypes => [{ IID => 'NOBODY', y => 1 }, { IID => 'NOONE', y => 2 }], phenotype => 'y') },
		qr/^gwas: none of the 60 samples of "vcf" has a value of "y" in "phenotypes"; check that its IIDs are the VCF's sample names/,
		'gwas: phenotypes of samples the VCF does not have die';
}

#  every function: input and what PLINK 2 is given

{
	# the VCF as a data frame, as Stats::LikeR's read_table gives one: a hash of
	# hashes keyed by CHROM:POS:REF:ALT, each sample's genotype in <sample>.GT
	open my $fh, '<', $vcf or die "$vcf: $!";
	my (@samples, %frame);
	while (my $line = <$fh>) {
		next if $line =~ /\A##/;
		chomp $line;
		my @f = split /\t/, $line;
		if ($line =~ /\A#/) {
			@samples = @f[9 .. $#f];
			next;
		}
		my %row = (CHROM => $f[0], POS => $f[1], ID => $f[2], REF => $f[3], ALT => $f[4]);
		@row{ map { "$_.GT" } @samples } = @f[9 .. $#f];
		$frame{"$f[0]:$f[1]:$f[3]:$f[4]"} = \%row;
	}
	close $fh;
	close_to pca(vcf => \%frame, n => 1)->{eigenvalues}[0], 10.7888, 'pca: a VCF given as a data frame';

	my $prefix = catfile($dir, 'popgen');
	is system($plink2, '--silent', '--vcf', $vcf, '--make-pgen', '--out', $prefix), 0, 'a PLINK 2 fileset of the VCF is made';
	close_to fst(vcf => "$prefix.pgen", populations => \%pop)->{fst}{CEU}{CHB}, 0.10763, 'fst: a PLINK 2 fileset';

	# the sex chromosomes and a multi-allelic record are left out
	my $x = vcf_with('sex.vcf', sub { 1 }, sub {
		my ($line) = @_;
		$line =~ s/\A1\t/X\t/;
		$line =~ s/\A(2\t[0-9]+\t\.\t[ACGT]\t)([ACGT])\t/$1$2,T\t/;
		$line;
	});
	is scalar @{ hardy_weinberg(vcf => $x) }, 250, 'hardy_weinberg: a VCF\'s X and multi-allelic records are left out';
	my $only_x = vcf_with('x.vcf', sub { $_[0] <= 10 }, sub { (my $l = $_[0]) =~ s/\A1\t/X\t/; $l });
	dies_like sub { hardy_weinberg(vcf => $only_x) },
		qr/^hardy_weinberg: "vcf" has no biallelic variant on the autosomes \(1 to 22\), which are all that hardy_weinberg reads/,
		'hardy_weinberg: a VCF of X alone dies';
}

done_testing;
