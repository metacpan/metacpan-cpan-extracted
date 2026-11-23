require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Temp qw(tempdir);
use File::Spec;
use File::Spec::Functions qw(catfile);
use Digest::SHA ();
use Cn::Bioinf qw(fasta_index fasta_region fasta2hash);
# fasta_index and fasta_region. Every expected value is htslib's or
# samtools's, checked on 2026-11-11:
#
# - htslib 1.25, test/faidx: t/data/faidx.fa is its faidx.fa, the index
#   expected of it is its faidx.fa.expected.fai, and the first regions fetched
#   are those of the "Fasta retrieval tests" in its faidx.tst, with the
#   sequences of its faidx.1.expected.fa. The lengths are the ones that file's
#   faidx_seq_len tests expect. t/data/faidx_reference.pl gives the notice
#   those files are distributed under.
# - samtools 1.19.2 (htslib 1.19): what "samtools faidx" printed for the other
#   regions, and how it took each file that cannot be indexed.
#   t/data/faidx_reference.pl runs it and prints both.
# - fai_build_core() of htslib's faidx.c (state IN_NAME), read on 2026-11-18
#   in the source at ~/prog/htslib (1.21-34-gb14fffb4): a name ends at any
#   byte that isspace() takes, '\v' among them.
# - By construction, for the file larger than one of Bioinf.xs's 64 KiB
#   FASTA_BLOCK reads (since 2026-11-18, when the scan moved to Bioinf.xs):
#   its offsets are counted from the lengths it is built of, and its
#   sequences checked against what fasta2hash reads.

my $dir = tempdir(CLEANUP => 1);
sub spew {
	my ($name, $content) = @_;
	my $f = catfile($dir, $name);
	open my $fh, '>:raw', $f or die "$f: $!";
	print {$fh} $content;
	close $fh or die "$f: $!";
	$f;
}
sub slurp {
	open my $fh, '<:raw', $_[0] or die "$_[0]: $!";
	local $/;
	my $all = <$fh>;
	close $fh;
	$all;
}
sub warnings_of {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	$code->();
	@w;
}
sub dies_like {
	my ($code, $re, $name) = @_;
	eval { $code->(); 1 } and return fail($name);
	like $@, $re, $name;
}
# What $code prints to STDOUT, which fasta_index writes "wrote" on
sub stdout_of {
	my ($code) = @_;
	my $said = catfile($dir, 'said.txt');
	open my $saved, '>&', \*STDOUT or die $!;
	open STDOUT, '>', $said or die $!;
	$code->();
	close STDOUT;
	open STDOUT, '>&', $saved or die $!;
	# Read in text mode, as STDOUT wrote it: on Windows each "\n" printed is
	# "\r\n" in the file, which slurp, being :raw, would hand back as it is.
	open my $fh, '<', $said or die "$said: $!";
	local $/;
	my $all = <$fh>;
}

# The fixture has a part with CRLF line endings, and its offsets are bytes, so
# a checkout that rewrote its line endings would fail everything below.
my $source = catfile($FindBin::Bin, 'data', 'faidx.fa');
is Digest::SHA::sha256_hex(slurp($source)), '1eb079facd2a271e5cd68d962996996a65cfe42307be45a2d4abcfe1403edd8b',
	"t/data/faidx.fa is htslib's file, byte for byte";
my $fa = spew('faidx.fa', slurp($source));

#  with no index file, which is read from the FASTA itself

# htslib: the "Fasta retrieval tests"
is_deeply fasta_region($fa, 'trailingblank2:28-33', 'trailingblank3:4-5', 'bar:4-5'),
	{ 'trailingblank2:28-33' => 'GGGCCC', 'trailingblank3:4-5' => 'TA', 'bar:4-5' => 'TA' }, "htslib's three regions, with no index file";
ok !-e "$fa.fai", 'and none was written';

#  fasta_index

my $fai;
my $said = stdout_of(sub { $fai = fasta_index($fa) });
is $fai, "$fa.fai", 'fasta_index returns the name of the index, the FASTA with .fai';
is $said, "wrote $fai\n", 'and says that it wrote it';
# htslib: faidx.fa.expected.fai. The first sequence has no name; the third has
# CRLF line endings, so its lines are 4 bases in 6 bytes; and "  foo" and
# " bar description" are named by their first word.
is slurp($fai), join('', map { "$_\n" }
	"\t4\t2\t4\t5", "trailingblank1\t33\t23\t12\t13", "trailingblank2\t72\t111\t24\t25", "trailingblank3\t5\t234\t4\t6",
	"foo\t8\t252\t6\t7", "bar\t8\t280\t8\t9"), "the index is htslib's, byte for byte";

#  fasta_region with the index file

is_deeply fasta_region($fa, 'trailingblank2:28-33', 'trailingblank3:4-5', 'bar:4-5'),
	{ 'trailingblank2:28-33' => 'GGGCCC', 'trailingblank3:4-5' => 'TA', 'bar:4-5' => 'TA' }, "htslib's three regions, from the index file";
# htslib: faidx_seq_len expects 33, and faidx_seq_len64 72
is length fasta_region($fa, 'trailingblank1')->{trailingblank1}, 33, 'trailingblank1 is 33 bases';
is length fasta_region($fa, 'trailingblank2')->{trailingblank2}, 72, 'trailingblank2 is 72';
# samtools faidx: each region and the sequence it printed
my %samtools = (
	'foo' => 'TGCATGCA',
	'trailingblank1' => 'AAATTTGGGCCCTTTGGGCCCAAAGGGCCCAAA',
	'trailingblank1:30-99' => 'CAAA', # cut short at the end, where samtools says "Truncated sequence"
	'trailingblank1:3' => 'ATTTGGGCCCTTTGGGCCCAAAGGGCCCAAA', # from 3 to the end
	'trailingblank1:3-' => 'ATTTGGGCCCTTTGGGCCCAAAGGGCCCAAA',
	'trailingblank1:-4' => 'AAAT', # from the start to 4
	'trailingblank2:1,0-1,2' => 'CCC', # commas in the numbers: 10 to 12
	'trailingblank1:33-33' => 'A', # the last base
	'trailingblank1:34' => '', # starts past the end
	'trailingblank1:40-50' => '',
	'bar:8-9' => 'A',
);
is_deeply fasta_region($fa, sort keys %samtools), \%samtools, "eleven regions as samtools faidx prints them";
is_deeply fasta_region($fa, ''), { '' => 'ATGC' }, 'the sequence with no name is asked for by none';
is_deeply fasta_region($fa, 'foo', 'foo', 'bar'), { foo => 'TGCATGCA', bar => 'TTTTAAAA' }, 'a region asked for twice is returned once';
# Every range of every sequence, against the sequence that fasta2hash reads.
# fasta2hash refuses a defline with no name, so it is given the file without
# its first sequence, which is ">" and "ATGC".
my $whole = fasta2hash(spew('named.fa', substr slurp($source), 7));
my %by_name = map { (split ' ', $_)[0] => $whole->{$_} } keys %{ $whole };
my $mismatch = 0;
foreach my $name (sort keys %by_name) {
	my $s = $by_name{$name};
	foreach my $i (1 .. length $s) {
		foreach my $j ($i .. length $s) {
			$mismatch++ unless fasta_region($fa, "$name:$i-$j")->{"$name:$i-$j"} eq substr $s, $i - 1, $j - $i + 1;
		}
	}
}
is_deeply [sort keys %by_name], [qw(bar foo trailingblank1 trailingblank2 trailingblank3)], 'fasta2hash reads the five sequences that have names';
is $mismatch, 0, 'and every range of each is the same part of what it reads';

# samtools exits 1 on these two; it prints an empty sequence for a start of 0,
# which here dies as well, since no base is numbered 0
dies_like(sub { fasta_region($fa, 'absent') }, qr/^fasta_region: \Q$fa\E has no sequence named "absent"/, 'a name that is not there dies');
dies_like(sub { fasta_region($fa, 'trailingblank1:5-3') }, qr/^fasta_region: the region "trailingblank1:5-3" ends before it starts/, 'a region that ends before it starts dies');
dies_like(sub { fasta_region($fa, 'trailingblank1:0-3') }, qr/^fasta_region: the region "trailingblank1:0-3" starts at 0/, 'a start of 0 dies, where samtools prints nothing');
dies_like(sub { fasta_region($fa, 'absent:1-2') }, qr/has no sequence named "absent:1-2", nor is it a range of one/, 'a range of a name that is not there dies');

# A name with a colon in it is taken whole when it is a sequence's name, as
# htslib's hts_parse_region() takes it, and a range of it can still be asked for
my $hla = spew('hla.fa', ">HLA-A*01:01:01:01 the allele\nACGTACGT\n>chr1:5\nTTTTGGGG\n");
is_deeply fasta_region($hla, 'HLA-A*01:01:01:01', 'HLA-A*01:01:01:01:2-4', 'chr1:5', 'chr1:5:5-6'),
	{ 'HLA-A*01:01:01:01' => 'ACGTACGT', 'HLA-A*01:01:01:01:2-4' => 'CGT', 'chr1:5' => 'TTTTGGGG', 'chr1:5:5-6' => 'GG' },
	'a name with colons in it, and a range of one';

#  an index that no longer describes the file

# the times are set, rather than waited for: the index a day older than the FASTA
my $now = time;
utime $now - 86400, $now - 86400, $fai or die "can't set the times of $fai: $!";
utime $now, $now, $fa or die "can't set the times of $fa: $!";
my @w = warnings_of(sub { is fasta_region($fa, 'bar:4-5')->{'bar:4-5'}, 'TA', 'an index older than its FASTA is still used' });
is scalar @w, 1, 'with one warning';
like $w[0], qr/^fasta_region: \Q$fai\E is older than \Q$fa\E, and may no longer describe it/, 'that says so, as htslib does';
utime $now, $now, $fai or die "can't set the times of $fai: $!";
@w = warnings_of(sub { is fasta_region($fa, 'bar:4-5')->{'bar:4-5'}, 'TA', 'an index as new as its FASTA' });
is scalar @w, 0, 'is not warned about';
my $short = spew('short.fa', ">a\nACGT\n");
spew('short.fa.fai', "a\t400\t3\t60\t61\n");
dies_like(sub { fasta_region($short, 'a:100-200') }, qr/^fasta_region: the index gives "a" 200 bases, and \Q$short\E has fewer where it says they are; \Q$short\E\.fai doesn't describe this file/,
	'an index of another file dies, rather than returning what bases there are');
spew('short.fa.fai', "a\t4\t3\n");
dies_like(sub { fasta_region($short, 'a') }, qr/^fasta_region: line 1 of \Q$short\E\.fai isn't a line of a FASTA index/, 'an index with too few columns dies');
spew('short.fa.fai', '');
dies_like(sub { fasta_region($short, 'a') }, qr/^fasta_region: \Q$short\E\.fai has no sequences/, 'and so does an empty one');

#  files that cannot be indexed

# samtools faidx refuses each of these ("Could not build fai index"), for the
# reason given: fai_build_core()'s "Different line length in sequence" and
# "Format error, unexpected ..."
foreach my $t (
	[">a\nACGT\nAC\nACGT\n", qr/line 4 of \S+ follows a shorter line of "a", and only a sequence's last line can be shorter/, 'a line after a shorter one'],
	[">a\nAC\nACGT\n", qr/line 3 of \S+ is longer than the lines before it of "a"/, 'a line longer than the first'],
	[">a\nACGT\n>b\n", qr/the last sequence of \S+ has a defline and nothing more/, 'a last defline with no sequence'],
	[">a\nACGT\n>b", qr/the last sequence of \S+ has a defline and nothing more/, 'and one with no line feed either'],
	["ACGT\n>a\nACGT\n", qr/line 1 of \S+ comes before any defline/, 'text before any defline'],
	['', qr/\S+ has no sequences/, 'an empty file'],
) {
	my ($content, $re, $name) = @{ $t };
	my $bad = spew('bad.fa', $content);
	dies_like(sub { fasta_index($bad) }, qr/^fasta_index: $re/, "fasta_index dies on $name");
	ok !-e "$bad.fai", 'and writes no index';
	dies_like(sub { fasta_region($bad, 'a') }, qr/^fasta_region: $re/, "fasta_region dies on $name");
}
# samtools: "Ignoring duplicate sequence "a"", and an index of the first alone
my $twice = spew('twice.fa', ">a\nACGT\n>a\nGG\n");
@w = warnings_of(sub { is fasta_region($twice, 'a')->{a}, 'ACGT', 'of two sequences of one name, the first is the one returned' });
is scalar @w, 1, 'with one warning';
like $w[0], qr/^fasta_region: \Q$twice\E has more than one sequence named "a", and the first is the one indexed/, 'that names it';
@w = warnings_of(sub { stdout_of(sub { fasta_index($twice) }) });
is slurp("$twice.fai"), "a\t4\t3\t4\t5\n", "and the index holds the first alone, as samtools's does";
is scalar @w, 1, 'with the same warning';

# Shapes that htslib's file does not have: a last line with no line feed, a
# sequence of one line, and blank lines between sequences, each checked against
# what fasta2hash reads
my $shapes = spew('shapes.fa', ">one\nACGTAC\nGTACGT\nAC\n\n\n>two\nGGGG\n>three\nTTTTT\nTT");
is_deeply fasta_region($shapes, 'one', 'one:5-9', 'two:2-3', 'three', 'three:5-7'),
	{ one => 'ACGTACGTACGTAC', 'one:5-9' => 'ACGTA', 'two:2-3' => 'GG', three => 'TTTTTTT', 'three:5-7' => 'TTT' },
	'a last line with no line feed, and blank lines between sequences';

# A defline and sequence lines that cross the 64 KiB blocks Bioinf.xs reads in:
# the name alone is 70,000 bytes, so it is cut by the first block's end, and
# the 2,000 lines of 61 bytes that follow from byte 70,007 are cut by the
# second's, at 131,072.
my $long_name = 'n' x 70_000;
my $first = 'ACGTACGTAC' x 12_000;
my $blocks = spew('blocks.fa', ">$long_name desc\n" . join('', map { substr($first, 60 * $_, 60) . "\n" } 0 .. 1_999)
	. ">second\n" . ('TTGCA' x 13) . "\n");
stdout_of(sub { fasta_index($blocks) });
is slurp("$blocks.fai"), "$long_name\t120000\t70007\t60\t61\n" . "second\t65\t" . (70_007 + 2_000 * 61 + 8) . "\t65\t66\n",
	'a defline and lines cut by the ends of the blocks it is read in';
unlink "$blocks.fai" or die "$blocks.fai: $!";
my $read = fasta2hash($blocks);
is_deeply fasta_region($blocks, "$long_name:65001-65010", "$long_name:119991-", 'second'),
	{ "$long_name:65001-65010" => substr($first, 65_000, 10), "$long_name:119991-" => substr($first, -10), second => $read->{second} },
	'and the bases there are the ones fasta2hash reads, with no index file';
is $read->{"$long_name desc"}, $first, 'which reads the first sequence whole';
# htslib: isspace() ends a name, and takes '\v' (0x0b) as space; perl's \s,
# which the loop before Bioinf.xs used, did not before perl 5.18
my $vt = spew('vt.fa', ">x\x0by\nACGT\n");
is_deeply fasta_region($vt, 'x'), { x => 'ACGT' }, 'a name ends at a vertical tab, as htslib ends it, on every perl';

dies_like(sub { fasta_region(catfile($dir, 'none.fa'), 'a') }, qr/^fasta_region: ".*none\.fa" doesn't exist or isn't a readable file/, 'a file that is not there dies');
my $gz = spew('x.fa.gz', 'not really gzip');
dies_like(sub { fasta_region($gz, 'a') }, qr/^fasta_region: \Q$gz\E is compressed, and a place in it can't be sought; decompress it first/, 'a compressed file dies');
dies_like(sub { fasta_index($gz) }, qr/^fasta_index: \Q$gz\E is compressed/, 'for fasta_index too');
done_testing;
