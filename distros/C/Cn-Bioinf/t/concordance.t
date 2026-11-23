require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec;
use File::Spec::Functions qw(catfile);
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Compress::Bzip2 qw(bzip2 $Bzip2Error);
use Cn::Bioinf qw(concordance);
# t/data/concordance.truth.vcf and t/data/concordance.test.vcf were written on
# 2026-10-19 by t/data/make_concordance_vcf.pl, whose header says what they
# hold: every one of the 45 kinds of comparison for sample A, a mix of them for
# B, and a sample in each file that the other lacks.
#
# %Want, every count, metric and discordant site of A and B, is what
# t/data/concordance_reference.pl printed for the same files on 2026-10-19: the
# assay_concordance() and metrics() of ~/Scripts/old/x.low_ram_local_concordance.pl,
# copied unchanged but for four corrections to the metrics that the reference
# marks (the true positives, tn_site, tn_genotype, and a discordance of two
# ALT-carrying calls as a false positive and a false negative), applied as
# that script's concordance() applied them. Where that script wrote a missing
# call as "./.", concordance writes ".", since it compares a call's alleles and
# not its string; %Want has "." there.
#
# Below the fixtures, each case where concordance departs from that script on
# purpose says what the script did; their expected values are worked out by
# hand from assay_concordance()'s rules.

my $dir = tempdir(CLEANUP => 1);
# concordance prints its report to STDOUT, which TAP is on too; Test::More has
# its own copy of that handle, made as it loaded, so STDOUT can go elsewhere.
open STDOUT, '>', File::Spec->devnull or die "can't send STDOUT to the null device: $!";
sub spew {
	my ($name, $content) = @_;
	my $f = catfile($dir, $name);
	open my $fh, '>:raw', $f or die $!;
	print {$fh} $content;
	close $fh;
	$f;
}
sub slurp { open my $fh, '<:raw', $_[0] or die "$_[0]: $!"; local $/; <$fh> }
sub dies_like {
	my ($code, $re, $name) = @_;
	eval { $code->(); 1 } and return fail($name);
	like $@, $re, $name;
}
# What was printed through STDOUT to the file $_[0]. STDOUT is opened in text
# mode, so on Windows each "\n" printed is "\r\n" in the file; reading the file
# in text mode too gives "\n" back, which slurp, being :raw, would not.
sub printed { open my $fh, '<', $_[0] or die "$_[0]: $!"; local $/; <$fh> }
# what $code printed to STDOUT, and what it returned
sub stdout_of {
	my ($code) = @_;
	my $file = catfile($dir, 'stdout.txt');
	open my $save, '>&', \*STDOUT or die $!;
	open STDOUT, '>', $file or die $!;
	my @r = $code->();
	open STDOUT, '>&', $save or die $!;
	my $text = printed($file); # scalar context: an empty file is '', not an empty list
	($text, @r);
}
sub warnings_of {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	$code->();
	@w;
}

my $truth = catfile($FindBin::Bin, 'data', 'concordance.truth.vcf');
my $test = catfile($FindBin::Bin, 'data', 'concordance.test.vcf');
my @Kinds = qw(concordant_diploid_ref_to_haploid_ref concordant_haploid_alt concordant_haploid_alt_to_hom_alt
	concordant_haploid_ref concordant_haploid_ref_to_diploid_ref concordant_het_alt concordant_het_ref concordant_hom_alt
	concordant_hom_alt_to_diploid_alt concordant_hom_ref concordant_no_call discordant_haploid_alt_to_haploid_alt
	discordant_haploid_alt_to_haploid_ref discordant_haploid_alt_to_het_alt discordant_haploid_alt_to_het_ref
	discordant_haploid_alt_to_hom_alt discordant_haploid_alt_to_hom_ref discordant_haploid_ref_to_haploid_alt
	discordant_haploid_ref_to_het_alt discordant_haploid_ref_to_het_ref discordant_haploid_ref_to_hom_alt
	discordant_het_alt_to_haploid_alt discordant_het_alt_to_haploid_ref discordant_het_alt_to_het_alt
	discordant_het_alt_to_het_ref discordant_het_alt_to_hom_alt discordant_het_alt_to_hom_ref
	discordant_het_ref_to_haploid_alt discordant_het_ref_to_haploid_ref discordant_het_ref_to_het_alt
	discordant_het_ref_to_het_ref discordant_het_ref_to_hom_alt discordant_het_ref_to_hom_ref
	discordant_hom_alt_to_haploid_alt discordant_hom_alt_to_haploid_ref discordant_hom_alt_to_het_alt
	discordant_hom_alt_to_het_ref discordant_hom_alt_to_hom_alt discordant_hom_alt_to_hom_ref
	discordant_hom_ref_to_haploid_alt discordant_hom_ref_to_het_alt discordant_hom_ref_to_het_ref
	discordant_hom_ref_to_hom_alt gained_site lost_site); # the script's @concordance_types
my @Metrics = qw(fn_genotype fn_site fp_genotype fp_site genotype_concordance precision_genotype precision_site
	recall_genotype specificity_genotype tn_genotype tn_site tp_genotype tp_site recall_site); # the script's @metrics

# from concordance_reference.pl; counts not listed are 0, and each discordance
# is [CHROM, POS, ID, kind, test's call, truth's call]
my %Want = (
	A => {
		counts => {
			concordant_diploid_ref_to_haploid_ref => 1, concordant_haploid_alt => 1,
			concordant_haploid_alt_to_hom_alt => 1, concordant_haploid_ref => 1,
			concordant_haploid_ref_to_diploid_ref => 1, concordant_het_alt => 1, concordant_het_ref => 1,
			concordant_hom_alt => 1, concordant_hom_alt_to_diploid_alt => 1, concordant_hom_ref => 1,
			concordant_no_call => 1, discordant_haploid_alt_to_haploid_alt => 1,
			discordant_haploid_alt_to_haploid_ref => 1, discordant_haploid_alt_to_het_alt => 1,
			discordant_haploid_alt_to_het_ref => 1, discordant_haploid_alt_to_hom_alt => 1,
			discordant_haploid_alt_to_hom_ref => 1, discordant_haploid_ref_to_haploid_alt => 1,
			discordant_haploid_ref_to_het_alt => 1, discordant_haploid_ref_to_het_ref => 1,
			discordant_haploid_ref_to_hom_alt => 1, discordant_het_alt_to_haploid_alt => 1,
			discordant_het_alt_to_haploid_ref => 1, discordant_het_alt_to_het_alt => 1,
			discordant_het_alt_to_het_ref => 1, discordant_het_alt_to_hom_alt => 1,
			discordant_het_alt_to_hom_ref => 1, discordant_het_ref_to_haploid_alt => 1,
			discordant_het_ref_to_haploid_ref => 1, discordant_het_ref_to_het_alt => 1,
			discordant_het_ref_to_het_ref => 1, discordant_het_ref_to_hom_alt => 1,
			discordant_het_ref_to_hom_ref => 1, discordant_hom_alt_to_haploid_alt => 1,
			discordant_hom_alt_to_haploid_ref => 1, discordant_hom_alt_to_het_alt => 1,
			discordant_hom_alt_to_het_ref => 1, discordant_hom_alt_to_hom_alt => 1,
			discordant_hom_alt_to_hom_ref => 1, discordant_hom_ref_to_haploid_alt => 1,
			discordant_hom_ref_to_het_alt => 1, discordant_hom_ref_to_het_ref => 1,
			discordant_hom_ref_to_hom_alt => 1, gained_site => 2, lost_site => 1,
		},
		metrics => {
			fn_genotype => 24, fn_site => 1, fp_genotype => 24, fp_site => 2,
			genotype_concordance => 0.23809523809523808, precision_genotype => 0.20000000000000001,
			precision_site => 0.75, recall_genotype => 0.20000000000000001, recall_site => 0.8571428571428571,
			specificity_genotype => 0.33333333333333331, tn_genotype => 4, tn_site => 4, tp_genotype => 6,
			tp_site => 6,
		},
		discordances => [
			[1, 1110, 'rs11', 'discordant_haploid_alt_to_haploid_alt', '2', '1'],
			[1, 1120, 'rs12', 'discordant_haploid_alt_to_haploid_ref', '0', '1'],
			[1, 1130, 'rs13', 'discordant_haploid_alt_to_het_alt', '1/2', '1'],
			[1, 1140, 'rs14', 'discordant_haploid_alt_to_het_ref', '0/1', '1'],
			[1, 1150, 'rs15', 'discordant_haploid_alt_to_hom_alt', '2/2', '1'],
			[1, 1160, 'rs16', 'discordant_haploid_alt_to_hom_ref', '0/0', '1'],
			[1, 1170, 'rs17', 'discordant_haploid_ref_to_haploid_alt', '1', '0'],
			[1, 1180, 'rs18', 'discordant_haploid_ref_to_het_alt', '1/2', '0'],
			[1, 1190, 'rs19', 'discordant_haploid_ref_to_het_ref', '0/1', '0'],
			[1, 1200, 'rs20', 'discordant_haploid_ref_to_hom_alt', '1/1', '0'],
			[1, 1210, 'rs21', 'discordant_het_alt_to_haploid_alt', '1', '1/2'],
			[1, 1220, 'rs22', 'discordant_het_alt_to_haploid_ref', '0', '1/2'],
			[1, 1230, 'rs23', 'discordant_het_alt_to_het_alt', '1/3', '1/2'],
			[1, 1240, 'rs24', 'discordant_het_alt_to_het_ref', '0/1', '1/2'],
			[1, 1250, 'rs25', 'discordant_het_alt_to_hom_alt', '1/1', '1/2'],
			[1, 1260, 'rs26', 'discordant_het_alt_to_hom_ref', '0/0', '1/2'],
			[1, 1270, 'rs27', 'discordant_het_ref_to_haploid_alt', '1', '0/1'],
			[1, 1280, 'rs28', 'discordant_het_ref_to_haploid_ref', '0', '0/1'],
			[1, 1290, 'rs29', 'discordant_het_ref_to_het_alt', '1/2', '0/1'],
			[1, 1300, 'rs30', 'discordant_het_ref_to_het_ref', '0/2', '0/1'],
			[1, 1310, 'rs31', 'discordant_het_ref_to_hom_alt', '1/1', '0/1'],
			[1, 1320, 'rs32', 'discordant_het_ref_to_hom_ref', '0/0', '0/1'],
			[1, 1330, 'rs33', 'discordant_hom_alt_to_haploid_alt', '2', '1/1'],
			[1, 1340, 'rs34', 'discordant_hom_alt_to_haploid_ref', '0', '1/1'],
			[1, 1350, 'rs35', 'discordant_hom_alt_to_het_alt', '1/2', '1/1'],
			[1, 1360, 'rs36', 'discordant_hom_alt_to_het_ref', '0/1', '1/1'],
			[1, 1370, 'rs37', 'discordant_hom_alt_to_hom_alt', '2/2', '1/1'],
			[1, 1380, 'rs38', 'discordant_hom_alt_to_hom_ref', '0/0', '1/1'],
			[1, 1390, 'rs39', 'discordant_hom_ref_to_haploid_alt', '1', '0/0'],
			[1, 1400, 'rs40', 'discordant_hom_ref_to_het_alt', '1/2', '0/0'],
			[1, 1410, 'rs41', 'discordant_hom_ref_to_het_ref', '0/1', '0/0'],
			[1, 1420, 'rs42', 'discordant_hom_ref_to_hom_alt', '1/1', '0/0'],
			[1, 1430, 'rs43', 'gained_site', '0/1', '.'],
			[1, 1440, 'rs44', 'lost_site', '.', '0/1'],
			[2, 500, 'test_only', 'gained_site', '0/1', '.'],
		],
	},
	B => {
		counts => {
			concordant_haploid_alt => 1, concordant_haploid_ref_to_diploid_ref => 1, concordant_hom_alt => 1,
			concordant_hom_ref => 30, concordant_no_call => 1, discordant_haploid_alt_to_het_alt => 1,
			discordant_haploid_alt_to_hom_ref => 1, discordant_haploid_ref_to_het_ref => 1,
			discordant_het_alt_to_haploid_ref => 1, discordant_het_alt_to_hom_alt => 1,
			discordant_het_ref_to_haploid_ref => 1, discordant_het_ref_to_hom_alt => 1,
			discordant_hom_alt_to_haploid_ref => 1, discordant_hom_alt_to_hom_alt => 1,
			discordant_hom_ref_to_het_alt => 1, gained_site => 2,
		},
		metrics => {
			fn_genotype => 8, fn_site => 0, fp_genotype => 6, fp_site => 2,
			genotype_concordance => 0.76744186046511631, precision_genotype => 0.25, precision_site => 0.5,
			recall_genotype => 0.20000000000000001, recall_site => 1,
			specificity_genotype => 0.93939393939393945, tn_genotype => 31, tn_site => 31, tp_genotype => 2,
			tp_site => 2,
		},
		discordances => [
			[1, 1060, 'rs6', 'discordant_haploid_alt_to_het_alt', '1/2', '1'],
			[1, 1090, 'rs9', 'discordant_haploid_alt_to_hom_ref', '0/0', '1'],
			[1, 1120, 'rs12', 'discordant_haploid_ref_to_het_ref', '0/1', '0'],
			[1, 1150, 'rs15', 'discordant_het_alt_to_haploid_ref', '0', '1/2'],
			[1, 1180, 'rs18', 'discordant_het_alt_to_hom_alt', '1/1', '1/2'],
			[1, 1210, 'rs21', 'discordant_het_ref_to_haploid_ref', '0', '0/1'],
			[1, 1240, 'rs24', 'discordant_het_ref_to_hom_alt', '1/1', '0/1'],
			[1, 1270, 'rs27', 'discordant_hom_alt_to_haploid_ref', '0', '1/1'],
			[1, 1300, 'rs30', 'discordant_hom_alt_to_hom_alt', '2/2', '1/1'],
			[1, 1330, 'rs33', 'discordant_hom_ref_to_het_alt', '1/2', '0/0'],
			[1, 1360, 'rs36', 'gained_site', '0/1', '.'],
			[2, 500, 'test_only', 'gained_site', '1/1', '.'],
		],
	},
);

# A count of every kind, 0 for those not listed.
sub all_counts { my ($c) = @_; +{ map { $_ => $c->{$_} // 0 } @Kinds } }

# The ratios were printed to 17 significant digits, which gives back the same
# double; on a long-double or quadmath perl, concordance's quotient carries more
# digits than that, which differ from the printed value by under 1e-16 of it.
sub metrics_ok {
	my ($got, $want, $name) = @_;
	is_deeply [sort keys %{ $got }], [sort @Metrics], "$name: every metric, and only those";
	my @off = grep { abs($got->{$_} - $want->{$_}) > 1e-15 * abs($want->{$_}) } @Metrics;
	ok !@off, "$name: each metric is the reference's" or diag join ', ', map { "$_: got $got->{$_}, want $want->{$_}" } @off;
}

# Pair $s of result $r, as the reference gave it.
sub pair_ok {
	my ($r, $s, $name) = @_;
	my $w = $Want{$s};
	is_deeply $r->{counts}, all_counts($w->{counts}), "$name: every count";
	metrics_ok($r->{metrics}, $w->{metrics}, $name);
	is_deeply [map { [@{ $_ }{qw(chrom pos id type test truth)}] } @{ $r->{discordances} }], $w->{discordances}, "$name: each discordant, gained and lost site, in the test's order";
}

# ---- the fixtures

my ($report, $r) = stdout_of(sub { concordance(truth => $truth, test => $test) });
is_deeply [sort keys %{ $r }], ['A', 'B'], 'the samples in both files are compared, and D, in the test alone, is not even a key, as the report once made it';
foreach my $s ('A', 'B') {
	pair_ok($r->{$s}, $s, $s);
	is_deeply [@{ $r->{$s} }{qw(test_sample truth_sample sites in_truth)}], [$s, $s, 46, 45], "$s: its names, the test's 46 sites, and the 45 of them in the truth";
	is_deeply [sort keys %{ $r->{$s} }], [sort qw(test_sample truth_sample sites in_truth counts metrics discordances)], "$s: and no other field";
}
is_deeply $r->{A}{discordances}[0], { chrom => 1, pos => 1110, id => 'rs11', ref => 'A', alt => 'G,T,C', type => 'discordant_haploid_alt_to_haploid_alt', test => '2', truth => '1' },
	'a discordance has the site as the test writes it';
like $report, qr/\Aconcordance: test \Q$test\E against truth \Q$truth\E\n/, 'the report names the files';
like $report, qr/^sample +sites +in truth +concordant +discordant +gained +lost +concordance +precision +recall +specificity\n/m, 'and its columns, with no truth sample column when every name matches';
like $report, qr/^B +46 +45 +34 +10 +2 +0 +0\.7674 +0\.2500 +0\.2000 +0\.9394\n^A +46 +45 +11 +32 +2 +1 +0\.2381 +0\.2000 +0\.2000 +0\.3333\n/m, 'and a row for each sample, in the test\'s order';
like $report, qr/^1 of the test's 3 samples are not in the truth: D\n\z/m, 'and the test\'s sample that the truth lacks';
{
	my ($text, $q) = stdout_of(sub { concordance(truth => $truth, test => $test, report => 0, discordances => 0) });
	is $text, '', 'report => 0 prints nothing';
	ok exists $q->{A}{discordances} && !defined $q->{A}{discordances}, 'discordances => 0 leaves "discordances" undef';
	is_deeply $q->{A}{counts}, $r->{A}{counts}, 'and counts the same';
}

# The same files compressed, read through IO::Uncompress.
{
	my %packed;
	foreach my $f ($truth, $test) {
		my $base = (File::Spec->splitpath($f))[2];
		gzip($f => ($packed{"$f.gz"} = catfile($dir, "$base.gz"))) or die "gzip: $GzipError";
		bzip2($f => ($packed{"$f.bz2"} = catfile($dir, "$base.bz2"))) or die "bzip2: $Bzip2Error";
	}
	my $q = concordance(truth => $packed{"$truth.gz"}, test => $packed{"$test.bz2"}, report => 0);
	is_deeply $q, $r, 'a .vcf.gz truth and a .vcf.bz2 test give the same';
}

# One sample in each file, under different names, compared whatever they are
# called: A's columns alone, named NA12878 in the truth and run42 in the test.
{
	my %one;
	foreach my $which ([truth => $truth, 'NA12878'], [test => $test, 'run42']) {
		my ($key, $file, $name) = @{ $which };
		my ($col, $text) = (undef, '');
		foreach my $line (split /\n/, slurp($file)) {
			my @f = split /\t/, $line;
			if ($line =~ /^#CHROM/) {
				($col) = grep { $f[$_] eq 'A' } 9 .. $#f;
				$f[$col] = $name;
			}
			$text .= ($line =~ /^##/ ? $line : join("\t", @f[0 .. 8], $f[$col])) . "\n";
		}
		$one{$key} = spew("one.$key.vcf", $text);
	}
	my ($text, $q) = stdout_of(sub { concordance(%one) });
	is_deeply [keys %{ $q }], ['run42'], 'two VCFs of one sample each are compared whatever the samples are called, keyed by the test\'s name';
	is $q->{run42}{truth_sample}, 'NA12878', 'with the truth\'s name in "truth_sample"';
	pair_ok($q->{run42}, 'A', 'one sample each');
	like $text, qr/^sample +truth sample +sites .+\n^run42 +NA12878 +46 /m, 'and the report gives the truth\'s name too';
	unlike $text, qr/not in the truth/, 'and does not call the test\'s sample missing from it';
}

# ---- where concordance departs from the script

my $hdr = "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT";
# concordance of a one-sample truth and test, each given as its records, with
# no report: the counts that are not 0, the discordances' kinds and calls, the
# sample's result, and the warnings, which say when no site was in the truth
sub small {
	my ($truth_rec, $test_rec, %opt) = @_;
	my $t = spew('small.truth.vcf', "$hdr\tS\n$truth_rec");
	my $q = spew('small.test.vcf', "$hdr\tS\n$test_rec");
	my $r;
	my @w = warnings_of(sub { $r = concordance(truth => $t, test => $q, report => 0, %opt)->{S} });
	my %c = map { $_ => $r->{counts}{$_} } grep { $r->{counts}{$_} } keys %{ $r->{counts} };
	(\%c, [map { "$_->{type} $_->{test} $_->{truth}" } @{ $r->{discordances} }], $r, \@w);
}
{
	my ($c) = small("chr1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", "chr1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	is_deeply $c, { concordant_het_ref => 1 }, 'a site whose CHROM has "chr" in both files is found, where the script dropped it from the truth\'s alone and found nothing';
	($c) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", "CHR1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	is_deeply $c, { concordant_het_ref => 1 }, 'and so is one whose CHROM has "CHR" in the test alone';
	($c) = small("1\t5\trs99\tA\tG\t.\t.\t.\tGT\t0/1\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	is_deeply $c, { concordant_het_ref => 1 }, 'and one whose ID differs, where the script took ID as part of the site and found nothing';
	($c) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", "1\t5\t.\tA\tT\t.\t.\t.\tGT\t0/1\n");
	is_deeply $c, { gained_site => 1 }, 'but not one whose ALT differs, which is a no-call in the truth, as in the script';
	($c) = small("1\t5\t.\tA\tG,T\t.\t.\t.\tGT\t0/1\n", "1\t5\t.\tA\tT,G\t.\t.\t.\tGT\t0/2\n");
	is_deeply $c, { gained_site => 1 }, 'nor one whose ALTs are in another order, as in the script';
	($c) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", "1\t6\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	is_deeply $c, { gained_site => 1 }, 'nor one at another POS';
	($c) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", "2\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	is_deeply $c, { gained_site => 1 }, 'nor one on another chromosome';
	($c) = small("1\t05\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	is_deeply $c, { concordant_het_ref => 1 }, 'POS is compared as a number, so "05" is 5';
}
{
	my ($c, $d) = small(
		"1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n1\t6\t.\tA\tG,T\t.\t.\t.\tGT\t2/1\n1\t7\t.\tA\tG\t.\t.\t.\tGT\t0|1\n",
		"1\t5\t.\tA\tG\t.\t.\t.\tGT\t1/0\n1\t6\t.\tA\tG,T\t.\t.\t.\tGT\t1|2\n1\t7\t.\tA\tG\t.\t.\t.\tGT\t1|0\n");
	is_deeply $c, { concordant_het_ref => 2, concordant_het_alt => 1 }, 'a call is its alleles, in either order and phased or not, where the script compared GT strings and died on "1/0" and "0|1"';
	($c, $d) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/0\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t1|0\n");
	is_deeply $d, ['discordant_hom_ref_to_het_ref 1|0 0/0'], 'and a discordance gives the call as GT had it';
	($c) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t.\n1\t6\t.\tA\tG\t.\t.\t.\tGT\t./.\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t./.\n1\t7\t.\tA\tG\t.\t.\t.\tGT\t./.\n");
	is_deeply $c, { concordant_no_call => 2 }, 'a no-call against "." or a site the truth lacks is concordant_no_call, where the script made it discordant_no_call_to_no_call, outside its 45 kinds';
	($c, $d) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n1\t6\t.\tA\tG\t.\t.\t.\tGT\t0/1\n1\t7\t.\tA\tG\t.\t.\t.\tGT\t0/1\n",
		"1\t5\t.\tA\tG\t.\t.\t.\tGT\t./1\n1\t6\t.\tA\tG\t.\t.\t.\tGT\t0/1/1\n1\t7\t.\tA\tG\t.\t.\t.\tDP\t30\n");
	is_deeply $c, { lost_site => 3 }, 'a partly missing call, one of three alleles, and a FORMAT without GT are each a no-call, where the script died on the first two';
	is_deeply $d, ['lost_site . 0/1', 'lost_site . 0/1', 'lost_site . 0/1'], 'and each is given as "."';
}
{
	my $truth_rec = "1\t5\t.\tA\tG\t.\t.\t.\tGT:DP\t0/1:30\n1\t6\t.\tA\tG\t.\t.\t.\tGT:DP\t0/1:9\n";
	my $test_rec = "1\t5\t.\tA\tG\t.\t.\t.\tGT:DP\t0/1:9\n1\t6\t.\tA\tG\t.\t.\t.\tGT:DP\t0/1:10\n";
	my ($c) = small($truth_rec, $test_rec);
	is_deeply $c, { concordant_het_ref => 2 }, 'every genotype is compared by default, whatever its DP, as the script compared them';
	($c) = small($truth_rec, $test_rec, min_depth => 10);
	is_deeply $c, { lost_site => 1, gained_site => 1 }, 'and with min_depth, a genotype of DP below it is a no-call, in the test or the truth';
	($c) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT:DP\t0/1:.\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", min_depth => 10);
	is_deeply $c, { concordant_het_ref => 1 }, 'but a DP of "." or none at all leaves it compared';
}
{
	my ($c, $d, $r) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t1/1\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t1/1\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	is_deeply $c, { concordant_hom_alt => 1, discordant_hom_alt_to_het_ref => 1 }, 'a site the truth lists twice gives its last calls, and one the test lists twice is compared twice, as in the script';
	is_deeply [@{ $r }{qw(sites in_truth)}], [2, 2], 'and each of the test\'s two is in the truth';
	($c) = small('', "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/65535\n");
	is_deeply $c, { gained_site => 1 }, 'an allele of 65535, the most a call holds, is read';
}

# The four corrections to the script's metrics, each on calls that tell the
# corrected set from the script's.
{
	my (undef, undef, $r) = small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/0\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/0\n");
	is_deeply [@{ $r->{metrics} }{qw(tp_site tp_genotype tn_site tn_genotype)}], [0, 0, 1, 1], 'a hom-REF call matched is a true negative alone, where the script counted it as a true positive too';
	($r) = (small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n"))[2];
	is_deeply [@{ $r->{metrics} }{qw(tp_site tp_genotype tn_site)}], [1, 1, 0], 'a het-REF call matched is a true positive, where the script did not count it';
	($r) = (small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/0\n", "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0\n"))[2];
	is_deeply [@{ $r->{metrics} }{qw(tp_site tn_site tn_genotype)}], [0, 1, 1], 'a diploid hom-REF truth called haploid REF is a true negative, where the script took only the reverse as one';
	($r) = (small("X\t5\t.\tA\tG\t.\t.\t.\tGT\t0\nX\t6\t.\tA\tG\t.\t.\t.\tGT\t0\n", "X\t5\t.\tA\tG\t.\t.\t.\tGT\t0\nX\t6\t.\tA\tG\t.\t.\t.\tGT\t1\n"))[2];
	is_deeply [@{ $r->{metrics} }{qw(tn_genotype fp_genotype specificity_genotype)}], [1, 1, 0.5], 'a haploid-REF truth called right counts for specificity, as one called wrong counts against it, where the script gave a specificity of 0';
	($r) = (small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n1\t6\t.\tA\tG\t.\t.\t.\tGT\t0/1\n1\t7\t.\tA\tG\t.\t.\t.\tGT\t0/0\n1\t8\t.\tA\tG\t.\t.\t.\tGT\t0/0\n",
		"1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n1\t6\t.\tA\tG\t.\t.\t.\tGT\t1/1\n1\t7\t.\tA\tG\t.\t.\t.\tGT\t0/0\n1\t8\t.\tA\tG\t.\t.\t.\tGT\t0/1\n"))[2];
	is_deeply [@{ $r->{metrics} }{qw(tp_genotype fp_genotype fn_genotype precision_genotype recall_genotype)}], [1, 2, 1, 1 / 3, 1 / 2],
		'a het-REF truth called hom-ALT is a false positive and a false negative, where the script counted it as neither';
	is $r->{metrics}{specificity_genotype}, 1 / 2, 'but not a false positive for specificity, whose negatives are the reference truths alone';
}

# Many sites, so that the table of them is rebuilt as it grows (it starts at
# 2,048 slots, and is rebuilt when more than half full), with every site found.
{
	my ($t, $q) = ('', '');
	foreach my $i (1 .. 5000) {
		$t .= "1\t$i\t.\tA\tG\t.\t.\t.\tGT\t" . ($i % 3 ? '0/1' : '1/1') . "\n";
		$q .= "1\t$i\t.\tA\tG\t.\t.\t.\tGT\t" . ($i % 5 ? '0/1' : '1/1') . "\n";
	}
	my ($c, $d, $r) = small($t, $q, discordances => 0);
	# 1 to 5000: hom-ALT in the truth at multiples of 3 (1,666), in the test at multiples of 5 (1,000), in both at multiples of 15 (333)
	is_deeply $c, { concordant_het_ref => 5000 - 1666 - 1000 + 333, concordant_hom_alt => 333, discordant_hom_alt_to_het_ref => 1666 - 333, discordant_het_ref_to_hom_alt => 1000 - 333 }, '5,000 sites are each found';
	is $r->{in_truth}, 5000, 'and each is in the truth';
}

# ---- errors and warnings

{
	my $two = spew('two.vcf', "$hdr\tX\tY\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/0\n");
	my $other = spew('other.vcf', "$hdr\tP\tQ\tR\tS\tT\tU\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/0\t0/0\t0/0\t0/0\t0/0\n");
	dies_like sub { concordance(truth => $two, test => $other, report => 0) },
		qr/^conc_header_test: \Q$other\E and the truth share no sample: the test's are "P", "Q", "R", "S", "T" and 1 more, and the truth's "X", "Y"/, 'two VCFs that share no sample, not both of one sample, die, naming some of each';
	my $one = spew('one.vcf', "$hdr\tS\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	dies_like sub { concordance(truth => $two, test => $one, report => 0) }, qr/^conc_header_test: .+ share no sample/, 'and so does one sample against two of other names';
	my @bad = (
		["1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/x\n", qr/^conc_gt: .+ line 3 has GT "0\/x" for sample "S", which isn't a genotype/, 'a GT with a letter'],
		["1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/\n", qr/^conc_gt: .+ line 3 has GT "0\/" for sample "S", which isn't a genotype/, 'a GT that ends in "/"'],
		["1\t5\t.\tA\tG\t.\t.\t.\tGT\t.1\n", qr/^conc_gt: .+ has GT "\.1" for sample "S", which isn't a genotype/, 'a GT of "." and a number run together'],
		["1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/65536\n", qr/^conc_gt: .+ line 3 has GT "0\/65536" for sample "S", whose allele is beyond the 65535 that concordance can compare/, 'an allele above 65535'],
		["1\t5\t.\tA\tG\t.\t.\t.\tGT\n", qr/^vcf_sample: .+ line 3 has 0 samples, and the #CHROM line names 1/, 'a record with no sample'],
		["1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/1\n", qr/^vcf_samples_end: .+ line 3 has more samples than the 1 its #CHROM line names/, 'a record with too many'],
		["1\tfive\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", qr/^vcf_pos: .+ line 3 has POS "five", which isn't a position/, 'a POS that is not a number'],
	);
	foreach my $c (@bad) {
		my ($rec, $re, $name) = @{ $c };
		dies_like sub { small($rec, "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n") }, $re, "$name in the truth dies";
		dies_like sub { small("1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n", $rec) }, $re, "and in the test";
	}
	my $records = spew('records.vcf', "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	dies_like sub { concordance(truth => $records, test => $one, report => 0) }, qr/^vcf_line: \Q$records\E line 1 is a record, but no #CHROM line has come before it/, 'a truth with no #CHROM line dies';
	my $empty = spew('empty.vcf', "##fileformat=VCFv4.2\n");
	dies_like sub { concordance(truth => $one, test => $empty, report => 0) }, qr/^vcf_read: \Q$empty\E has no #CHROM line, so it isn't a VCF/, 'and so does a test with none';
	my $bare = spew('bare.vcf', "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\n");
	dies_like sub { concordance(truth => $bare, test => $one, report => 0) }, qr/^vcf_header: \Q$bare\E has no samples/, 'and a truth with no samples';
	my $plain = spew('plain.vcf.gz', slurp($one));
	dies_like sub { concordance(truth => $plain, test => $one, report => 0) }, qr/^concordance: can't read \Q$plain\E/, 'and a .vcf.gz that is not compressed';

	my @w = warnings_of(sub { concordance(truth => $one, test => spew('none.vcf', "$hdr\tS\n"), report => 0) });
	is scalar(@w), 1, 'a test with no records warns once';
	like $w[0], qr/^concordance: "test" .+none\.vcf has no records, so nothing was compared/, 'saying so';
	@w = warnings_of(sub { concordance(truth => $one, test => spew('elsewhere.vcf', "$hdr\tS\n2\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n3\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n"), report => 0) });
	is scalar(@w), 1, 'a test none of whose sites the truth has warns once';
	like $w[0], qr/^concordance: none of the 2 sites of "test" .+elsewhere\.vcf is in "truth" \Q$one\E, so every call of the test is gained or a no-call; check that the two are of the same genome build/, 'saying so';
	@w = warnings_of(sub { concordance(truth => $truth, test => $test, report => 0) });
	is scalar(@w), 0, 'and the fixtures, which share sites, do not warn';
}

# ---- genome builds, by the headers' ##contig lengths
#
# The lengths are made up: what is tested is that they agree or not, and a
# real build's would say no more. The site, which both files have, shows that
# a call that passes is compared, and that one that dies was not refused for
# sharing no site.
{
	my $site = "1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n";
	my $vcf = sub {
		my ($name, @contig) = @_;
		spew($name, "##fileformat=VCFv4.2\n" . join('', map { "##contig=<$_>\n" } @contig) . "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\n$site");
	};
	my $b1 = $vcf->('b1.vcf', 'ID=chr1,length=1000,assembly=hg19', 'ID=chr2,length=2000,assembly=hg19');
	my $b2 = $vcf->('b2.vcf', 'ID=1,length=1001,assembly=GRCh38', 'ID=2,length=2000,assembly=GRCh38');
	dies_like sub { concordance(truth => $b1, test => $b2, report => 0) },
		qr/^concordance: "test" \Q$b2\E and "truth" \Q$b1\E are on different genome builds: their ##contig lines give 1 as 1001 bases long in the test and 1000 in the truth \(1 of the 2 contigs that both give a length for differ\); the test's header says "GRCh38" and the truth's "hg19", so a POS in one is not the same place in the other/,
		'two VCFs whose ##contig lengths differ die, naming the contig and both builds, where they were compared as if one build';
	my ($text, $r) = stdout_of(sub { concordance(truth => $b1, test => $vcf->('b3.vcf', 'ID=CHR1,length=1000', 'ID=chr2,length=2000'), report => 0) });
	is $r->{S}{counts}{concordant_het_ref}, 1, 'but the same lengths, under "chr" in either case or none, are compared';
	($text, $r) = stdout_of(sub { concordance(truth => $b1, test => $vcf->('b4.vcf'), report => 0) });
	is $r->{S}{counts}{concordant_het_ref}, 1, 'and so is a test with no ##contig lines';
	($text, $r) = stdout_of(sub { concordance(truth => $b1, test => $vcf->('b5.vcf', 'ID=chr1', 'ID=chr3,length=5', 'ID=chr2,length=2000'), report => 0) });
	is $r->{S}{counts}{concordant_het_ref}, 1, 'and one whose differing contig is in it alone, or has no length';
	my $ref = spew('b6.vcf', "##fileformat=VCFv4.2\n##reference=file:///ref/hs38.fa\n##contig=<ID=1,length=7>\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\n$site");
	my $hg19 = spew('b7.vcf', "##fileformat=VCFv4.2\n##reference=file:///ref/ucsc.hg19.fasta\n##contig=<ID=chr1,length=1000>\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\n$site");
	dies_like sub { concordance(truth => $hg19, test => $ref, report => 0) },
		qr/; the test's header says "file:\/\/\/ref\/hs38\.fa" and the truth's "file:\/\/\/ref\/ucsc\.hg19\.fasta", so/,
		'a header with no assembly names its ##reference instead';
	dies_like sub { concordance(truth => $vcf->('b8.vcf', map { "ID=chr$_,length=$_" } 1 .. 5), test => $vcf->('b9.vcf', map { "ID=chr$_,length=${_}0" } 1 .. 5), report => 0) },
		qr/give 1 as 10 bases long in the test and 1 in the truth, 2 as 20 bases long in the test and 2 in the truth, 3 as 30 bases long in the test and 3 in the truth, and 2 more \(5 of the 5 contigs/,
		'and more than 3 differing contigs are counted, not all named';
	# more ##contig lines than fit in one 64 KiB block, gzipped, with the one that
	# differs at the end, so that the header is read across blocks
	my @long = map { "ID=chrUn_$_,length=$_" } 1 .. 4000;
	my $long = $vcf->('b10.vcf', @long, 'ID=chrY,length=50');
	gzip $long => "$long.gz" or die $GzipError;
	cmp_ok -s $long, '>', 2 * 65536, 'the long header spans blocks';
	dies_like sub { concordance(truth => "$long.gz", test => $vcf->('b11.vcf', 'ID=chrY,length=51'), report => 0) },
		qr/^concordance: .+ give Y as 51 bases long in the test and 50 in the truth \(1 of the 1 contigs/, 'and a contig 4,000 lines into a gzipped header is found';
}

# On a 32-bit perl the test's calls for 349,526 samples (12 bytes each a site)
# overflow a size_t at its first 1,024 sites. Without conc_grow()'s check,
# 5.44.0-i686 died with perl's "panic: memory wrap" (2026-10-19), and a perl
# built without usemallocwrap would have allocated too little. A 64-bit perl
# would really allocate the 4.3 GB, so it skips.
SKIP: {
	require Config;
	skip 'a 64-bit perl would allocate 4.3 GB', 1 unless $Config::Config{ptrsize} == 4;
	my $names = join("\t", map { "s$_" } 1 .. 349_526);
	my $calls = join("\t", ('0/1') x 349_526);
	my $many = spew('many.vcf', "$hdr\t$names\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t$calls\n");
	dies_like sub { concordance(truth => $many, test => $many, report => 0) },
		qr/^conc_grow: \Q$many\E has more sites of its 349526 samples compared than this perl can hold \(0 already\)/, '349,526 samples die on a 32-bit perl, naming the function, where Renew() died with "panic: memory wrap"';
}

SKIP: {
	skip 'Test::LeakTrace is not installed', 2 unless eval { require Test::LeakTrace; 1 };
	my $bad = spew('bad.vcf', "$hdr\tA\tB\n1\t1000\t.\tA\tG,T,C\t.\t.\t.\tGT\t0/1\t0/x\n");
	Test::LeakTrace::no_leaks_ok(sub { concordance(truth => $truth, test => $test, report => 0) }, 'concordance does not leak');
	Test::LeakTrace::no_leaks_ok(sub { eval { concordance(truth => $bad, test => $test, report => 0) } }, 'nor when it dies part-way through the truth');
}

done_testing;
