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
use Cn::Bioinf qw(parent);
# t/data/parent.vcf, and the own VCFs t/data/parent.{C,F,S,U}.vcf of four of
# its samples, were written on 2026-10-18 by t/data/make_parent_vcf.pl, whose
# header says what they hold: a made-up family of seven (F and M the parents
# of C and S, U unrelated, D a second genotyping of C, G the child of C and U)
# over 2,000 SNVs, then the records that parent skips or reads specially.
#
# The counts, t (sites by the child's and the parent's ALT count, flattened
# as t[3 * child + parent]) and the sites in both files or in one alone, are
# what t/data/parent_reference.py, an independent count with cyvcf2 0.34.0,
# printed for the same files on 2026-10-18. The other fields follow from them:
# IBS0, IBS1, IBS2 and the het and hom-ALT counts by their definitions, and
# the kinship by KING-robust's between-family formula. That formula, and
# parent's counts, were checked that day against PLINK 2.0.0-a.7.13LM's
# --make-king-table counts (--vcf-min-dp 10), which agreed exactly: on
# t/data/parent.vcf less its "edge" records (which PLINK cannot read), whose
# kinships are frozen below as @Plink, and on two of one family's exomes
# merged by bcftools 1.21 (merge -0, then view -m2 -M2 -v snps), where NSNP,
# HETHET, IBS0, HET1_HOM2, HET2_HOM1 and KINSHIP were 150976, 43728, 458,
# 37170, 39095 and 0.258656 from both.
#
# The decisions are those of README.md: parent and child when the IBS0 rate is
# below max_ibs0 (0.012, peddy 0.4.3's) and the kinship between KING's 0.177
# and 0.354.

my $dir = tempdir(CLEANUP => 1);
# parent prints its report to STDOUT, which TAP is on too; Test::More has its
# own copy of that handle, made as it loaded, so STDOUT can go elsewhere.
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
# what $code printed to STDOUT, and what it returned in list context
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

my $vcf = catfile($FindBin::Bin, 'data', 'parent.vcf');
my %own = map { $_ => catfile($FindBin::Bin, 'data', "parent.$_.vcf") } qw(C F S U);

# The whole returned hash, from the nine counts of t and the three of in, and
# the relationship.
sub want {
	my ($t, $in, $relationship) = @_;
	my @t = @{ $t };
	my %s = (in_both => $in->[0], child_only => $in->[1], parent_only => $in->[2]);
	$s{sites} = $in->[0] + $in->[1] + $in->[2];
	$s{child_ref_parent_alt} = $t[2];
	$s{child_alt_parent_ref} = $t[6];
	$s{ibs0} = $t[2] + $t[6];
	$s{ibs1} = $t[1] + $t[3] + $t[5] + $t[7];
	$s{ibs2} = $t[4] + $t[8];
	$s{het_het} = $t[4];
	$s{child_het} = $t[3] + $t[4] + $t[5];
	$s{parent_het} = $t[1] + $t[4] + $t[7];
	$s{child_hom_alt} = $t[6] + $t[7] + $t[8];
	$s{parent_hom_alt} = $t[2] + $t[5] + $t[8];
	my $min = $s{child_het} < $s{parent_het} ? $s{child_het} : $s{parent_het};
	$s{kinship} = 0.5 - ($s{child_het} + $s{parent_het} - 2 * $s{het_het} + 4 * $s{ibs0}) / (4 * $min);
	$s{ibs0_rate} = $s{ibs0} / $s{sites};
	$s{relationship} = $relationship;
	$s{parent} = $relationship eq 'parent-child' ? 1 : 0;
	\%s;
}

# ---- one VCF of both samples

my %one = ( # child, parent => t, the sites, the relationship
	'C F' => [[376, 148, 3, 145, 292, 151, 8, 169, 404], 1320, 'parent-child'],
	'C M' => [[379, 148, 3, 142, 283, 149, 6, 167, 402], 1300, 'parent-child'],
	'G C' => [[357, 147, 6, 170, 296, 162, 5, 140, 409], 1335, 'parent-child'],
	'C S' => [[403, 111, 22, 124, 337, 131, 27, 122, 417], 1291, 'full siblings'],
	'C D' => [[526, 4, 2, 2, 575, 0, 8, 6, 550], 1147, 'duplicate'],
	'G F' => [[331, 155, 38, 182, 283, 168, 33, 165, 361], 1385, 'second-degree'],
	'C U' => [[277, 191, 59, 166, 249, 170, 74, 193, 310], 1412, 'unrelated'],
);
foreach my $pair (sort keys %one) {
	my ($c, $p) = split ' ', $pair;
	my ($t, $sites, $rel) = @{ $one{$pair} };
	my $want = want($t, [$sites, 0, 0], $rel);
	my ($is, $s) = parent(vcf => $vcf, child => $c, parent => $p);
	is $is, $want->{parent}, "$c and $p: $want->{parent}";
	is_deeply $s, $want, "and every field, $rel";
}
is scalar(parent(vcf => $vcf, child => 'C', parent => 'F')), 1, 'in scalar context, 1 alone';
is scalar(parent(vcf => $vcf, child => 'C', parent => 'U')), 0, 'and 0';
{
	my ($c_f) = (parent(vcf => $vcf, child => 'C', parent => 'F'))[1];
	my ($f_c) = (parent(vcf => $vcf, child => 'F', parent => 'C'))[1];
	is $f_c->{kinship}, $c_f->{kinship}, 'the kinship is the same with child and parent swapped';
	is_deeply [@{ $f_c }{qw(child_alt_parent_ref child_ref_parent_alt child_het parent_het)}], [@{ $c_f }{qw(child_ref_parent_alt child_alt_parent_ref parent_het child_het)}],
		'and the counts of each are swapped';
}
is_deeply((parent(vcf => $vcf, child => 'C', parent => 'F', min_depth => 0))[1], want([442, 191, 3, 172, 345, 173, 9, 188, 483], [1564, 0, 0], 'parent-child'),
	'min_depth 0 counts every genotype');
# t was [133, 68, 2, 51, 103, 55, 4, 64, 154], 501 sites
dies_like(sub { parent(vcf => $vcf, child => 'C', parent => 'F', min_depth => 30) },
	qr/^parent: "C" and "F" of .+? have only 501 autosomal biallelic SNVs of DP 30 or more where either carries the ALT, and 1000 are needed at /,
	'min_depth 30 leaves 501 sites, too few to decide from');
is scalar(parent(vcf => $vcf, child => 'C', parent => 'S', max_ibs0 => 0.04)), 1, 'max_ibs0 0.04 takes siblings (IBS0 rate 0.038) for parent and child';
is scalar(parent(vcf => $vcf, child => 'C', parent => 'F', max_ibs0 => 11 / 1320)), 0, 'and an IBS0 rate equal to max_ibs0 is not below it';

# Kinship on the records PLINK 2 can read, as its --make-king-table gave it.
{
	my $bulk = spew('bulk.vcf', join '', grep { !/\A[^\t]*\t[^\t]*\tedge\t/ } split /^/m, slurp($vcf));
	my @Plink = (['C', 'F', 0.225298], ['C', 'M', 0.223822], ['C', 'S', 0.203947], ['C', 'U', -0.0321062], ['C', 'D', 0.481337], ['G', 'F', 0.107558], ['G', 'C', 0.219072]);
	foreach my $k (@Plink) {
		my ($c, $p, $kin) = @{ $k };
		my $got = (parent(vcf => $bulk, child => $c, parent => $p, report => 0))[1]{kinship};
		# PLINK prints 6 significant digits, so it can be half a unit of the 6th out
		my ($exp) = sprintf('%e', $kin) =~ /e([-+][0-9]+)\z/; # of the first digit
		ok abs($got - $kin) <= 0.5 * 10 ** ($exp - 5), "$c and $p: kinship $got is PLINK 2's $kin";
	}
}

# ---- each sample's own VCF

my %two = ( # child, parent => t, in, the relationship
	'C F' => [[0, 165, 3, 155, 292, 151, 8, 169, 404], [1017, 163, 167], 'parent-child'],
	'F C' => [[0, 155, 8, 165, 292, 169, 3, 151, 404], [1017, 167, 163], 'parent-child'],
	'C S' => [[1, 124, 25, 131, 337, 131, 31, 122, 417], [1007, 162, 149], 'full siblings'],
	'C U' => [[1, 210, 64, 179, 249, 170, 79, 193, 310], [922, 258, 274], 'unrelated'],
);
foreach my $pair (sort keys %two) {
	my ($c, $p) = split ' ', $pair;
	my $want = want(@{ $two{$pair} });
	my ($is, $s) = parent(child => $own{$c}, parent => $own{$p});
	is $is, $want->{parent}, "own VCFs of $c and $p: $want->{parent}";
	is_deeply $s, $want, "and every field, $want->{relationship}";
}
{
	my $want = want(@{ $two{'C F'} });
	my $gz = catfile($dir, 'C.vcf.gz');
	my $c = slurp($own{C});
	gzip(\$c, $gz) or die $GzipError;
	my $bz2 = catfile($dir, 'F.VCF.BZ2');
	my $f = slurp($own{F});
	bzip2(\$f, $bz2) or die $Bzip2Error;
	is_deeply((parent(child => $gz, parent => $bz2))[1], $want, 'a .vcf.gz and a .vcf.bz2');
	(my $crlf = $f) =~ s/\n/\r\n/g;
	is_deeply((parent(child => $own{C}, parent => spew('crlf.vcf', $crlf)))[1], $want, 'a VCF with CRLF line ends');
}

# ---- the report

{
	my ($out, $is, $s) = stdout_of(sub { parent(vcf => $vcf, child => 'C', parent => 'F') });
	is $out, "parent: child C, parent F, in $vcf\n"
		. "parent and child (1): the IBS0 rate, 0.0083, is below 0.012, and kinship 0.2207 is from 0.177 to 0.354, as for first-degree relatives\n"
		. "sites compared     1320  autosomal biallelic SNVs where either carries the ALT, DP 10 or more\n"
		. "IBS0                 11  opposite homozygotes\n"
		. "  child hom-ALT       8  and the parent hom-REF\n"
		. "  child hom-REF       3  and the parent hom-ALT\n"
		. "IBS1                613  one allele shared\n"
		. "IBS2                696  both alleles shared\n"
		. "het in both         292\n"
		. "het                 588  the child's, and 609 the parent's\n"
		. "hom-ALT             581  the child's, and 558 the parent's\n"
		. "kinship          0.2207  KING-robust, between-family\n", 'the report of one VCF';
	is $is, 1, 'and it returns the same';
	($out) = stdout_of(sub { parent(child => $own{C}, parent => $own{F}) });
	like $out, qr/^sites compared +1347 .*\n  in both VCFs +1017\n  in the child's alone +163  the parent taken as hom-REF\n  in the parent's alone +167  the child taken as hom-REF\n/m,
		'the report of own VCFs says where the sites came from';
	($out) = stdout_of(sub { parent(vcf => $vcf, child => 'C', parent => 'S') });
	like $out, qr/^not parent and child \(0\): kinship 0\.2000 is from 0\.177 to 0\.354, as for first-degree relatives, and the IBS0 rate, 0\.0380, is not below 0\.012, so full siblings$/m,
		'siblings';
	($out) = stdout_of(sub { parent(vcf => $vcf, child => 'C', parent => 'D') });
	like $out, qr/^not parent and child \(0\): kinship 0\.4775 is above 0\.354, as for the same person or identical twins, and the IBS0 rate, 0\.0087, is below 0\.012$/m,
		'one person twice';
	($out) = stdout_of(sub { parent(vcf => $vcf, child => 'G', parent => 'F') });
	like $out, qr/^not parent and child \(0\): kinship 0\.\d+ is from 0\.0884 to 0\.177, as for second-degree relatives/m, 'second-degree';
	($out) = stdout_of(sub { parent(vcf => $vcf, child => 'C', parent => 'U', min_depth => 0) });
	like $out, qr/^not parent and child \(0\): kinship -?0\.\d+ is below 0\.0442, as for unrelated people/m, 'unrelated';
	like $out, qr/DP 0 or more$/m, 'and the min_depth used';
	my @r;
	($out, @r) = stdout_of(sub { parent(vcf => $vcf, child => 'C', parent => 'F', report => 0) });
	is $out, '', 'report => 0 prints nothing';
	is $r[0], 1, 'and returns the same';
}

# ---- warnings

{
	my $r;
	my @w = warnings_of(sub { $r = parent(child => $own{C}, parent => $own{F}, report => 0) });
	is $r, 1, 'own VCFs of one pipeline';
	is scalar(@w), 0, 'give no warning';
	# 400 more sites in F's alone, as a genome against an exome gives
	my $extra = join '', map { "22\t" . (90000000 + 100 * $_) . "\t.\tA\tG\t.\tPASS\t.\tGT\t0/1\n" } 1 .. 400;
	my $more = spew('F.more.vcf', slurp($own{F}) . $extra);
	@w = warnings_of(sub { $r = parent(child => $own{C}, parent => $more, report => 0) });
	is $r, 0, 'with 400 more sites in the parent\'s VCF alone, no longer parent and child';
	is scalar(@w), 1, 'and one warning';
	like $w[0], qr/^parent: the parent's VCF has 567 sites that the child's lacks, and the child's only 163 that the parent's lacks, so the two were probably not sequenced over the same regions/,
		'which says why';
	@w = warnings_of(sub { parent(child => $more, parent => $own{C}, report => 0) });
	like $w[0], qr/^parent: the child's VCF has 567 sites that the parent's lacks, and the parent's only 163/, 'and names the child\'s when it is the child\'s';
}

# Found by review on 2026-11-10, and failing against the code of that day: the
# ratio of the sites in each file alone was the whole test, so two VCFs that
# list every site, hom-REF calls included, and differ by 3 sites against 1 were
# warned of as an exome against a genome is. The counts are by construction.
{
	my $hdr = "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT";
	# the child's call and the parent's, in turn: every site has an ALT in one
	# of them, and none is an opposite homozygote
	my @gt = (['0/1', '0/1'], ['0/0', '0/1'], ['1/1', '0/1'], ['0/1', '0/0'], ['0/1', '1/1'], ['1/1', '1/1']);
	# $who's VCF (0 = the child C, 1 = the parent P): $n sites that both list,
	# and $alone of its own, from position $from on chromosome 2
	my $own = sub {
		my ($who, $n, $alone, $from) = @_;
		"$hdr\t" . ('C', 'P')[$who] . "\n"
			. join('', map { "1\t" . (1000 * $_) . "\t.\tA\tG\t.\t.\t.\tGT\t$gt[$_ % @gt][$who]\n" } 1 .. $n)
			. join('', map { "2\t" . ($from + $_) . "\t.\tA\tG\t.\t.\t.\tGT\t0/1\n" } 1 .. $alone);
	};
	foreach my $case (
		# sites in both, in the child's alone, in the parent's alone, warnings, why
		[1200, 3, 1, 0, 'a difference of 2 sites, which chance gives'],
		[1200, 40, 10, 0, 'a difference of 30 sites, under the 50 that chance does not give'],
		[9000, 60, 5, 0, 'a difference of 55 sites that is under 0.9% of the 9,065 compared'],
		[1200, 60, 5, 1, 'a difference of 55 sites that is 4% of the 1,265 compared'],
	) {
		my ($n, $c, $p, $warned, $why) = @{ $case };
		my ($child, $parent) = (spew('own.C.vcf', $own->(0, $n, $c, 1000)), spew('own.P.vcf', $own->(1, $n, $p, 5000)));
		my @r;
		my @w = warnings_of(sub { @r = parent(child => $child, parent => $parent, report => 0) });
		is_deeply [@{ $r[1] }{qw(in_both child_only parent_only)}], [$n, $c, $p], "$n sites in both VCFs, $c in the child's alone and $p in the parent's";
		is scalar(@w), $warned, ($warned ? 'warns' : 'does not warn') . " that the two differ in their regions: $why";
	}
}

# ---- what parent refuses

my $hdr = "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT";
foreach my $case (
	[[child => 'C'], qr/^parent: needs "parent"/, 'no parent'],
	[[child => 'C', parent => 'F', vcf => $vcf, cutoff => 1], qr/^parent: doesn't know "cutoff"/, 'an unknown option'],
	[[child => 'C', parent => 'X', vcf => $vcf], qr/^parent_header_one: .+? has no sample "X"; its samples are "F", "M", "C", "S", "U" and 2 more/, 'a sample the VCF lacks'],
	[[child => 'C', parent => 'C', vcf => $vcf], qr/^parent: "child" and "parent" are both "C"/, 'one sample twice'],
	[[child => $own{C}, parent => $own{C}], qr/^parent: "child" and "parent" are both "\Q$own{C}\E"/, 'one file twice'],
	[[child => ['C'], parent => 'F', vcf => $vcf], qr/^parent: "child" must be a sample name of "vcf", not an ARRAY ref/, 'a sample name that is a ref'],
	[[child => '', parent => 'F', vcf => $vcf], qr/^parent: "child" must be a sample name of "vcf", not ""/, 'an empty sample name'],
	[[child => $vcf, parent => $own{F}], qr/^parent_header_own: .+? has 7 samples, and a VCF given as "child" or "parent" must have one/, 'a VCF of seven samples as "child"'],
	[[child => $own{C}, parent => catfile($dir, 'none.vcf')], qr/^parent: "parent" file ".+?none\.vcf" doesn't exist or isn't readable/, 'a parent file that does not exist'],
	[[child => $own{C}, parent => $own{F} . '.txt'], qr/^parent: "parent" file ".+?" doesn't exist/, 'nor a file name of another suffix'],
	[[child => 'C', parent => 'F', vcf => $vcf, min_depth => -1], qr/^parent: "min_depth" must be a whole number, 0 or more, not "-1"/, 'a negative min_depth'],
	[[child => 'C', parent => 'F', vcf => $vcf, max_ibs0 => 0], qr/^parent: "max_ibs0" must be a number above 0, not "0"/, 'max_ibs0 0'],
	[[child => 'C', parent => 'F', vcf => $vcf, max_ibs0 => 'a'], qr/^parent: "max_ibs0" must be a number above 0, not "a"/, 'max_ibs0 not a number'],
	[[child => 'C', parent => 'F', vcf => $vcf, report => 2], qr/^parent: "report" must be 0 or 1, not "2"/, 'report 2'],
) {
	my ($args, $re, $name) = @{ $case };
	dies_like(sub { parent(@{ $args }) }, $re, $name);
}
{
	my $txt = spew('parent.txt', slurp($own{F}));
	dies_like(sub { parent(child => $own{C}, parent => $txt) }, qr/^parent: "parent" file .+?parent\.txt must end in \.vcf, \.vcf\.gz, \.vcf\.bgz or \.vcf\.bz2/, 'a VCF named .txt');
	dies_like(sub { parent(child => $own{C}, parent => spew('no_chrom.vcf', "##fileformat=VCFv4.2\n")) }, qr/^vcf_read: .+? has no #CHROM line, so it isn't a VCF/, 'a file with no #CHROM line');
	# where a UV is 32 bits (5.44.0-i686 here), vcf_pos refuses it first
	dies_like(sub { parent(child => $own{C}, parent => spew('big_pos.vcf', "$hdr\tF\n1\t4294967296\t.\tA\tG\t.\t.\t.\tGT\t0/1\n")) },
		qr/^(?:parent_record_own: .+? line 3 has POS 4294967296, beyond the 4294967295 that parent can compare|vcf_pos: .+? line 3 has POS "4294967296", which isn't a position)/,
		'a POS beyond 32 bits, in an own VCF');
	dies_like(sub { parent(child => $own{C}, parent => spew('short.vcf', "$hdr\tF\n1\t5\t.\tA\tG\t.\t.\t.\tGT\n")) },
		qr/^vcf_sample: .+? line 3 has 0 samples, and the #CHROM line names 1/, 'a record with no sample, in an own VCF');
	dies_like(sub { parent(vcf => spew('wide.vcf', "$hdr\tC\tF\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/1\t0/1\n"), child => 'C', parent => 'F') },
		qr/^vcf_samples_end: .+? line 3 has more samples than the 2 its #CHROM line names/, 'a record with a sample too many, in one VCF');
	# 999 sites where either carries the ALT, one short
	my $few = spew('few.vcf', "$hdr\tC\tF\n" . join '', map { "1\t$_\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/0\n" } 1 .. 999);
	dies_like(sub { parent(vcf => $few, child => 'C', parent => 'F') }, qr/^parent: "C" and "F" of .+? have only 999 autosomal biallelic SNVs of DP 10 or more where either carries the ALT, and 1000 are needed at /,
		'999 sites');
	my $few_c = spew('few_c.vcf', "$hdr\tC\n" . join '', map { "1\t$_\t.\tA\tG\t.\t.\t.\tGT\t0/1\n" } 1 .. 999);
	my $one_f = spew('one_f.vcf', "$hdr\tF\n2\t5\t.\tA\tG\t.\t.\t.\tGT\t0/0\n");
	dies_like(sub { parent(child => $few_c, parent => $one_f) }, qr/^parent: .+? and .+? have only 999 .+ and 1000 are needed; if the files share few sites, check that they are of the same genome build/,
		'and with own VCFs, a hint about builds');
	# as bcftools merge writes VCFs that list only their own variants: "./." for hom-REF
	(my $merged = slurp($vcf)) =~ s{(?<=[\t:])0/0(?=[:\t\n])}{./.}g;
	dies_like(sub { parent(vcf => spew('merged.vcf', $merged), child => 'C', parent => 'F') },
		qr/^parent: neither of "C" and "F" of .+? has a hom-REF call where the other carries the ALT, so no opposite homozygote can be seen/, 'a VCF with no hom-REF call');
	my $no_het = spew('no_het.vcf', "$hdr\tC\tF\n" . join '', map { "1\t$_\t.\tA\tG\t.\t.\t.\tGT\t" . ($_ % 2 ? '1/1' : '0/0') . "\t0/1\n" } 1 .. 1000);
	dies_like(sub { parent(vcf => $no_het, child => 'C', parent => 'F') }, qr/^parent: the child of "C" and "F" of .+? has no het call at the sites compared, so no kinship can be taken/,
		'a child with no het call');
}

SKIP: {
	skip 'Test::LeakTrace is not installed', 3 unless eval { require Test::LeakTrace; 1 };
	my $bad = spew('bad.vcf', "$hdr\tF\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/1\n");
	Test::LeakTrace::no_leaks_ok(sub { parent(vcf => $vcf, child => 'C', parent => 'F', report => 0) }, 'parent does not leak, with one VCF');
	Test::LeakTrace::no_leaks_ok(sub { parent(child => $own{C}, parent => $own{F}, report => 0) }, 'nor with own VCFs');
	Test::LeakTrace::no_leaks_ok(sub { eval { parent(child => $own{C}, parent => $bad, report => 0) } }, 'nor when it dies part-way through the second file');
}
done_testing;
