require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Spec::Functions qw(catfile);
use Digest::SHA qw(sha256_hex);
use Cn::Bioinf qw(fasta2hash find_orfs translate_six_frames);
# find_orfs and translate_six_frames. Every expected value is another
# package's, checked on 2026-11-11:
#
# - EMBOSS 6.6.0's getorf: the four t/data/*.orf_*.fa files are its output as
#   it wrote it, for t/data/V00294.fa (the lacI gene that getorf's own
#   documentation uses) and t/data/NC_005816.fna (a Yersinia pestis plasmid,
#   Tests/GenBank/NC_005816.fna of Biopython 1.87). The three frames quoted
#   from its documentation are the "Output files for usage example" of
#   doc/programs/text/getorf.txt in EMBOSS 6.6.0, which its QA test getorf-ex
#   (test/qatest.dat) checks. t/data/emboss_reference.pl made the files, and
#   its header comment gives the command behind each.
# - EMBOSS 6.6.0's transeq, for the six frames of the plasmid, as SHA-256
#   digests that the same script prints.
# - Biopython 1.87: the second listing of "Identifying open reading frames" in
#   its Tutorial (Doc/Tutorial/chapter_cookbook.rst), which t/data/seq_reference.py
#   reproduces, and the docstring of six_frame_translations() in
#   Bio/SeqUtils/__init__.py, which its test suite runs as a doctest.
# - scikit-bio 0.7.4, skbio/sequence/tests/test_genetic_code.py.
# - BioPerl, t/Seq/PrimarySeq.t of bioperl-live at commit 4a43b46.

my $data = catfile($FindBin::Bin, 'data');
my ($lac) = values %{ fasta2hash(catfile($data, 'V00294.fa')) };
my ($plasmid) = values %{ fasta2hash(catfile($data, 'NC_005816.fna')) };
is length $lac, 1113, 'the lacI gene is read whole';
is length $plasmid, 9609, 'and so is the plasmid';

# The frames of a getorf output file as find_orfs gives them: [start, end,
# strand, protein], in find_orfs's order. getorf writes "[465 - 49] (REVERSE
# SENSE)" for a frame on the minus strand, with the larger position first.
sub getorf {
	my ($file) = @_;
	my $h = fasta2hash(catfile($data, $file));
	my @orf;
	foreach my $defline (keys %{ $h }) {
		$defline =~ /\A\S+ \[([0-9]+) - ([0-9]+)\]( \(REVERSE SENSE\))?/ or die "$file: can't read \"$defline\"";
		push @orf, $3 ? [$2, $1, -1, $h->{$defline}] : [$1, $2, 1, $h->{$defline}];
	}
	[sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] || $b->[2] <=> $a->[2] } @orf];
}
sub found { [map { [@{ $_ }{qw(start end strand protein)}] } @{ $_[0] }] }

#  find_orfs

# getorf's documentation: getorf -minsize 300, which is 100 amino acids
my $orfs = find_orfs($lac, min_length => 100);
is_deeply [map { [@{ $_ }{qw(start end strand)}] } @{ $orfs }], [[1, 1110, 1], [49, 465, -1], [735, 1112, 1]],
	"the frames of lacI are those of getorf's documentation";
like $orfs->[2]{protein}, qr/\AGHRSHCDAGCQRSDGAGRNARHYRVRAARWCGYLGSGIRRYRRQLMLYPAVNHHQTGFSP.*TGKRAV\z/, 'with the protein it prints for the first';
like $orfs->[0]{protein}, qr/\APEESQFRVVNVKPVTLYDVAEYAGVSYQTVSRVVNQASHVSAKTREKVEAAMAELNYIPN.*RQVSRLESGQ\z/, 'for the second';
like $orfs->[1]{protein}, qr/\ARRNISAGSFHSNGILVIQRIVNDQPTDALREKIVHRRFTGFDAASFYHRHHHAGTQLIGA.*VHHAGNGLIRDTGILCDIV\z/, 'and for the third';
is_deeply $orfs->[1], {
	start => 49, end => 465, strand => -1, frame => -1, length => 139,
	protein => 'RRNISAGSFHSNGILVIQRIVNDQPTDALREKIVHRRFTGFDAASFYHRHHHAGTQLIGARFNRRDNLRRRVQGQTGGGNANQQRLFARQLLCHAVGNVIQLRHRRFHFFPRFRRNVAGLVHHAGNGLIRDTGILCDIV',
}, 'the fields of a frame on the minus strand';
is_deeply [map { $_->{frame} } @{ $orfs }], [1, -1, 3], 'the reading frame of each';

# getorf's output files, with its default of 30 nucleotides, which is this
# function's default of 10 amino acids
my $want = getorf('V00294.orf_any.fa');
is scalar @{ $want }, 48, 'getorf found 48 frames between stops in lacI';
is_deeply found(find_orfs($lac)), $want, 'and find_orfs finds the same, with the same proteins';
$want = getorf('V00294.orf_atg.fa');
is scalar @{ $want }, 14, 'getorf found 14 frames from ATG to a stop';
is_deeply found(find_orfs($lac, start => 'ATG')), $want, 'and find_orfs finds the same with start => "ATG"';
is_deeply found(find_orfs($lac, start => 'ATG', strand => '+')), [grep { $_->[2] == 1 } @{ $want }], 'those of the plus strand alone';
is_deeply found(find_orfs($lac, start => 'ATG', strand => '-')), [grep { $_->[2] == -1 } @{ $want }], 'and of the minus strand alone';
$want = getorf('NC_005816.orf_any.fa');
is scalar @{ $want }, 14, 'getorf found 14 frames of 100 amino acids in the plasmid, under code 11';
is_deeply found(find_orfs($plasmid, table => 11, min_length => 100)), $want, 'and find_orfs finds the same';
$want = getorf('NC_005816.orf_code.fa');
is scalar @{ $want }, 13, "getorf found 13 from one of code 11's start codons";
is_deeply found(find_orfs($plasmid, table => 11, min_length => 100, start => 'code')), $want, 'and find_orfs finds the same with start => "code"';
is_deeply found(find_orfs($plasmid, table => 'Bacterial', min_length => 100, start => 'code')), $want, 'by the name of the code too';
ok !grep({ $_->[3] !~ /\AM/ } @{ $want }), 'each of which starts with M, whichever start codon it has';

# Biopython's Tutorial lists the same 14 frames of the plasmid as "first 30
# amino acids...last 3 - length, strand, start:end". Its start and end count
# from 0, end past the last base, and take in the stop codon that closes the
# frame, which find_orfs leaves out: so on the plus strand its start is one
# less and its end three more, cut off at the sequence's end, and on the minus
# strand, where the stop is before the frame, its start is four less.
my @tutorial = (
	'NQIQGVICSPDSGEFMVTFETVMEIKILHK...GVA - length 355, strand 1, 41:1109',
	'WDVKTVTGVLHHPFHLTFSLCPEGATQSGR...VKR - length 111, strand -1, 491:827',
	'KSGELRQTPPASSTLHLRLILQRSGVMMEL...NPE - length 285, strand 1, 1030:1888',
	'RALTGLSAPGIRSQTSCDRLRELRYVPVSL...PLQ - length 119, strand -1, 2830:3190',
	'RRKEHVSKKRRPQKRPRRRRFFHRLRPPDE...PTR - length 128, strand 1, 3470:3857',
	'GLNCSFFSICNWKFIDYINRLFQIIYLCKN...YYH - length 176, strand 1, 4249:4780',
	'RGIFMSDTMVVNGSGGVPAFLFSGSTLSSY...LLK - length 361, strand -1, 4814:5900',
	'VKKILYIKALFLCTVIKLRRFIFSVNNMKF...DLP - length 165, strand 1, 5923:6421',
	'LSHTVTDFTDQMAQVGLCQCVNVFLDEVTG...KAA - length 107, strand -1, 5974:6298',
	'GCLMKKSSIVATIITILSGSANAASSQLIP...YRF - length 315, strand 1, 6654:7602',
	'IYSTSEHTGEQVMRTLDEVIASRSPESQTR...FHV - length 111, strand -1, 7788:8124',
	'WGKLQVIGLSMWMVLFSQRFDDWLNEQEDA...ESK - length 125, strand -1, 8087:8465',
	'TGKQNSCQMSAIWQLRQNTATKTRQNRARI...AIK - length 100, strand 1, 8741:9044',
	'QGSGYAFPHASILSGIAMSHFYFLVLHAVK...CSD - length 114, strand -1, 9264:9609',
);
my $len = length $plasmid;
is_deeply [map {
	my ($from, $to) = $_->{strand} > 0 ? ($_->{start} - 1, $_->{end} + 3 > $len ? $len : $_->{end} + 3) : ($_->{start} - 4, $_->{end});
	sprintf '%s...%s - length %d, strand %d, %d:%d', substr($_->{protein}, 0, 30), substr($_->{protein}, -3), $_->{length}, $_->{strand}, $from, $to;
} @{ find_orfs($plasmid, table => 11, min_length => 100) }], \@tutorial, "the plasmid's frames are those of Biopython's Tutorial";

# BioPerl: translate(-orf => 1), which translates the first frame from an ATG
my $first = sub { find_orfs($_[0], start => 'ATG', strand => '+', min_length => 1)->[0] };
is $first->('TTTTATGGTGGCGTCAACTTAATTT')->{protein}, 'MVAST', "BioPerl's first frame from an ATG";
is_deeply $first->('ggggggatgtagcccc'), { start => 7, end => 9, strand => 1, frame => 1, length => 1, protein => 'M' },
	'its smallest, a start codon and a stop';
is $first->('ggggggatgtggcccc')->{protein}, 'MWP', 'and one with no stop, which runs to the end';

is_deeply find_orfs(''), [], 'an empty sequence has no frames';
is_deeply find_orfs('AT'), [], 'nor has one shorter than a codon';
is_deeply find_orfs('TAA', min_length => 1, strand => '+'), [], 'nor a strand that is one stop';
# EMBOSS: getorf -minsize 3 -noreverse of these nine bases, which
# t/data/emboss_reference.pl prints: a frame at the start, one after a stop,
# and one that the sequence's end cuts short
is_deeply found(find_orfs('ATGAAATAG', min_length => 1, strand => '+')), [[1, 6, 1, 'MK'], [3, 8, 1, 'EI'], [5, 7, 1, 'N']],
	"the frames of nine bases are getorf's";

#  translate_six_frames

# scikit-bio: test_translate_six_frames, whose expected proteins are in the
# order of frames 1, 2, 3, -1, -2, -3
is_deeply translate_six_frames('AUGCUAACAUAAA'), { 1 => 'MLT*', 2 => 'C*HK', 3 => 'ANI', -1 => 'FMLA', -2 => 'LC*H', -3 => 'YVS' },
	"scikit-bio's six frames";
is_deeply translate_six_frames('AUGCUAACAUAAA', stop_symbol => '.'), { 1 => 'MLT.', 2 => 'C.HK', 3 => 'ANI', -1 => 'FMLA', -2 => 'LC.H', -3 => 'YVS' },
	'with "stop_symbol"';
# Biopython: the docstring of six_frame_translations() draws the minus frames
# under the complementary strand, last residue first, so each is reversed here:
# it prints "H  G  N  Y  H  A  A  S" for its frame -1
is_deeply translate_six_frames('AUGGCCAUUGUAAUGGGCCGCUGA'),
	{ 1 => 'MAIVMGR*', 2 => 'WPL*WAA', 3 => 'GHCNGPL', -1 => scalar reverse('HGNYHAAS'), -2 => scalar reverse('AMTIPRQ'), -3 => scalar reverse('PWQLPGS') },
	"Biopython's six frames";
# EMBOSS: transeq -frame 6 -alternative -table 11 of the plasmid. transeq
# writes an X for the one or two bases after a frame's last whole codon, which
# is dropped here, and t/data/emboss_reference.pl takes it off before the
# digest.
my $frames = translate_six_frames($plasmid, table => 11);
is_deeply { map { $_ => [length $frames->{$_}, sha256_hex($frames->{$_})] } keys %{ $frames } }, {
	1 => [3203, 'd6df5f16c73c57d0f41dfc086925d08c54fde2dbfbb7e84a7d68c6613b1c04c2'],
	2 => [3202, '7d67b83b3b11229e80bf50261426ed17e0c9459904e2a634b255717aa4199566'],
	3 => [3202, '13499f167757f52a6014972d6e4a9890c044f81e4bb46d6dc0d567bb49195187'],
	-1 => [3203, '30794bafcc707b689932fbd46f8a849fe7188a2e1fa57ee42d75b651ff77cc49'],
	-2 => [3202, '96a4c197a2a24c9c2a9f8e35d2370005e1039ad47c9c580a1cb9cb9ff2dbf85d'],
	-3 => [3202, 'eea836f146fb0256ce889a5112d983aabbc3ab896c12aafbcb6a5d9c08b0b16b'],
}, "the plasmid's six frames are transeq's";
is_deeply translate_six_frames(''), { map { $_ => '' } 1, 2, 3, -1, -2, -3 }, 'an empty sequence has six empty frames';
is_deeply translate_six_frames('AT'), { map { $_ => '' } 1, 2, 3, -1, -2, -3 }, 'and so has one shorter than a codon';
my @w;
{
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	is translate_six_frames('ATGAAAC')->{1}, 'MK', 'a length that is not a multiple of three';
}
is scalar @w, 0, 'is not warned about, since five of the six frames always end inside a codon';
done_testing;
