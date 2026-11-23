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
use Cn::Bioinf qw(sex_check);
# t/data/sex.vcf was written by hand on 2026-10-18. Its four samples are F
# (heterozygous on X), M (mostly hom-ALT), H (haploid calls, as a caller that
# knows a sample is male writes them) and N (no calls on X). Its records hold
# each case sex_check skips (an autosome, X's and Y's PARs on GRCh37 and on
# GRCh38 and their bounds, an indel, a multi-allelic site, an ALT of ".", a
# FORMAT with no GT) and each kind of genotype it counts (phased, haploid,
# triploid, an allele of 2, "./1", a DP below 7, a DP of ".", no DP, GT after
# DP), under chromosomes named chrX, X, 23, chrY, Y and 24, and bases in lower
# case.
#
# The expected counts are what t/data/sex_reference.py, peddy 0.4.3's
# counting loop run through cyvcf2 0.34.0, printed for the same file on
# 2026-10-18 with min_depth 7 and 0; the sexes and het_ratios follow from
# them by peddy's rule (male when x_het / x_hom_alt is below 0.6). On that day
# the script and sex_check also gave identical counts for five genomes, which
# are not in the distribution; they are why peddy's 0.6 is kept, being about
# three times the highest male ratio and a third of the lowest female one:
#
#   genome.vcf.gz    whole genome  x_het 1990, x_hom_alt 68035  0.029 male
#   exome.vcf.bz2    exome         x_het   81, x_hom_alt   784  0.103 male
#   father.vcf.gz    exome         x_het  246, x_hom_alt  1226  0.201 male
#   daughter.vcf.gz  exome         x_het 1514, x_hom_alt   912  1.660 female
#   mother.vcf.gz    exome         x_het 1563, x_hom_alt   913  1.712 female

my $dir = tempdir(CLEANUP => 1);
# sex_check prints its report to STDOUT, which TAP is on too; Test::More has
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
	my $r = $code->();
	open STDOUT, '>&', $save or die $!;
	my $text = printed($file); # scalar context: an empty file is '', not an empty list
	($text, $r);
}
sub warnings_of {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	$code->();
	@w;
}

my $plain = catfile($FindBin::Bin, 'data', 'sex.vcf');
my $vcf = slurp($plain);
sub counts {
	my %c;
	@c{qw(x_het x_hom_alt x_hom_ref x_haploid x_missing y_called y_alt)} = @_;
	\%c;
}
my %want = (
	F => { %{ counts(5, 2, 0, 0, 2, 1, 0) }, het_ratio => 5 / 2, sex => 'female' },
	M => { %{ counts(2, 7, 0, 0, 0, 2, 1) }, het_ratio => 2 / 7, sex => 'male' },
	H => { %{ counts(0, 8, 2, 9, 0, 2, 2) }, het_ratio => 0,     sex => 'male' },
	# differs from peddy, which divides by a hom-ALT count of 0 as if it were 1
	# and so would call N male
	N => { %{ counts(0, 0, 0, 0, 9, 0, 0) }, het_ratio => undef, sex => undef },
);
is_deeply sex_check(vcf => $plain), \%want, 'each sample\'s counts, het_ratio and sex';

# The report is in the VCF's order (F M H N), not sorted (F H M N).
{
	my ($out, $r) = stdout_of(sub { sex_check(vcf => $plain) });
	is $out, "sex_check: $plain\n"
		. "male when het/hom-ALT, over SNVs on X outside its pseudo-autosomal regions, is below 0.6; genotypes of DP below 7 not counted\n"
		. "sample  sex      het/hom-ALT  X het  X hom-ALT  X haploid  X missing  Y called\n"
		. "F       female         2.500      5          2          0          2         1\n"
		. "M       male           0.286      2          7          0          0         2\n"
		. "H       male           0.000      0          8          9          0         2\n"
		. "N       unknown            -      0          0          0          9         0\n"
		. "1 of 4 unknown: no het or hom-ALT call on X\n", 'the report, in file order, with the rule it applied';
	is_deeply $r, \%want, 'and the same hash is returned';
	($out) = stdout_of(sub { sex_check(vcf => $plain, cutoff => 0.25, min_depth => 0) });
	like $out, qr/^male when .+ is below 0\.25; genotypes of DP below 0 not counted$/m, 'the report gives the cutoff and min_depth used';
	($out, $r) = stdout_of(sub { sex_check(vcf => $plain, report => 0) });
	is $out, '', 'report => 0 prints nothing';
	is_deeply $r, \%want, 'and returns the same';
}

my $gz = catfile($dir, 'sex.vcf.gz');
gzip(\$vcf, $gz) or die $GzipError;
is_deeply sex_check(vcf => $gz), \%want, 'a .vcf.gz';
# bgzip writes a series of gzip members, which MultiStream reads on past the first
my $bgz = catfile($dir, 'sex.vcf.bgz');
{
	my $half = index $vcf, "chrX\t3000500";
	my ($first, $second) = (substr($vcf, 0, $half), substr($vcf, $half));
	my ($one, $two);
	gzip(\$first, \$one) or die $GzipError;
	gzip(\$second, \$two) or die $GzipError;
	spew('sex.vcf.bgz', $one . $two);
}
is_deeply sex_check(vcf => $bgz), \%want, 'a .vcf.bgz of two gzip members, read through both';
my $bz2 = catfile($dir, 'SEX.VCF.BZ2');
bzip2(\$vcf, $bz2) or die $Bzip2Error;
is_deeply sex_check(vcf => $bz2), \%want, 'a .vcf.bz2, its suffix in upper case';
(my $crlf = $vcf) =~ s/\n/\r\n/g;
is_deeply sex_check(vcf => spew('crlf.vcf', $crlf)), \%want, 'a VCF with CRLF line ends';

# Every record of sex.vcf starts 10 bytes before a multiple of 64 KiB, the block
# lib/Cn/Bioinf.pm reads in, so that each is split across two blocks, and the
# last has no newline. Filler records on chr1, whose INFO is padded to the
# length needed, put them there.
{
	my ($head, $records) = $vcf =~ /\A(.*?^#CHROM[^\n]*\n)(.*)\z/ms or die 'no #CHROM in sex.vcf';
	my $out = $head;
	foreach my $r (split /^/m, $records) {
		my $gap = (65536 - 10 - length($out) % 65536) % 65536;
		while ($gap) {
			my $fill = "chr1\t1\t.\tA\tG\t.\tPASS\t";
			my $tail = "\tGT\t0/1\t0/1\t0/1\t0/1\n";
			my $room = $gap - length($fill) - length($tail);
			# too little room for a filler line: overshoot to the next block
			$room += 65536 if $room < 1;
			my $info = $room > 2000 ? 2000 : $room;
			$out .= $fill . ('x' x $info) . $tail;
			$gap = (65536 - 10 - length($out) % 65536) % 65536;
		}
		$out .= $r;
	}
	chomp $out;
	is_deeply sex_check(vcf => spew('blocks.vcf', $out)), \%want, 'records that span two blocks, and a last line with no newline';
}

my %deep = map { $_ => { %{ $want{$_} } } } keys %want; # a copy, one level down
@{ $deep{F} }{qw(x_het het_ratio)} = (6, 3);
@{ $deep{M} }{qw(x_hom_alt het_ratio)} = (8, 2 / 8);
@{ $deep{N} }{qw(x_missing y_called y_alt)} = (10, 1, 1);
is_deeply sex_check(vcf => $plain, min_depth => 0), \%deep, 'min_depth 0 counts the genotypes of DP 5, 6 and 2 too';
is sex_check(vcf => $plain, min_depth => 6)->{M}{x_hom_alt}, 8, 'min_depth 6 counts a genotype of DP 6';
is sex_check(vcf => $plain, cutoff => 2 / 7)->{M}{sex}, 'female', 'a het_ratio equal to cutoff is female, as in peddy';
is sex_check(vcf => $plain, cutoff => 3)->{F}{sex}, 'male', 'and one below it male';

{
	my $no_x = spew('no_x.vcf', "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\nchr1\t5\t.\tA\tG\t.\t.\t.\tGT\t0/1\n");
	my $r;
	my @w = warnings_of(sub { $r = sex_check(vcf => $no_x) });
	is_deeply $r, { S => { %{ counts(0, 0, 0, 0, 0, 0, 0) }, het_ratio => undef, sex => undef } }, 'a VCF with no X: every count 0, no sex';
	is scalar(@w), 1, 'and one warning';
	like $w[0], qr/^sex_check: "vcf" \Q$no_x\E has no SNV on X outside its pseudo-autosomal regions, so no sex can be told/, 'which says why';
	my @none = warnings_of(sub { sex_check(vcf => $plain) });
	is scalar(@none), 0, 'and no warning for a VCF with X';
}

# A GT that ends in its separator, "1/" or "0|", has lost its second allele and
# is missing. It used to be read as the haploid call "1": a hom-ALT call on X,
# and counted as haploid. The plain "1" beside it is the haploid call it is not.
{
	my $cut = spew('cut_gt.vcf', "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS\tH\n"
		. join('', map { "chrX\t$_->[0]\t.\tA\tG\t.\t.\t.\tGT\t$_->[1]\t1\n" } [3000000, '1/'], [3000100, '0|'], [3000200, '/1']));
	my $r;
	warnings_of(sub { $r = sex_check(vcf => $cut) });
	is_deeply [@{ $r->{H} }{qw(x_haploid x_hom_alt x_missing)}], [3, 3, 0], 'a haploid "1" on X is counted haploid hom-ALT';
	is_deeply [@{ $r->{S} }{qw(x_haploid x_hom_alt x_hom_ref x_missing)}], [0, 0, 0, 3], '"1/", "0|" and "/1" are missing, not haploid calls';
}

my $hdr = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tA\tB\n";
my $x = "chrX\t3000000\t.\tA\tG\t.\t.\t.\tGT";
foreach my $case (
	["##fileformat=VCFv4.2\n", qr/^vcf_read: .+? has no #CHROM line, so it isn't a VCF/, 'no #CHROM line'],
	["$x\t0/1\t0/1\n$hdr", qr/^vcf_line: .+? line 1 is a record, but no #CHROM line has come before it/, 'a record before #CHROM'],
	["$hdr$hdr", qr/^vcf_header: .+? line 2 is a second #CHROM line/, 'two #CHROM lines'],
	["#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tA\tA\n", qr/^vcf_header: .+? names sample "A" twice in its #CHROM line/, 'a sample named twice, whose name was freed twice on perl 5.32.1 and older'],
	["#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n", qr/^vcf_header: .+? has no samples: its #CHROM line \(line 1\) ends at INFO or before/, 'no FORMAT'],
	["#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\n", qr/^vcf_header: .+? has no samples: its #CHROM line \(line 1\) ends at FORMAT/, 'FORMAT and no samples'],
	["$hdr\nchrX\t3000000\t.\tA\tG\n", qr/^vcf_columns: .+? line 3 has 5 columns, and a record needs 9 and a sample/, 'a record of 5 columns (after an empty line, which is skipped)'],
	["$hdr$x\t0/1\n", qr/^vcf_sample: .+? line 2 has 1 samples, and the #CHROM line names 2/, 'a record of too few samples'],
	["$hdr$x\t0/1\t0/1\t0/1\n", qr/^vcf_samples_end: .+? line 2 has more samples than the 2 its #CHROM line names/, 'a record of too many samples'],
	["${hdr}chrX\t3e6\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/1\n", qr/^vcf_pos: .+? line 2 has POS "3e6", which isn't a position/, 'a POS that is not a whole number'],
	["${hdr}chrX\t\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/1\n", qr/^vcf_pos: .+? line 2 has an empty POS/, 'an empty POS'],
	["${hdr}chrX\t99999999999999999999999\t.\tA\tG\t.\t.\t.\tGT\t0/1\t0/1\n", qr/^vcf_pos: .+? line 2 has POS "99999999999999999999999", which isn't a position/, 'a POS too big for a UV'],
) {
	my ($content, $re, $name) = @{ $case };
	dies_like(sub { sex_check(vcf => spew('bad.vcf', $content)) }, $re, $name);
}
# Found by review on 2026-11-10, and failing against the code of that day: a
# tab at the end of the #CHROM line made a sample named "", and an error
# raised in Bioinf.xs was placed at the line of Cn/Bioinf.pm that called it.
# The period after the line number is optional, since Carp before 1.25 (perl
# 5.12.5's) writes none.
dies_like(sub { sex_check(vcf => spew('tab.vcf', "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tA\t\n$x\t0/1\t\n")) },
	qr/^vcf_header: .+? has an empty sample name in its #CHROM line \(line 1\), column 11; a tab at the end of the line/,
	'a #CHROM line that ends in a tab dies, rather than naming a sample ""');
dies_like(sub { sex_check(vcf => spew('bad.vcf', "$hdr$x\t0/1\n")) }, qr/^vcf_sample: .+? line 2 has 1 samples, and the #CHROM line names 2 at \Q${\ __FILE__}\E line \d+\.?\n\z/,
	"an error raised in Bioinf.xs is placed at the caller's line, not at Cn/Bioinf.pm's");
# a record on another chromosome is not looked at, so a short one cannot die
{
	(my $text = "$hdr$x\t0/1\n") =~ s/chrX/chr1/;
	my $r;
	my @w = warnings_of(sub { $r = sex_check(vcf => spew('chr1.vcf', $text)) });
	is_deeply [sort keys %{ $r }], ['A', 'B'], 'a short record on chr1 is not read';
	is scalar(@w), 1, 'and the VCF is reported as having no X';
}

{
	my ($gzipped, $bzipped);
	gzip(\$vcf, \$gzipped) or die $GzipError;
	bzip2(\$vcf, \$bzipped) or die $Bzip2Error;
	dies_like(sub { sex_check(vcf => spew('cut.vcf.gz', substr($gzipped, 0, length($gzipped) - 20))) },
		qr/^sex_check: can't read .+?cut\.vcf\.gz: unexpected end of file/, 'a truncated .vcf.gz');
	dies_like(sub { sex_check(vcf => spew('cut.vcf.bz2', substr($bzipped, 0, length($bzipped) - 20))) },
		qr/^sex_check: can't read .+?cut\.vcf\.bz2: unexpected end of file/, 'a truncated .vcf.bz2');
	dies_like(sub { sex_check(vcf => spew('plain.vcf.gz', $vcf)) }, qr/^sex_check: can't read .+?plain\.vcf\.gz: /, 'an uncompressed .vcf.gz');
	dies_like(sub { sex_check(vcf => spew('tiny.vcf.gz', 'x')) }, qr/^sex_check: can't read .+?tiny\.vcf\.gz: (?:it isn't gzip-compressed|Header Error: Minimum header size is 10 bytes)/,
		'one too short to hold a gzip header, which IO::Uncompress::Gunzip 2.223 gives no error for, and 2.020 (perl 5.10.1) does');
	dies_like(sub { sex_check(vcf => spew('plain.vcf.bz2', $vcf)) }, qr/^sex_check: can't read .+?plain\.vcf\.bz2: /, 'an uncompressed .vcf.bz2');
}

SKIP: {
	skip 'Test::LeakTrace is not installed', 2 unless eval { require Test::LeakTrace; 1 };
	my $short = spew('short.vcf', "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tA\tB\n$x\t0/1\n");
	Test::LeakTrace::no_leaks_ok(sub { sex_check(vcf => $plain) }, 'sex_check does not leak');
	Test::LeakTrace::no_leaks_ok(sub { eval { sex_check(vcf => $short) } }, 'nor when it dies part-way through the file');
}
done_testing;
