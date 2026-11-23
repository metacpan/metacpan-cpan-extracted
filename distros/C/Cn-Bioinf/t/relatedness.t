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
use Cn::Bioinf qw(parent relatedness sex_check);
# t/data/parent.vcf and the own VCFs t/data/parent.{C,F,S,U}.vcf are
# t/parent.t's, written by t/data/make_parent_vcf.pl, whose header says what
# they hold: a made-up family of seven (F and M the parents of C and S, U
# unrelated, D a second genotyping of C, G the child of C and U).
#
# The counts of every pair, t (sites by the first sample's and the second's
# ALT count, flattened as t[3 * first + second]) and the sites in both files or
# in one alone, are what t/data/parent_reference.py, the independent count
# with cyvcf2 0.34.0 (numpy 2.5.4, Python 3.14.2) behind t/parent.t, printed
# for each pair of the same files on 2026-10-19, at min_depth 10. The other
# fields follow from them as in t/parent.t. The kinships in @Plink are PLINK
# 2.0.0-a.7.13LM's --make-king-table (--vcf-min-dp 10) for every pair of
# t/data/parent.vcf less its "edge" records, run the same day.
#
# The relationships, which sample is the parent, and the categories are the
# family's, as make_parent_vcf.pl draws it, and not what relatedness made of
# the counts. The sexes come from the X records that with_x() below adds, in
# which a male is never het; the counts of each sample are compared with what
# sex_check, which t/sex.t checks against peddy, makes of the same file.
#
# On 2026-10-19 relatedness was also run on peddy's ceph1463.peddy.vcf.gz
# (17 samples of the CEPH 1463 pedigree, three generations; not in the
# distribution) and agreed with its ceph1463.ped on all 17 sexes and on 134 of
# the 136 pairs, each father, mother, son, daughter, brother and sister, and
# which of each parent and child was the parent, included. The other two were
# a grandfather and a grandmother with their grandson NA12893, whose kinships,
# 0.0839 and 0.0799, are below KING's 0.0884 and so third-degree.

my $dir = tempdir(CLEANUP => 1);
# relatedness prints its report to STDOUT, which TAP is on too; Test::More has
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
my @samples = qw(F M C S U D G); # parent.vcf's, in its order

# The pair's hash, from the nine counts of t (t[0] unused) and the three of in.
sub want {
	my ($x, $y, $t, $in) = @_;
	my @t = @{ $t };
	my %s = (in_both => $in->[0], only => { $x => $in->[1], $y => $in->[2] });
	$s{sites} = $in->[0] + $in->[1] + $in->[2];
	$s{ibs0} = $t[2] + $t[6];
	$s{ibs1} = $t[1] + $t[3] + $t[5] + $t[7];
	$s{ibs2} = $t[4] + $t[8];
	$s{het_het} = $t[4];
	$s{het} = { $x => $t[3] + $t[4] + $t[5], $y => $t[1] + $t[4] + $t[7] };
	my ($hx, $hy) = @{ $s{het} }{$x, $y};
	my $min = $hx < $hy ? $hx : $hy;
	$s{kinship} = 0.5 - ($hx + $hy - 2 * $s{het_het} + 4 * $s{ibs0}) / (4 * $min);
	$s{ibs0_rate} = $s{ibs0} / $s{sites};
	$s{undecided} = undef;
	\%s;
}

# ---- one VCF of seven samples

my %one = ( # first, second => t, sites; from parent_reference.py
	'F M' => [[308, 167, 59, 169, 235, 203, 69, 191, 303], 1396],
	'F C' => [[376, 145, 8, 148, 292, 169, 3, 151, 404], 1320],
	'F S' => [[385, 156, 1, 162, 284, 174, 4, 149, 406], 1336],
	'F U' => [[284, 197, 48, 185, 259, 179, 65, 186, 306], 1425],
	'F D' => [[381, 148, 1, 150, 301, 159, 6, 148, 396], 1309],
	'F G' => [[331, 182, 33, 155, 283, 165, 38, 168, 361], 1385],
	'M C' => [[379, 142, 6, 148, 283, 167, 3, 149, 402], 1300],
	'M S' => [[391, 145, 5, 163, 286, 157, 5, 150, 403], 1314],
	'M U' => [[312, 168, 63, 171, 261, 167, 60, 197, 301], 1388],
	'M D' => [[396, 150, 1, 144, 290, 161, 4, 146, 393], 1289],
	'M G' => [[346, 172, 23, 153, 291, 160, 33, 163, 368], 1363],
	'C S' => [[403, 111, 22, 124, 337, 131, 27, 122, 417], 1291],
	'C U' => [[277, 191, 59, 166, 249, 170, 74, 193, 310], 1412],
	'C D' => [[526, 4, 2, 2, 575, 0, 8, 6, 550], 1147],
	'C G' => [[357, 170, 5, 147, 296, 140, 6, 162, 409], 1335],
	'S U' => [[296, 190, 65, 186, 240, 165, 54, 199, 314], 1413],
	'S D' => [[411, 125, 20, 115, 346, 117, 23, 134, 410], 1290],
	'S G' => [[341, 180, 35, 152, 278, 153, 39, 164, 374], 1375],
	'U D' => [[291, 182, 64, 190, 242, 187, 56, 168, 307], 1396],
	'U G' => [[376, 154, 5, 151, 324, 164, 1, 144, 391], 1334],
	'D G' => [[368, 169, 6, 156, 300, 140, 0, 148, 407], 1326],
);
# The family, as make_parent_vcf.pl draws it: each pair's relationship, and
# for a parent and child, the parent. D is C sequenced again, so D's relatives
# are C's.
my %family = (
	'F C' => ['parent-child', 'F'], 'F S' => ['parent-child', 'F'], 'F D' => ['parent-child', 'F'],
	'M C' => ['parent-child', 'M'], 'M S' => ['parent-child', 'M'], 'M D' => ['parent-child', 'M'],
	'C G' => ['parent-child', 'C'], 'D G' => ['parent-child', 'D'], 'U G' => ['parent-child', 'U'],
	'C S' => ['full siblings'], 'S D' => ['full siblings'], 'C D' => ['duplicate'],
	'F G' => ['second-degree'], 'M G' => ['second-degree'], 'S G' => ['second-degree'],
);
$family{$_} //= ['unrelated'] foreach keys %one;

# The category of the pair $x, $y of %family, given each sample's sex (male,
# female or undef), by README.md's words, written afresh.
sub category {
	my ($x, $y, $sex) = @_;
	my ($rel, $parent) = @{ $family{"$x $y"} };
	my %w = (male => [qw(father son)], female => [qw(mother daughter)]);
	if ($rel eq 'parent-child') {
		my $child = $parent eq $x ? $y : $x;
		return ($sex->{$parent} ? $w{ $sex->{$parent} }[0] : 'parent') . '-' . ($sex->{$child} ? $w{ $sex->{$child} }[1] : 'child');
	}
	return $rel unless $rel eq 'full siblings';
	my ($sx, $sy) = @{ $sex }{$x, $y};
	!$sx || !$sy ? 'full siblings' : $sx ne $sy ? 'brother-sister' : $sx eq 'male' ? 'brothers' : 'sisters';
}

# Every pair of $r as %one and %family have it, with the categories that
# %$sex gives.
sub check_family {
	my ($r, $sex, $what) = @_;
	is_deeply [sort keys %{ $r }], [sort @samples], "$what: a key for each sample";
	foreach my $pair (sort keys %one) {
		my ($x, $y) = split ' ', $pair;
		my ($t, $sites) = @{ $one{$pair} };
		my $want = want($x, $y, $t, [$sites, 0, 0]);
		my ($rel, $parent) = @{ $family{$pair} };
		@{ $want }{qw(relationship parent category)} = ($rel, $parent, category($x, $y, $sex));
		is_deeply $r->{$x}{$y}, $want, "$what: $x and $y, $want->{category}" . ($parent ? ", $parent the parent" : '');
		is $r->{$y}{$x}, $r->{$x}{$y}, "$what: and $y and $x are the same hash";
	}
	ok !(grep { exists $r->{$_}{$_} } @samples), "$what: no sample is paired with itself";
}

{
	my ($r, $s) = relatedness($vcf);
	# only C has a call on X, the edge records' 1/1
	check_family($r, { C => 'male' }, 'parent.vcf');
	is_deeply [map { $s->{$_}{sex} } @samples], [undef, undef, 'male', undef, undef, undef, undef], 'the sexes: only C has an X call, and is male';
	is_deeply scalar(relatedness($vcf, report => 0)), $r, 'in scalar context, the pairs alone';
	is_deeply scalar(relatedness(vcf => $vcf, report => 0)), $r, 'and the VCF may be given as "vcf"';
	is_deeply scalar(relatedness(vcf => [$vcf], report => 0)), $r, 'or as an array of one';
	# relatedness counts each pair as parent does
	my $same = 0;
	foreach my $pair (sort keys %one) {
		my ($x, $y) = split ' ', $pair;
		my $p = (parent(vcf => $vcf, child => $x, parent => $y, report => 0))[1];
		my $q = $r->{$x}{$y};
		$same++ if $p->{kinship} == $q->{kinship} && $p->{child_het} == $q->{het}{$x} && $p->{parent_het} == $q->{het}{$y}
			&& $p->{relationship} eq $q->{relationship} && !grep { $p->{$_} != $q->{$_} } qw(sites ibs0 ibs1 ibs2 het_het ibs0_rate);
	}
	is $same, 21, 'every pair as parent counts and decides it';
}
is_deeply((relatedness($vcf, min_depth => 0, report => 0))->{C}{F}, do {
		# t/parent.t's t for child C and parent F, [442, 191, 3, 172, 345, 173, 9,
		# 188, 483], with the two swapped, since F comes first in parent.vcf
		my $w = want('F', 'C', [442, 172, 9, 191, 345, 188, 3, 173, 483], [1564, 0, 0]);
		@{ $w }{qw(relationship parent category)} = ('parent-child', 'F', 'parent-son');
		$w;
	}, 'min_depth 0 counts every genotype');
is relatedness($vcf, max_ibs0 => 0.04, report => 0)->{C}{S}{relationship}, 'parent-child', 'max_ibs0 0.04 takes siblings (IBS0 rate 0.038) for parent and child';

# Kinship on the records PLINK 2 can read, as its --make-king-table gave it.
{
	my $bulk = spew('bulk.vcf', join '', grep { !/\A[^\t]*\t[^\t]*\tedge\t/ } split /^/m, slurp($vcf));
	my @Plink = (['M', 'F', -0.0198145], ['C', 'F', 0.225298], ['C', 'M', 0.223822], ['S', 'F', 0.22326], ['S', 'M', 0.218158], ['S', 'C', 0.203947],
		['U', 'F', 0.0217042], ['U', 'M', 0.00125209], ['U', 'C', -0.0321062], ['U', 'S', -0.0143824], ['D', 'F', 0.238693], ['D', 'M', 0.235068],
		['D', 'C', 0.481337], ['D', 'S', 0.213235], ['D', 'U', -0.00971284], ['G', 'F', 0.107558], ['G', 'M', 0.139073], ['G', 'C', 0.219072],
		['G', 'S', 0.0947684], ['G', 'U', 0.243971], ['G', 'D', 0.232802]);
	my $r = relatedness($bulk, report => 0);
	my @off;
	foreach my $k (@Plink) {
		my ($x, $y, $kin) = @{ $k };
		# PLINK prints 6 significant digits, so it can be half a unit of the 6th out
		my ($exp) = sprintf('%e', $kin) =~ /e([-+][0-9]+)\z/; # of the first digit
		push @off, "$x $y: $r->{$x}{$y}{kinship}, not $kin" unless abs($r->{$x}{$y}{kinship} - $kin) <= 0.5 * 10 ** ($exp - 5);
	}
	is "@off", '', 'the kinship of all 21 pairs is PLINK 2\'s';
}

# ---- sexes, and the categories they give

# $vcf with 100 SNVs on X outside its PARs added, in which a male (by %sex) is
# hom-REF and hom-ALT by turns, and a female het and hom-ALT; a sample not in
# %sex has no call there.
sub with_x {
	my ($name, %sex) = @_;
	my $x = join '', map {
		my $i = $_;
		join("\t", 'chrX', 3000000 + 1000 * $i, '.', 'A', 'G', '.', 'PASS', '.', 'GT',
			map { !$sex{$_} ? './.' : $sex{$_} eq 'male' ? ($i % 2 ? '1/1' : '0/0') : ($i % 2 ? '0/1' : '1/1') } @samples) . "\n";
	} 1 .. 100;
	spew($name, slurp($vcf) . $x);
}
# $file with only the columns of the samples @keep
sub columns {
	my ($file, $name, @keep) = @_;
	my %col = map { $samples[$_] => 9 + $_ } 0 .. $#samples;
	spew($name, join '', map {
		my @f = split /\t/, $_, -1;
		chomp $f[-1];
		/\A##/ ? $_ : join("\t", @f[0 .. 8], @f[@col{@keep}]) . "\n";
	} split /^/m, slurp($file));
}
foreach my $layout (
	['sexes of each kind', F => 'male', M => 'female', C => 'male', S => 'female', U => 'female', D => 'male', G => 'female'],
	['all women but F', F => 'male', M => 'female', C => 'female', S => 'female', U => 'female', D => 'female', G => 'female'],
	['all men', map { $_ => 'male' } @samples],
	['G\'s sex unknown', F => 'male', M => 'female', C => 'male', S => 'female', U => 'female', D => 'male'],
) {
	my ($what, %sex) = @{ $layout };
	my $file = with_x('x.vcf', %sex);
	my ($r, $s) = relatedness($file, report => 0);
	# C's edge records on X are 1/1, so an all-female layout has C het 50 and
	# hom-ALT 52, which is still female
	check_family($r, \%sex, $what);
	is_deeply [map { $s->{$_}{sex} } @samples], [@sex{@samples}], "$what: each sample's sex";
	my $sc = sex_check($file, min_depth => 10, report => 0);
	$_->{file} = $file foreach values %{ $sc };
	is_deeply $s, $sc, "$what: and every count, as sex_check gives them";
}
{
	my $file = with_x('x.vcf', F => 'male', M => 'female', C => 'male', S => 'female', U => 'female', D => 'male', G => 'female');
	# with no third sample to say which is the parent
	my $r = relatedness(columns($file, 'cf.vcf', 'C', 'F'), report => 0);
	is_deeply [sort keys %{ $r }], ['C', 'F'], 'two samples';
	is_deeply [@{ $r->{C}{F} }{qw(relationship category parent)}], ['parent-child', 'father-son', undef], 'two men are father and son, though which is which is unknown';
	$r = relatedness(columns($file, 'cm.vcf', 'C', 'M'), report => 0);
	is_deeply [@{ $r->{C}{M} }{qw(relationship category parent)}], ['parent-child', 'parent-child', undef], 'but a man and a woman may be father and daughter or mother and son';
	$r = relatedness(columns($file, 'cfs.vcf', 'C', 'F', 'S'), report => 0);
	is_deeply [@{ $r->{C}{F} }{qw(category parent)}], ['father-son', 'F'], 'with a sibling, the parent is known';
	$r = relatedness(columns($file, 'cfm.vcf', 'C', 'F', 'M'), report => 0);
	is_deeply [@{ $r->{C}{M} }{qw(category parent)}], ['mother-son', 'M'], 'and with the other parent';
}

# ---- each sample's own VCF

my %two = ( # first, second => t, in; from parent_reference.py
	'C F' => [[0, 165, 3, 155, 292, 151, 8, 169, 404], [1017, 163, 167]],
	'C S' => [[1, 124, 25, 131, 337, 131, 31, 122, 417], [1007, 162, 149]],
	'C U' => [[1, 210, 64, 179, 249, 170, 79, 193, 310], [922, 258, 274]],
	'F S' => [[1, 166, 1, 170, 284, 174, 7, 149, 406], [1014, 176, 167]],
	'F U' => [[1, 211, 53, 194, 259, 179, 73, 186, 306], [931, 266, 264]],
	'S U' => [[1, 205, 71, 199, 240, 165, 61, 199, 314], [918, 260, 276]],
);
{
	my ($r, $s) = relatedness(@own{qw(C F S U)});
	is_deeply [sort keys %{ $r }], [qw(C F S U)], 'own VCFs: a key for each sample';
	foreach my $pair (sort keys %two) {
		my ($x, $y) = split ' ', $pair;
		my $want = want($x, $y, @{ $two{$pair} });
		my ($rel, $parent) = @{ $family{"$x $y"} // $family{"$y $x"} };
		# only C has a call on X, the edge records' 1/1; the others' are 0/0, which
		# their own VCFs leave out
		@{ $want }{qw(relationship parent category)} = ($rel, $parent, $pair eq 'C F' ? 'parent-son' : $rel);
		is_deeply $r->{$x}{$y}, $want, "own VCFs: $x and $y, $rel" . ($parent ? ", $parent the parent" : '');
	}
	is_deeply [map { $s->{$_}{file} } qw(C F S U)], [@own{qw(C F S U)}], 'and each sample\'s file';
	is_deeply scalar(relatedness(vcf => [@own{qw(U S F C)}], report => 0)), $r, 'in another order, and as "vcf"';
	is_deeply scalar(relatedness(@own{qw(C F)}, report => 0))->{C}{F}, do {
			my $w = want('C', 'F', @{ $two{'C F'} });
			@{ $w }{qw(relationship parent category)} = ('parent-child', undef, 'parent-child');
			$w;
		}, 'two own VCFs, with no third to say which is the parent';
	my $gz = catfile($dir, 'C.vcf.gz');
	my $c = slurp($own{C});
	gzip(\$c, $gz) or die $GzipError;
	my $bz2 = catfile($dir, 'F.VCF.BZ2');
	my $f = slurp($own{F});
	bzip2(\$f, $bz2) or die $Bzip2Error;
	my $packed = relatedness($gz, $bz2, @own{qw(S U)}, report => 0);
	is_deeply $packed, $r, 'a .vcf.gz and a .vcf.bz2';
}

# ---- the report

{
	my ($out) = stdout_of(sub { relatedness(@own{qw(C F S U)}) });
	my @f = map { $own{$_} } qw(C F S U);
	my $w = length $f[0];
	is $out, "relatedness: " . join(', ', @f) . "\n"
		. "KING-robust kinship over autosomal biallelic SNVs where either carries the ALT, genotypes of DP below 10 not counted;"
		. " first-degree from 0.177 to 0.354, and of those, parent and child when the IBS0 rate is below 0.012;"
		. " male when het/hom-ALT on X outside its pseudo-autosomal regions is below 0.6\n"
		. "sample  sex      X het/hom-ALT  VCF\n"
		. "C       male             0.000  $f[0]\n"
		. "F       unknown              -  $f[1]\n"
		. "S       unknown              -  $f[2]\n"
		. "U       unknown              -  $f[3]\n"
		. "sample  sample  sites  IBS0 rate  kinship  relationship\n"
		. "C       F        1347     0.0082   0.2140  parent-son (F the parent)\n"
		. "C       S        1318     0.0425   0.1861  full siblings\n"
		. "C       U        1454     0.0983  -0.0535  unrelated\n"
		. "F       S        1357     0.0059   0.2116  parent-child (F the parent)\n"
		. "F       U        1461     0.0862  -0.0040  unrelated\n"
		. "S       U        1454     0.0908  -0.0364  unrelated\n", 'the report of own VCFs';
	($out) = stdout_of(sub { relatedness(columns($vcf, 'cf.vcf', 'C', 'F'), report => 0) });
	is $out, '', 'report => 0 prints nothing';
}

# ---- undecided pairs, and warnings

{
	# as bcftools merge writes VCFs that list only their own variants: "./." for hom-REF
	(my $merged = slurp($vcf)) =~ s{(?<=[\t:])0/0(?=[:\t\n])}{./.}g;
	my $r;
	my @w = warnings_of(sub { $r = relatedness(spew('merged.vcf', $merged), report => 0) });
	is_deeply [map { $r->{C}{$_}{relationship} } qw(F M S U D G)], [undef, undef, undef, undef, undef, undef], 'a VCF with no hom-REF call: every relationship undef';
	like $r->{C}{F}{undecided}, qr/^neither has a hom-REF call where the other carries the ALT, so no opposite homozygote can be seen/, 'and "undecided" says why';
	is $r->{C}{F}{category}, undef, 'as does the category';
	is scalar(@w), 1, 'one warning for all 21 pairs';
	like $w[0], qr/^relatedness: 21 of 21 pairs are undecided, and their relationship undef, such as F and M: neither has a hom-REF call/, 'which counts them';
	my ($out) = stdout_of(sub { warnings_of(sub { relatedness(spew('merged.vcf', $merged)) }) });
	like $out, qr/^F +M +\d+ .*undecided: neither has a hom-REF call/m, 'the report says so too';
	my $hdr = "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT";
	# 999 sites where either carries the ALT, one short
	my $few = spew('few.vcf', "$hdr\tC\tF\n" . join '', map { "1\t$_\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/0\n" } 1 .. 999);
	@w = warnings_of(sub { $r = relatedness($few, report => 0) });
	is $r->{C}{F}{undecided}, '999 sites compared, and 1000 are needed', '999 sites';
	is_deeply [@{ $r->{C}{F} }{qw(sites relationship)}], [999, undef], 'and those sites are still given';
	my $no_het = spew('no_het.vcf', "$hdr\tC\tF\n" . join '', map { "1\t$_\t.\tA\tG\t.\t.\t.\tGT\t" . ($_ % 2 ? '1/1' : '0/0') . "\t0/1\n" } 1 .. 1000);
	@w = warnings_of(sub { $r = relatedness($no_het, report => 0) });
	is_deeply [@{ $r->{C}{F} }{qw(undecided kinship)}], ['C has no het call at the sites compared', undef], 'a sample with no het call: no kinship';
	# 400 more sites in F's alone, as a genome against an exome gives
	my $extra = join '', map { "22\t" . (90000000 + 100 * $_) . "\t.\tA\tG\t.\tPASS\t.\tGT\t0/1\n" } 1 .. 400;
	my $more = spew('F.more.vcf', slurp($own{F}) . $extra);
	@w = warnings_of(sub { $r = relatedness($own{C}, $more, $own{S}, report => 0) });
	isnt $r->{C}{F}{relationship}, 'parent-child', 'with 400 more sites in F\'s VCF alone, C and F are no longer parent and child';
	is scalar(@w), 1, 'and one warning';
	like $w[0], qr/^relatedness: the VCFs of 2 pairs were probably not sequenced over the same regions .*: .+?F\.more\.vcf against .+?parent\.C\.vcf \(567 to 163\), .+?F\.more\.vcf against .+?parent\.S\.vcf \(576 to 167\);/,
		'which names both pairs';
	@w = warnings_of(sub { $r = relatedness(@own{qw(C F S)}, report => 0) });
	is $r->{C}{F}{relationship}, 'parent-child', 'own VCFs of one pipeline';
	is scalar(@w), 0, 'give no warning';
}

# Found by review on 2026-11-10, and failing against the code of that day: as
# in t/parent.t, two VCFs that list every site and differ by 3 sites against 1
# were warned of as an exome against a genome is. The counts are by
# construction.
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
		my $r;
		my @w = warnings_of(sub { $r = relatedness($child, $parent, report => 0) });
		is_deeply [$r->{C}{P}{in_both}, @{ $r->{C}{P}{only} }{qw(C P)}], [$n, $c, $p], "$n sites in both VCFs, $c in C's alone and $p in P's";
		is scalar(@w), $warned, ($warned ? 'warns' : 'does not warn') . " that the two differ in their regions: $why";
	}
}

# ---- what relatedness refuses, once it reads the files

{
	my $hdr = "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT";
	dies_like(sub { relatedness($own{C}) }, qr/^rel_header_one: .+? has 1 sample, and relatedness compares two or more/, 'a VCF of one sample, alone');
	dies_like(sub { relatedness($own{C}, $vcf) }, qr/^rel_header_own: .+?parent\.vcf has 7 samples, and each of several VCFs must have one/, 'a VCF of seven among several');
	my $again = spew('C.again.vcf', slurp($own{C}));
	dies_like(sub { relatedness($own{C}, $again) }, qr/^rel_header_own: .+?parent\.C\.vcf and .+?C\.again\.vcf both name their sample "C"/, 'two VCFs of one sample name');
	dies_like(sub { relatedness($own{C}, spew('no_chrom.vcf', "##fileformat=VCFv4.2\n")) }, qr/^vcf_read: .+? has no #CHROM line, so it isn't a VCF/, 'a file with no #CHROM line');
	dies_like(sub { relatedness(spew('wide.vcf', "$hdr\tC\tF\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/1\t0/1\n")) },
		qr/^vcf_samples_end: .+? line 3 has more samples than the 2 its #CHROM line names/, 'a record with a sample too many');
	dies_like(sub { relatedness(spew('narrow.vcf', "$hdr\tC\tF\nchrX\t3000000\t.\tA\tG\t.\t.\t.\tGT\t0/1\n")) },
		qr/^vcf_sample: .+? line 3 has 1 samples, and the #CHROM line names 2/, 'a record on X with a sample too few');
	dies_like(sub { relatedness($own{C}, spew('own_wide.vcf', "$hdr\tF\nchrY\t5000000\t.\tA\tG\t.\t.\t.\tGT\t1\t1\n")) },
		qr/^vcf_samples_end: .+? line 3 has more samples than the 1 its #CHROM line names/, 'a record on Y with a sample too many, in an own VCF');
}

SKIP: {
	skip 'Test::LeakTrace is not installed', 3 unless eval { require Test::LeakTrace; 1 };
	my $bad = spew('bad.vcf', "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tB\n1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/1\n");
	Test::LeakTrace::no_leaks_ok(sub { relatedness($vcf, report => 0) }, 'relatedness does not leak, with one VCF');
	Test::LeakTrace::no_leaks_ok(sub { relatedness(@own{qw(C F S U)}, report => 0) }, 'nor with own VCFs');
	Test::LeakTrace::no_leaks_ok(sub { eval { relatedness(@own{qw(C F)}, $bad, report => 0) } }, 'nor when it dies part-way through the third file');
}
done_testing;
