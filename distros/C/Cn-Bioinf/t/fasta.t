require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Spec::Functions qw(catfile);
use IO::Compress::Gzip ();
use Cn::Bioinf qw(fasta2hash hash2fasta_file);
# The expected values are what bioinf.pm's pure-perl fasta2hash and
# hash2fasta_file returned for the same input (checked 2026-09-29), except
# where a case says the XS deliberately differs. Those for whitespace are what
# Biopython 1.87's SeqIO.parse(file, 'fasta') read from the same file (checked
# 2026-10-17): its record.description and str(record.seq).

my $dir = tempdir(CLEANUP => 1);
sub spew {
	my ($name, $content) = @_;
	my $f = catfile($dir, $name);
	open my $fh, '>:raw', $f or die $!;
	print {$fh} $content;
	close $fh;
	$f;
}
sub warnings_of {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	$code->();
	@w;
}

my $plain = spew('a.fa', ">one desc\nACGT\nAC\n>two\nMKV\n>three\n\nGG\n");
is_deeply fasta2hash($plain), { 'one desc' => 'ACGTAC', two => 'MKV', three => 'GG' }, 'every record, lines joined';
is fasta2hash($plain, 'two'), 'MKV', 'one record by its defline';
is fasta2hash($plain, 'three'), 'GG', 'the last record by its defline';
eval { fasta2hash($plain, 'four') };
like $@, qr/couldn't find "four"/, 'an absent defline dies';

# Differs from bioinf.pm, which kept the "\r" of a CRLF file in every sequence
# and defline.
is_deeply fasta2hash(spew('crlf.fa', ">x\r\nAC\r\nGT\r\n>y\r\nW\r\n")), { x => 'ACGT', y => 'W' }, 'CRLF line endings';
is_deeply fasta2hash(spew('noeol.fa', ">x\nAC\n>y\nWW")), { x => 'AC', y => 'WW' }, 'no newline at the end';
is_deeply fasta2hash(spew('tail.fa', ">x\nAC\n>y")), { x => 'AC', y => '' }, 'a last defline with no sequence';
is fasta2hash(spew('tail2.fa', ">x\nAC\n>y"), 'y'), '', 'which can still be asked for';

my @w = warnings_of(sub { is_deeply fasta2hash(spew('dup.fa', ">x\nA\n>y\nC\n>x\nG\n")), { x => 'AG', y => 'C' }, 'a repeated defline is concatenated' });
is scalar @w, 1, 'with one warning';
like $w[0], qr/"x" appears more than once in .*dup\.fa \(line 5\)/, 'naming the defline and its line';
# The defline is named as it is keyed, without the whitespace dropped from its
# end. The warning used to print that whitespace too, the CR of a CRLF file
# included, as the dropped bytes were still in the buffer the message read.
@w = warnings_of(sub { is_deeply fasta2hash(spew('dupcr.fa', ">a  \r\nAC GT\r\n>a \t\r\nTT\r\n")), { a => 'ACGTTT' }, 'a repeated CRLF defline with trailing whitespace' });
is scalar @w, 1, 'with one warning';
like $w[0], qr/^read_fasta: "a" appears more than once in .*dupcr\.fa \(line 3\)/, 'which names the defline without its trailing whitespace';
@w = warnings_of(sub { is fasta2hash(spew('dupk.fa', ">x\nA\n>x\nG\n>y\nC\n"), 'x'), 'AG', 'also when only that record is wanted' });
is scalar @w, 1, 'with one warning there too';
# Differs from bioinf.pm: with a key, the other deflines are not kept, so a
# repeat of one of them goes unremarked.
@w = warnings_of(sub { is fasta2hash(spew('dupo.fa', ">x\nA\n>x\nG\n>y\nC\n"), 'y'), 'C', 'a record after a repeated one' });
is scalar @w, 0, 'with no warning about the repeat, which was not asked for';

# Up to 2026-10-17 a sequence kept its spaces and tabs, and a defline its
# trailing whitespace, so this was { 'x ' => "AC GT AC\t", y => 'MK' }.
my $ws = spew('ws.fa', ">x \nAC GT \nAC\t\n>y\nMK\n");
is_deeply fasta2hash($ws), { x => 'ACGTAC', y => 'MK' }, 'whitespace is dropped from sequences and from the end of deflines, rather than kept';
is fasta2hash($ws, 'x'), 'ACGTAC', 'so a defline with a trailing space is found by its name';
# Differs from Biopython, which keeps a tab inside a line and the spaces at the
# start of a defline's name
is fasta2hash(spew('tab.fa', ">x\nAC\tGT\n"), 'x'), 'ACGT', 'a tab inside a line is dropped too';
is_deeply fasta2hash(spew('lead-ws.fa', " \t\r\n>x\nA\n")), { x => 'A' }, 'a line of whitespace before the first defline is allowed';
# Every byte but "\n" at each place 1 to 19 of a 20-byte line, which Bioinf.xs
# reads as two 8-byte words and a 4-byte tail: its 8-bytes-at-once test for
# whitespace must drop " ", "\t", "\r", "\f" and "\x0b", as Python's
# str.split() would, and keep every other byte.
{
	my (@records, %want);
	foreach my $byte (grep { $_ != 10 } 0 .. 255) {
		my @lines = map { my $l = 'A' x 20; substr($l, $_, 1, chr $byte); $l } 1 .. 19;
		push @records, ">b$byte\n" . join("\n", @lines) . "\n";
		($want{"b$byte"} = join '', @lines) =~ tr/ \t\r\f\x0b//d;
	}
	is_deeply fasta2hash(spew('bytes.fa', join '', @records)), \%want, 'each of the 255 bytes, at each place in a line, is dropped only if it is whitespace';
}
eval { fasta2hash(spew('bad.fa', "ACGT\n>x\nA\n")) };
like $@, qr/line 1 is sequence, but no defline/, 'sequence before any defline dies';
is_deeply fasta2hash(spew('lead.fa', "\n\r\n>x\nA\n")), { x => 'A' }, 'blank lines before the first defline are allowed';
eval { fasta2hash(spew('empty-def.fa', ">x\nA\n>\nC\n")) };
like $@, qr/line 3 is a defline with no name/, 'a bare ">" dies';
eval { fasta2hash(spew('empty.fa', '')) };
like $@, qr/couldn't find any sequences/, 'an empty file dies';
eval { fasta2hash(catfile($dir, 'nope.fa')) };
like $@, qr/doesn't exist or isn't a readable file/, 'a missing file dies';

# A record that straddles Bioinf.xs's 64 KiB read blocks. ">x\r\n" is 4 bytes,
# so 65531 residues put the "\r" at byte 65535, the last of the first block,
# and its "\n" first in the second: the "\r" has to be chopped after the fact.
my $long = 'A' x 65531;
my $f = spew('long.fa', ">x\r\n$long\r\n>y\r\nMK\r\n");
is fasta2hash($f, 'x'), $long, 'a CRLF split across a block boundary';
is fasta2hash($f, 'y'), 'MK', 'and the record after it';
# ">x\n" is 3 bytes, so the space after 65532 residues is the last byte of the
# first block and the tab the first of the second; and the defline of 65533
# letters puts its trailing space at the end of the first block.
$f = spew('long-ws.fa', ">x\n" . ('A' x 65532) . " \tC\n>y\nMK\n");
is fasta2hash($f, 'x'), ('A' x 65532) . 'C', 'whitespace split across a block boundary';
$f = spew('long-def.fa', '>' . ('n' x 65533) . " \t\nMK\n");
is_deeply fasta2hash($f), { ('n' x 65533) => 'MK' }, 'and at the end of a defline split across one';

# The .gz files are made with IO::Compress::Gzip rather than a gzip command
# line, which would need a shell. Reading one still runs the gzip program, so
# these are skipped where fasta2hash says it can't, and fail on anything else.
sub gzip_file {
	my ($from, $to) = @_;
	IO::Compress::Gzip::gzip($from => $to) or die "gzip $from: $IO::Compress::Gzip::GzipError";
	$to;
}
my $gunzip = eval { fasta2hash(gzip_file($plain, catfile($dir, 'probe.fa.gz'))); 1 } ? '' : $@;
my $no_gzip = $gunzip =~ /^_open_fasta: can't run gzip/ ? $gunzip : '';
$no_gzip =~ s/ at .+ line \d+\.\n\z//; # croak's location, which is only noise in a skip

SKIP: {
	skip "fasta2hash can't read a .gz here: $no_gzip", 3 if $no_gzip;
	my $gz = gzip_file($plain, catfile($dir, 'a.fa.gz'));
	is_deeply fasta2hash($gz), fasta2hash($plain), '.gz is decompressed';
	is fasta2hash($gz, 'one desc'), 'ACGTAC', 'and can be read for one record';
	# the suffix in any case, as pgs_score takes a weights file's; X.FA.GZ used
	# to be read as plain text, and died of its first gzip byte as "sequence,
	# but no defline"
	my $upper = gzip_file($plain, catfile($dir, 'A.FA.GZ'));
	is_deeply fasta2hash($upper), fasta2hash($plain), '.GZ is decompressed too';
}

SKIP: {
	# 20,000 60-residue lines compress to about 3 KB; half of that is a gzip
	# stream that ends early, and gzip says so on STDERR and in its exit status
	skip "fasta2hash can't read a .gz here: $no_gzip", 4 if $no_gzip;
	my $big = spew('big.fa', ">x\n" . (('A' x 60) . "\n") x 20_000);
	my $gz_whole = gzip_file($big, catfile($dir, 'whole.fa.gz'));
	my $gz = gzip_file($big, catfile($dir, 'big.fa.gz'));
	truncate $gz, int((-s $gz) / 2) or die "truncate $gz: $!";
	open my $saved, '>&', \*STDERR or die $!;
	open STDERR, '>', File::Spec->devnull or die $!;
	my $r = eval { fasta2hash($gz) };
	my $err = $@;
	my $one = eval { fasta2hash($gz, 'nope') };
	my $err_key = $@;
	# _fasta_ordered, which plot_msa, plot_phylo, view_alignment and
	# msa_quality_table read their FASTA through, up to 2026-11-16 left gzip's
	# exit status unread and returned the part it got
	my ($whole) = Cn::Bioinf::_fasta_ordered($gz_whole);
	my $ordered = eval { [Cn::Bioinf::_fasta_ordered($gz)] };
	my $err_ordered = $@;
	open STDERR, '>&', $saved or die $!;
	is length $whole->{x}, 1_200_000, '_fasta_ordered reads the whole .gz';
	like $err_ordered, qr/^_fasta_ordered: couldn't read all of .+big\.fa\.gz: gzip exited [1-9]/,
		'and dies on a truncated one, rather than returning part of it';
	like $err, qr/^fasta2hash: couldn't read all of .+big\.fa\.gz: gzip exited [1-9]/, 'a truncated .gz dies, rather than returning part of it';
	like $err_key, qr/couldn't read all of/, 'and so it does when a key was looked for to the end';
}

my %h = (b => 'ABCDEFGHIJ', a => 'XYZ', e => '');
my $out = catfile($dir, 'out.fa');
my $said = catfile($dir, 'said.txt');
{
	open my $saved, '>&', \*STDOUT or die $!;
	open STDOUT, '>', $said or die $!;
	is hash2fasta_file(\%h, $out), $out, 'hash2fasta_file returns the file name';
	open STDOUT, '>&', $saved or die $!;
}
open my $fh, '<', $said or die $!;
is do { local $/; <$fh> }, "wrote $out\n", 'and says "wrote" it, without colour when STDOUT is not a terminal, rather than nothing';
close $fh;
# Test::More has its own copy of STDOUT, made as it loaded, so the "wrote"
# lines of the calls below can go to the null device rather than into the TAP.
open STDOUT, '>', File::Spec->devnull or die "can't send STDOUT to the null device: $!";
open $fh, '<', $out or die $!;
is do { local $/; <$fh> }, ">a\nXYZ\n>b\nABCDEFGHIJ\n>e\n", 'sorted keys, 80 columns';
close $fh;
hash2fasta_file(\%h, $out, ['b', 'a'], 4);
open $fh, '<', $out or die $!;
is do { local $/; <$fh> }, ">b\nABCD\nEFGH\nIJ\n>a\nXYZ\n", 'given order and width';
close $fh;
hash2fasta_file(\%h, $out, ['b'], 0);
is_deeply fasta2hash($out), { b => 'ABCDEFGHIJ' }, 'width 0 writes one line, and reads back';
# Up to 2026-10-17 a string perl held as UTF-8 was written as its UTF-8 and any
# other as its bytes, so "caf\x{e9}" came out as one byte or two depending on
# how it was made, and one file could mix the two.
my $up = "caf\x{e9}";
utf8::upgrade($up);
hash2fasta_file({ $up => $up }, $out, [$up], 0);
open $fh, '<:raw', $out or die $!;
is do { local $/; <$fh> }, ">caf\xe9\ncaf\xe9\n", 'a string perl holds as UTF-8 is written as its characters, as print would, not as its UTF-8';
close $fh;
eval { hash2fasta_file({ "\x{3b2}-tub" => 'K' }, $out) };
like $@, qr/^write_fasta: ".+-tub" has a character above 255, so it has to be encoded/, 'a character above 255 in a defline dies';
eval { hash2fasta_file({ b => "M\x{3b2}" }, $out) };
like $@, qr/^write_fasta: the sequence of "b" has a character above 255/, 'and in a sequence';
eval { hash2fasta_file(\%h, $out, ['zz']) };
like $@, qr/"zz" has no sequence/, 'a key not in the hash dies';
eval { hash2fasta_file(\%h, $out, [undef]) };
like $@, qr/element 0 of the order is undefined/, 'an undef in the order dies';
eval { hash2fasta_file([], $out) };
like $@, qr/must be a hash ref/, 'a non-hash dies';
eval { hash2fasta_file(\%h, $out, 'b') };
like $@, qr/array ref or undef/, 'a non-array order dies';

# ---- found by review on 2026-11-10; each failed against the code of that day

# A file whose lines end in CR alone is one line, and came back as one record
# named by the whole file, with no sequence. Biopython 1.87 reads such a file,
# since Python opens it with universal newlines; here it is refused, which is
# a deliberate difference.
eval { fasta2hash(spew('cr.fa', ">a\rAAA\r>b\rCCC\r")) };
like $@, qr/^read_fasta: .+cr\.fa line 1 has a carriage return inside its defline, as a file whose lines end in CR alone/,
	'a file of CR line endings dies, rather than being one record named by all of it';
# An error raised in Bioinf.xs was placed at the line of Cn/Bioinf.pm that
# called the XSUB, which tells a caller nothing. The period after the line
# number is optional: Carp wrote none before its 1.25, so perl 5.12.5's does
# not (the first run of this test there, on 2026-11-10, failed on it).
eval { fasta2hash(spew('noseq.fa', "ACGT\n")) };
like $@, qr/^read_fasta: .+noseq\.fa line 1 is sequence, but no defline .+ at \Q${\ __FILE__}\E line \d+\.?\n\z/,
	"an error raised in Bioinf.xs is placed at the caller's line, not at Cn/Bioinf.pm's";
eval { hash2fasta_file({ a => 'M' }, $out, ['zz']) };
like $@, qr/^write_fasta: "zz" has no sequence in the hash at \Q${\ __FILE__}\E line \d+\.?\n\z/, 'and so is one raised in writing';
# With a key, reading stops at the defline after its record, as README.md
# says, so a second record of that name further on is not read: the first's
# sequence comes back alone, with no warning. This is not new; the whole-file
# read of the same file, which warns and joins the two, is the sentinel.
{
	my $far = spew('dupfar.fa', ">a\nAAA\n>b\nCCC\n>a\nGGG\n");
	my @w = warnings_of(sub { is fasta2hash($far)->{a}, 'AAAGGG', 'a repeat further on is joined when the whole file is read' });
	is scalar(@w), 1, 'and warned of';
	@w = warnings_of(sub { is fasta2hash($far, 'a'), 'AAA', 'but with a key, reading stops before it, and the first record comes back alone' });
	is scalar(@w), 0, 'with no warning';
}
# hash2fasta_file wrote a reference as "ARRAY(0x...)", a key with a line feed
# as a defline and a line of sequence, and an empty key as a defline with no
# name, none of which fasta2hash reads back as what was given.
eval { hash2fasta_file({ a => ['M'] }, $out) };
like $@, qr/^write_fasta: the sequence of "a" is a reference, not a string of residues/, 'a sequence that is a reference dies, rather than being written as ARRAY(0x...)';
eval { hash2fasta_file({ "a\nb" => 'M' }, $out) };
like $@, qr/^write_fasta: "a\nb" has a line feed in it, which would end the defline there/, 'a key with a line feed dies';
eval { hash2fasta_file({ '' => 'M' }, $out) };
like $@, qr/^write_fasta: element 0 of the order is an empty name, which a defline can't be/, 'an empty key dies';
{
	package Cn::Bioinf::Test::Seq; # an object that is its own text
	use overload '""' => sub { ${ $_[0] } }, fallback => 1;
}
hash2fasta_file({ o => bless(\(my $text = 'MKV'), 'Cn::Bioinf::Test::Seq') }, $out, undef, 0);
is_deeply fasta2hash($out), { o => 'MKV' }, 'but an object that overloads its text is written as that text';

SKIP: {
	skip "fasta2hash can't read a .gz here: $no_gzip", 1 if $no_gzip;
	# gzip read a name that starts with "-" as its options. The name has to be
	# relative to start with one, hence the chdir.
	require Cwd;
	my $was = Cwd::getcwd();
	gzip_file($plain, catfile($dir, '-n.fa.gz'));
	chdir $dir or die "$dir: $!";
	my $got = eval { fasta2hash('-n.fa.gz') };
	my $why = $@;
	chdir $was or die "$was: $!";
	is_deeply $got, fasta2hash($plain), 'a .gz whose name starts with "-" is read, not taken for gzip\'s options' or diag $why;
}

SKIP: {
	skip 'Test::LeakTrace is not installed', 5 unless eval { require Test::LeakTrace; 1 };
	Test::LeakTrace::no_leaks_ok(sub { fasta2hash($plain) }, 'fasta2hash does not leak');
	Test::LeakTrace::no_leaks_ok(sub { eval { fasta2hash($plain, 'four') } }, 'nor when it dies');
	Test::LeakTrace::no_leaks_ok(sub { hash2fasta_file(\%h, $out, ['b', 'a']) }, 'hash2fasta_file does not leak');
	Test::LeakTrace::no_leaks_ok(sub { hash2fasta_file({ $up => $up }, $out, [$up]) }, 'nor when it writes a string held as UTF-8');
	Test::LeakTrace::no_leaks_ok(sub { eval { hash2fasta_file({ a => 'M', "\x{3b2}" => 'K' }, $out) } }, 'nor when it dies on a character above 255');
}
done_testing;
