require 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More;
use FindBin;
use File::Spec::Functions qw(catfile);
use Digest::SHA qw(sha256_hex);
use Cn::Bioinf qw(:all);
# The sequence functions that work on a string: complement,
# reverse_complement, transcribe, back_transcribe, translate, gc_content,
# kmer_count, assembly_stats, molecular_weight, isoelectric_point,
# protein_charge, subseq and motif_search. Every expected value is another
# package's, checked on 2026-11-11, and each block says which:
#
# - Biopython 1.87: the literals of its Tests/test_seq.py, Tests/test_translate.py,
#   Tests/test_SeqUtils.py and Tests/test_ProtParam.py, and the examples in the
#   docstrings of Bio/SeqUtils/__init__.py and Bio/SeqUtils/IsoelectricPoint.py,
#   which its test suite runs as doctests. Where those tests compare two of the
#   library's functions with each other rather than with a literal, and for
#   nt_search(), which they do not cover, the values are what the library
#   returned for the same input: t/data/seq_reference.py prints them.
# - BioPerl, t/Seq/PrimarySeq.t of bioperl-live at commit 4a43b46.
# - scikit-bio 0.7.4, skbio/sequence/tests/test_sequence.py.
# - assembly-stats 1.0.1 (github.com/sanger-pathogens/assembly-stats),
#   stats_unittest.cpp and its test_files/stats_unittest.fasta, whose five
#   sequences are spelled out here.
# - EMBOSS 6.6.0's revseq, extractseq, geecee, wordcount and fuzznuc, run on
#   t/data/NC_005816.fna (Tests/GenBank/NC_005816.fna of Biopython 1.87):
#   t/data/emboss_reference.pl runs them and prints what is frozen here.

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
# Whether $got is within a relative $tol of $want. The tolerance is given at
# each use, with what it allows for.
sub near {
	my ($got, $want, $tol, $name) = @_;
	my $ok = abs($got - $want) <= $tol * abs($want);
	ok $ok, $name or diag "got $got, wanted $want";
}
my ($plasmid) = values %{ fasta2hash(catfile($FindBin::Bin, 'data', 'NC_005816.fna')) };
is length $plasmid, 9609, 'the plasmid is read whole';

#  complement, reverse_complement, transcribe, back_transcribe

# Biopython, Tests/test_seq.py: test_complement_incompatible_letters,
# test_complement_of_mixed_dna_rna, test_complement_of_rna and
# test_complement_of_dna, and the same four of TestReverseComplement
is complement('CAGGTU'), 'GTCCAA', 'complement reads U as T';
is complement('CAGGTU', type => 'RNA'), 'GUCCAA', 'and writes U for RNA';
is complement('AUGAAACTG'), 'TACTTTGAC', 'complement of a mix of U and T';
is complement('AUGAAACTG', type => 'RNA'), 'UACUUUGAC', 'and as RNA';
is complement('AUGAAACUG', type => 'RNA'), 'UACUUUGAC', 'complement of RNA';
is complement('ATGAAACTG'), 'TACTTTGAC', 'complement of DNA';
is reverse_complement('AUGAAACTG'), 'CAGTTTCAT', 'reverse_complement of a mix of U and T';
is reverse_complement('AUGAAACTG', type => 'RNA'), 'CAGUUUCAU', 'and as RNA';
is reverse_complement('AUGAAACUG'), 'CAGTTTCAT', 'reverse_complement of RNA, as DNA';
is reverse_complement('ATGAAACTG'), 'CAGTTTCAT', 'reverse_complement of DNA';
is reverse_complement('atgaaactg', type => 'rna'), 'caguuucau', '"type" is taken in any case';
# BioPerl, t/Seq/PrimarySeq.t: revcom()
is reverse_complement('TTGGTGGCGTCAACT'), 'AGTTGACGCCACCAA', "BioPerl's revcom";
# Biopython, Tests/test_translate.py: test_transcription
is transcribe('ATA'), 'AUA', 'transcribe';
my $dna = 'GAAAATTCATTTTCTTTGGACTTTCTCTGAAATCCGAGTCCTAGGAAAGATGCGTGAGATTCTTCATATT';
my $rna = 'GAAAAUUCAUUUUCUUUGGACUUUCUCUGAAAUCCGAGUCCUAGGAAAGAUGCGUGAGAUUCUUCAUAUU';
is transcribe($dna), $rna, 'transcribe, a longer one';
is back_transcribe($rna), $dna, 'back_transcribe';

# test_seqs of Biopython's Tests/test_seq.py, which that file checks one
# function against another; these are what Biopython 1.87 returned for each,
# from t/data/seq_reference.py: the sequence, then complement, complement_rna,
# reverse_complement, reverse_complement_rna, transcribe and back_transcribe.
# They take in every ambiguous letter, both cases, gaps, and X, which pairs
# with itself.
my @biopython = (
	[qw(TCAAAAGGATGCATCATG AGTTTTCCTACGTAGTAC AGUUUUCCUACGUAGUAC CATGATGCATCCTTTTGA CAUGAUGCAUCCUUUUGA UCAAAAGGAUGCAUCAUG TCAAAAGGATGCATCATG)],
	[qw(T A A A A U T)],
	[qw(ATGAAACTG TACTTTGAC UACUUUGAC CAGTTTCAT CAGUUUCAU AUGAAACUG ATGAAACTG)],
	[qw(ATGAARCTG TACTTYGAC UACUUYGAC CAGYTTCAT CAGYUUCAU AUGAARCUG ATGAARCTG)],
	[qw(AWGAARCKG TWCTTYGMC UWCUUYGMC CMGYTTCWT CMGYUUCWU AWGAARCKG AWGAARCKG)],
	[qw(ACGUMRWSYKVHDBXN TGCAKYWSRMBDHVXN UGCAKYWSRMBDHVXN NXVHDBMRSWYKACGT NXVHDBMRSWYKACGU ACGUMRWSYKVHDBXN ACGTMRWSYKVHDBXN)],
	[qw(ACGTMRWSYKVHDBXN TGCAKYWSRMBDHVXN UGCAKYWSRMBDHVXN NXVHDBMRSWYKACGT NXVHDBMRSWYKACGU ACGUMRWSYKVHDBXN ACGTMRWSYKVHDBXN)],
	[qw(AUGAAACUG TACTTTGAC UACUUUGAC CAGTTTCAT CAGUUUCAU AUGAAACUG ATGAAACTG)],
	[qw(ATGAAA-CTG TACTTT-GAC UACUUU-GAC CAG-TTTCAT CAG-UUUCAU AUGAAA-CUG ATGAAA-CTG)],
	[qw(ATGAAACTGWN TACTTTGACWN UACUUUGACWN NWCAGTTTCAT NWCAGUUUCAU AUGAAACUGWN ATGAAACTGWN)],
	[qw(AUGAAA==CUG TACTTT==GAC UACUUU==GAC CAG==TTTCAT CAG==UUUCAU AUGAAA==CUG ATGAAA==CTG)],
	[qw(AUGAAACUGWN TACTTTGACWN UACUUUGACWN NWCAGTTTCAT NWCAGUUUCAU AUGAAACUGWN ATGAAACTGWN)],
	[qw(AUGAAACTG TACTTTGAC UACUUUGAC CAGTTTCAT CAGUUUCAU AUGAAACUG ATGAAACTG)],
	[qw(AUGaaaCUG TACtttGAC UACuuuGAC CAGtttCAT CAGuuuCAU AUGaaaCUG ATGaaaCTG)],
	[qw(ACTGTCGTCT TGACAGCAGA UGACAGCAGA AGACGACAGT AGACGACAGU ACUGUCGUCU ACTGTCGTCT)],
);
foreach my $t (@biopython) {
	my ($s, @want) = @{ $t };
	is_deeply [
		complement($s), complement($s, type => 'RNA'), reverse_complement($s), reverse_complement($s, type => 'RNA'),
		transcribe($s), back_transcribe($s),
	], \@want, "$s: both complements, both reverse complements and both transcriptions";
}
my $kept = 'ACGT';
complement($kept);
reverse_complement($kept);
transcribe($kept);
is $kept, 'ACGT', "the caller's sequence is left as it was";
# EMBOSS: revseq of the plasmid
is sha256_hex(reverse_complement($plasmid)), '60849fa3462b305a9061f3bea899522b5a2a5664a0d1552692eec6afde1f1f1c',
	"reverse_complement of the plasmid is revseq's";

#  translate

# Biopython, Tests/test_seq.py, TestTranslating
is translate('ATG---AAACTG', gap => '-'), 'M-KL', 'a codon of three gaps is a gap';
is translate('GTG---GCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG', gap => '-'), 'V-AIVMGR*KGAR*', 'with stops after it';
is translate('ATG---AAACTGTAG', gap => '-'), 'M-KL*', 'and a stop at the end';
is translate('ATG---AAACTGTAG', gap => '-', stop_symbol => '@'), 'M-KL@', '"stop_symbol" is written for a stop';
dies_like(sub { translate('ATG---AAACTG', gap => '~') }, qr/^translate_codons: codon 2, "---", has a letter that isn't a nucleotide's/,
	'a gap that is not "gap" dies');
dies_like(sub { translate('ATG~~~AAACTG', gap => '-') }, qr/codon 2, "~~~"/, 'and so the other way round');
dies_like(sub { translate('ATG---AAACTG') }, qr/codon 2, "---"/, 'a gap dies when "gap" is not given');
is translate('GTGGCCATTGTAATGGGCCGC'), 'VAIVMGR', 'a plain translation';
is translate('GTG---GCCATTGTAATGGGCCGC', gap => '-'), 'V-AIVMGR', 'and with a gap';
is translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG', table => 2, to_stop => 1), 'VAIVMGRWKGAR', '"to_stop" ends at the first stop of the code';
foreach my $codon (qw(TA? N-N AC_ Ac_)) {
	dies_like(sub { translate($codon) }, qr/^translate_codons: codon 1, "\Q$codon\E"/, "the codon $codon dies");
}
is translate($_), 'Z', "$_ is Z, glutamate or glutamine" for qw(SAR SAG SAA);
is translate($_), 'B', "$_ is B, aspartate or asparagine" for qw(RAY RAT RAC);
is translate($_), 'J', "$_ is J, leucine or isoleucine" for qw(WTA MTY MTT MTW MTM MTH MTA MTC HTA);
my @w = warnings_of(sub { is translate('GTGGCCATTGTAATGGGCCG'), 'VAIVMG', 'a sequence that ends inside a codon is translated up to it' });
is scalar @w, 1, 'with one warning';
like $w[0], qr/^translate: the sequence's length, 20, is not a multiple of three, so its last 2 letters are not translated at \Q${\ __FILE__}\E line/,
	'which says how much was left, at the caller\'s line';
# code 2 reads the TGA at codon 8 as W, so the first stop is the TAG at codon 13
dies_like(sub { translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAGTAG', table => 2, cds => 1) },
	qr/^translate: with "cds", only the last codon may be a stop, and codon 13, "TAG", is one/, '"cds" dies on a stop before the last');
is translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG', table => 2, cds => 1), 'MAIVMGRWKGAR', '"cds" starts with M and drops the stop';
dies_like(sub { translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCG', table => 2, cds => 1) }, qr/the sequence's length, 35, must be a multiple of three/,
	'"cds" dies on a length that is not a multiple of three');
dies_like(sub { translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGA', table => 2, cds => 1) }, qr/the last codon, "CGA", must be a stop codon of genetic code 2/,
	'"cds" dies without a stop codon');
dies_like(sub { translate('GCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG', table => 2, cds => 1) }, qr/the first codon, "GCC", must be a start codon of genetic code 2/,
	'"cds" dies without a start codon');
dies_like(sub { translate('ATGGGCTGA', table => 28, to_stop => 1) },
	qr/^translate: "to_stop" can't be used with "table" 28: genetic code 28 reads TAA as Q or as a stop and TAG as Q or as a stop and TGA as W or as a stop/,
	'"to_stop" dies with a code whose stops are also amino acids');
@w = warnings_of(sub { is translate('ATGGGCTGA', table => 28), 'MGW', 'such a codon is translated as the amino acid' });
is scalar @w, 1, 'with one warning';
like $w[0], qr/^translate: genetic code 28 reads TAA as Q or as a stop .* and they are translated as the amino acid/, 'which says so';
# TestStopCodons
my $stops = 'TAATAGTGAAGAAGG';
is translate($stops), '***RR', 'stops of the standard code';
is translate($stops, table => 1), '***RR', 'by its number';
is translate($stops, table => 'SGC0'), '***RR', "by NCBI's short name";
is translate($stops, table => 2), '**W**', 'of code 2';
is translate($stops, table => 'Yeast Mitochondrial'), '**WRR', 'of a code by its name';
is translate($stops, table => 5), '**WSS', 'of code 5';
is translate($stops, table => 9), '**WSS', 'of code 9';
is translate($stops, table => 'Euplotid Nuclear'), '**CRR', 'of another by its name';
is translate($stops, table => 11), '***RR', 'of code 11';
is translate($stops, table => 'Bacterial'), '***RR', 'by one of the organisms in its name';
is translate($stops, table => 'bacterial, archaeal and plant plastid'), '***RR', 'and by its whole name, in any case';
is_deeply [map { translate($_) } qw(TAT TAR TAN NNN)], [qw(Y * X X)], 'a codon that may or may not be a stop is X';
is_deeply [map { translate($_) } qw(TAt TaR TaN nnN)], [qw(Y * X X)], 'in mixed case';
is_deeply [map { translate($_) } qw(tat tar tan nnn)], [qw(Y * X X)], 'and in lower case';
# Tests/test_translate.py
is translate('', to_stop => 1), '', 'an empty sequence';
is translate('TAA', to_stop => 1), '', 'a stop alone, with "to_stop"';
@w = warnings_of(sub {
	is translate('GAAAATTCATTTTCTTTGGACTTTCTCTGAAATCCGAGTCCTAGGAAAGATGCGTGAGATTCTTCA', to_stop => 1), 'ENSFSLDFL', 'a longer one, to its stop';
	is translate('GAAAATTCATTTTCTTTGGACTTTCTCTGAAATCCGAGTCCTAGGAAAGATGCGTGAGATTCTTCATAT', table => 'SGC8', to_stop => 1),
		'ENSFSLDFLWNPSPSNDAWDSSY', 'and under code 9';
});
is scalar @w, 0, 'neither warns, as both are whole codons';
is translate('GAA', table => 15, to_stop => 1), 'E', 'code 15';
is translate('ATA', table => 'Vertebrate Mitochondrial', to_stop => 1), 'M', 'ATA under the vertebrate mitochondrial code';
my $mixed = 'TCAAAAAGGTGCATCTAGATG';
is translate($mixed, to_stop => 1), 'SKRCI', 'to the stop';
is translate($mixed), 'SKRCI*M', 'and through it';
is translate($mixed, table => 2, to_stop => 1), 'SK', 'code 2 reads AGG as a stop';
is translate($mixed, table => 2), 'SK*CI*M', 'both of them';
is translate($mixed, table => 2, stop_symbol => '+'), 'SK+CI+M', 'written as "stop_symbol"';
(my $mixed_rna = $mixed) =~ tr/T/U/;
is translate($mixed_rna, to_stop => 1), 'SKRCI', 'RNA, to the stop';
is translate($mixed_rna), 'SKRCI*M', 'RNA, through it';
is translate('RATGATTARAATYTA', table => 'Vertebrate Mitochondrial'), 'BD*NL', 'ambiguous codons';
is translate('RATGATTARAATYTA', table => 'SGC1', to_stop => 1), 'BD', 'and to the stop';
# Biopython 1.87's own answers for its test_seqs, cut to whole codons, from
# t/data/seq_reference.py: translate(), and under codes 2 and 11
foreach my $t (
	[qw(TCAAAAGGATGCATCATG SKGCIM)], [qw(ATGAAACTG MKL)], [qw(ATGAARCTG MKL)], [qw(AWGAARCKG XKX)], [qw(AUGAAACUG MKL)],
	[qw(AUGAAACTG MKL)], [qw(AUGaaaCUG MKL)], [qw(ACTGTCGTC TVV)],
) {
	is_deeply [map { translate($t->[0], table => $_) } 1, 2, 11], [($t->[1]) x 3], "$t->[0] under codes 1, 2 and 11";
}
# Biopython translates ACX, taking X as any base, and refuses XXX; X is not an
# IUPAC nucleotide, and here a codon with one always dies
dies_like(sub { translate('ACX') }, qr/codon 1, "ACX"/, 'a codon with X dies, where Biopython reads it as N');
# BioPerl, t/Seq/PrimarySeq.t: translate()
is translate('TTGGTGGCGTCAACT'), 'LVAST', "BioPerl's translation";
is translate('TTGGTGGCGTCAACTTAA', cds => 1), 'MVAST', 'its -complete, where TTG starts the protein as M';
is translate('ATGGTGGCGTCAACTTAG', table => 6), 'MVASTQ', 'its -codontable_id 6, which reads TAG as Q';
is translate('ATGGTGGCGTCAACTTAG', stop_symbol => 'X'), 'MVASTX', 'its -terminator';
@w = warnings_of(sub { is translate(substr 'ATGGTGGCGTCAACTTAG', 1), 'WWRQL', 'its -frame 1' });
is scalar @w, 1, 'which leaves two letters over';
# A string perl holds as characters is translated as its bytes are
my $upgraded = 'ATGAAACTG';
utf8::upgrade($upgraded);
is translate($upgraded), 'MKL', 'a sequence held as UTF-8';
is translate('ATGTAA', stop_symbol => "\xe9"), "M\xe9", 'a "stop_symbol" above 127';

#  gc_content

# Biopython, Tests/test_SeqUtils.py: test_gc_fraction, which compares to 3
# places. Each case here is exact to 1e-15 instead: t/data/seq_reference.py
# printed Biopython's answers to 17 digits and they are these fractions, and
# 1e-15 is what a long-double or quadmath perl's own rounding of 2/3 needs.
foreach my $t (
	['', 0, 0, 0],
	['ACGGGCTACCGTATAGGCAAGAGATGATGCCC', 0.5625, 0.5625, 0.5625],
	['ACTGSSSS', 0.75, 0.75, 0.75],
	['GGAUCUUCGGAUCU', 0.5, 0.5, 0.5],
	['CCTGNN', 0.75, 0.5, 2 / 3],
	['GDVV', 1, 0.25, 2 / 3],
	# the docstring of gc_fraction, and one with every weighted letter
	['ACTG', 0.5, 0.5, 0.5],
	['ACTGN', 0.5, 0.4, 0.5],
	['acgtBDHKMNRVXY-', 0.5, 2 / 15, 7 / 15],
) {
	my ($s, @want) = @{ $t };
	my @mode = qw(remove ignore weighted);
	foreach my $i (0 .. 2) {
		my $got = gc_content($s, ambiguous => $mode[$i]);
		ok abs($got - $want[$i]) <= 1e-15, "gc_content of \"$s\", $mode[$i]" or diag "got $got, wanted $want[$i]";
	}
}
is gc_content('ACTGN'), 0.5, '"ambiguous" is "remove" unless given';
# EMBOSS: geecee of the plasmid, which it prints to two places
is sprintf('%.2f', gc_content($plasmid)), '0.45', "gc_content of the plasmid is geecee's";

#  kmer_count

# scikit-bio, skbio/sequence/tests/test_sequence.py: test_kmer_frequencies,
# test_kmer_frequencies_empty_sequence, test_kmer_frequencies_relative and
# test_kmer_frequencies_floating_point_precision
is_deeply kmer_count('', 1), {}, 'kmer_count of an empty sequence';
is_deeply kmer_count('', 1, overlap => 0), {}, 'without overlap';
is_deeply kmer_count('', 1, relative => 1), {}, 'as shares';
is_deeply kmer_count('', 1, relative => 1, overlap => 0), {}, 'and both';
is_deeply kmer_count('GATTACA', 1), { G => 1, A => 3, T => 2, C => 1 }, '1-mers';
is_deeply kmer_count('GATTACA', 3), { GAT => 1, ATT => 1, TTA => 1, TAC => 1, ACA => 1 }, '3-mers';
is_deeply kmer_count('GATTACA', 3, overlap => 1), { GAT => 1, ATT => 1, TTA => 1, TAC => 1, ACA => 1 }, '"overlap" is 1 unless given';
is_deeply kmer_count('GATTACA', 8), {}, 'a k longer than the sequence';
is_deeply kmer_count('GATTACA', 3, overlap => 0), { GAT => 1, TAC => 1 }, '3-mers that do not overlap';
is_deeply kmer_count('GATTACA', 7, overlap => 0), { GATTACA => 1 }, 'a k of the whole sequence';
is_deeply kmer_count('GATTACA', 8, overlap => 0), {}, 'and one longer, without overlap';
is_deeply kmer_count('GATTACA', 1, relative => 1), { A => 3 / 7, C => 1 / 7, G => 1 / 7, T => 2 / 7 }, '1-mers as shares';
is_deeply kmer_count('GATTACA', 3, relative => 1), { GAT => 1 / 5, ATT => 1 / 5, TTA => 1 / 5, TAC => 1 / 5, ACA => 1 / 5 }, '3-mers as shares';
is_deeply kmer_count('GATTACA', 8, relative => 1), {}, 'no k-mers, as shares';
is_deeply kmer_count('GATTACA', 3, overlap => 0, relative => 1), { GAT => 1 / 2, TAC => 1 / 2 }, 'shares without overlap';
is_deeply kmer_count('GATTACA', 7, overlap => 0, relative => 1), { GATTACA => 1 }, 'a share of exactly 1';
ok kmer_count('AAAAAAAAAA', 1, relative => 1)->{A} == 1, 'ten of one letter are a share of exactly 1, not ten tenths added up';
# EMBOSS: wordcount -wordsize 3 of the plasmid
my %words = map { split /=/ } qw(
	AAA=366 AAC=208 AAG=144 AAT=214 ACA=186 ACC=134 ACG=136 ACT=136 AGA=174 AGC=138 AGG=123 AGT=105 ATA=189 ATC=187 ATG=172 ATT=180
	CAA=159 CAC=141 CAG=232 CAT=176 CCA=136 CCC=112 CCG=131 CCT=121 CGA=110 CGC=132 CGG=131 CGT=110 CTA=64 CTC=146 CTG=205 CTT=144
	GAA=231 GAC=125 GAG=106 GAT=159 GCA=163 GCC=118 GCG=103 GCT=145 GGA=159 GGC=119 GGG=100 GGT=103 GTA=106 GTC=104 GTG=113 GTT=144
	TAA=176 TAC=118 TAG=58 TAT=179 TCA=223 TCC=136 TCG=113 TCT=157 TGA=178 TGC=140 TGG=127 TGT=149 TTA=172 TTC=192 TTG=104 TTT=245
);
is_deeply kmer_count($plasmid, 3), \%words, "3-mers of the plasmid are wordcount's";
# A sequence with a character above 255 is counted in perl, and one held as
# UTF-8 without any is counted as its bytes are; both give characters as keys
is_deeply kmer_count("\x{3b1}\x{3b2}\x{3b1}\x{3b2}", 2), { "\x{3b1}\x{3b2}" => 2, "\x{3b2}\x{3b1}" => 1 }, 'k-mers of characters above 255';
my $latin = "\xe9A\xe9A";
utf8::upgrade($latin);
is_deeply kmer_count($latin, 2), { "\xe9A" => 2, "A\xe9" => 1 }, 'k-mers of a sequence held as UTF-8';

#  assembly_stats

# assembly-stats: stats_unittest.cpp, whose tests print these for
# test_files/stats_unittest.fasta, the five sequences below. Its "sum" is
# total_length, "n" number, "ave" mean_length and "largest" longest; its N50
# line "N50 = 6, n = 2" is n50 and l50; N_count and Gaps are n_count and gaps.
my @contigs = qw(ACCCGTGT AC AnGT ANNNAC A);
my $stats = assembly_stats(\@contigs);
is_deeply $stats, {
	total_length => 21, number => 5, mean_length => 21 / 5, longest => 8, shortest => 1, n_count => 4, gaps => 2, n50 => 6, l50 => 2,
	nx => { 10 => 8, 20 => 8, 30 => 8, 40 => 6, 50 => 6, 60 => 6, 70 => 4, 80 => 4, 90 => 2, 100 => 1 },
	lx => { 10 => 1, 20 => 1, 30 => 1, 40 => 2, 50 => 2, 60 => 2, 70 => 3, 80 => 3, 90 => 4, 100 => 5 },
}, "assembly_stats gives assembly-stats's numbers";
is sprintf('%.2f', $stats->{mean_length}), '4.20', 'the mean as assembly-stats prints it';
my %named;
@named{qw(a b c d e)} = @contigs;
is_deeply assembly_stats(\%named), $stats, 'a hash of sequences, as fasta2hash returns, gives the same';
is_deeply assembly_stats([]), {
	total_length => 0, number => 0, mean_length => 0, longest => 0, shortest => 0, n_count => 0, gaps => 0, n50 => 0, l50 => 0,
	nx => { map { 10 * $_ => 0 } 1 .. 10 }, lx => { map { 10 * $_ => 0 } 1 .. 10 },
}, 'no sequences give zeros, as assembly-stats prints for an empty file';
# Up to 2026-11-16 sequences that were all empty reached every tenth at the
# first of them, since 10 * 0 >= 0 * x, so that their L50 was 1. The values are
# the README's rule, that every Nx and Lx of sequences with no length is 0;
# assembly-stats was not run on such a file.
is_deeply assembly_stats(['', '']), {
	total_length => 0, number => 2, mean_length => 0, longest => 0, shortest => 0, n_count => 0, gaps => 0, n50 => 0, l50 => 0,
	nx => { map { 10 * $_ => 0 } 1 .. 10 }, lx => { map { 10 * $_ => 0 } 1 .. 10 },
}, 'two empty sequences give an L50 of 0, rather than 1';
is pos($contigs[3]), undef, "counting the gaps leaves the caller's sequences as they were";

#  molecular_weight

# Biopython: the docstring of molecular_weight (Bio/SeqUtils/__init__.py), which
# prints to two places
is sprintf('%.2f', molecular_weight('AGC')), '949.61', 'molecular_weight of DNA';
is sprintf('%.2f', molecular_weight('AGC', type => 'DNA')), '949.61', 'by its type';
is sprintf('%.2f', molecular_weight('AGC', type => 'RNA')), '997.61', 'of RNA';
is sprintf('%.2f', molecular_weight('AGC', type => 'protein')), '249.29', 'of a protein';
# Tests/test_ProtParam.py: test_get_molecular_weight and
# test_get_monoisotopic_molecular_weight, to two places
my $protein = 'MAEGEITTFTALTEKFNLPPGNYKKPKLLYCSNGGHFLRILPDGTVDGTRDRSDQHIQLQLSAESVGEVYIKSTETGQYLAMDTSGLLYG'
	. 'SQTPSEECLFLERLEENHYNTYTSKKHAEKNWFVGLKKNGSCKRGPRTHYGQKAILFLPLPV';
is sprintf('%.2f', molecular_weight($protein, type => 'protein')), '17103.16', "of Biopython's test protein";
is sprintf('%.2f', molecular_weight($protein, type => 'protein', monoisotopic => 1)), '17092.61', 'and its monoisotopic weight';
# What Biopython 1.87 returned, to 17 digits, from t/data/seq_reference.py.
# Biopython adds a weight for each letter in turn and this multiplies each
# letter's weight by its count, so the two round differently: the largest
# difference among these was 2.1e-16 of the value (a double's rounding, on
# perl 5.44.0), and 1e-13 leaves room for a longer sum.
foreach my $t (
	['AGC', {}, 949.60949999999991],
	['AGC', { type => 'RNA' }, 997.60770000000002],
	['AGC', { type => 'protein' }, 249.28739999999999],
	['AGC', { double_stranded => 1 }, 1890.2057],
	['AGC', { circular => 1 }, 931.59419999999989],
	['AGC', { double_stranded => 1, circular => 1 }, 1854.1750999999999],
	['AGC', { monoisotopic => 1 }, 949.16706000000011],
	['AGC', { type => 'RNA', double_stranded => 1 }, 1972.1755000000001],
	['AGC', { type => 'RNA', monoisotopic => 1, circular => 1 }, 979.14123899999993],
	['acg tac gta', {}, 2802.7965999999997],
	['GATTACAGATTACAGATTACA', { double_stranded => 1, monoisotopic => 1 }, 13001.169099999999],
	[$protein, { type => 'protein' }, 17103.161700000001],
	[$protein, { type => 'protein', monoisotopic => 1 }, 17092.614978000001],
	[$protein, { type => 'protein', circular => 1 }, 17085.146400000001],
	['MOUSE', { type => 'protein' }, 752.73860000000002],
) {
	my ($s, $opt, $want) = @{ $t };
	near(molecular_weight($s, %{ $opt }), $want, 1e-13,
		'molecular_weight of ' . (length $s > 30 ? 'the protein' : "\"$s\"") . join('', map { ", $_ => $opt->{$_}" } sort keys %{ $opt }));
}
# Biopython gives an empty sequence the weight of the water it took off, 18.0153
dies_like(sub { molecular_weight('') }, qr/^molecular_weight: the sequence is empty/, 'an empty sequence dies, where Biopython weighs it as water');
dies_like(sub { molecular_weight('ACGN') }, qr/^molecular_weight: "N" has no weight as a letter of DNA; only ACGT do/, 'an ambiguous letter dies');
dies_like(sub { molecular_weight('ACGU') }, qr/"U" has no weight as a letter of DNA/, 'so does U in DNA');
dies_like(sub { molecular_weight('MKX', type => 'protein') }, qr/"X" has no weight as a letter of protein/, 'and X in a protein');

#  isoelectric_point, protein_charge

# Biopython: Tests/test_ProtParam.py, test_isoelectric_point and
# test_charge_at_pH, which compare to two places, and the docstring of
# Bio/SeqUtils/IsoelectricPoint.py, which prints to two
is sprintf('%.2f', isoelectric_point($protein)), '7.72', "isoelectric_point of Biopython's test protein";
ok abs(protein_charge($protein, 7.72)) < 0.005, 'whose charge at that pH is 0.00';
is sprintf('%.2f', isoelectric_point('INGAR')), '9.75', 'isoelectric_point of INGAR';
is sprintf('%.2f', protein_charge('INGAR', 7.0)), '0.76', 'and its charge at pH 7';
is sprintf('%.2f', isoelectric_point('PETER')), '4.53', 'isoelectric_point of PETER';
ok abs(protein_charge('PETER', 4.53)) < 0.005, 'whose charge at that pH is 0.00';
# What Biopython 1.87 returned, to 17 digits, from t/data/seq_reference.py:
# the isoelectric point, and the charge at pH 7 and at pH 7.72. The bisection
# takes the same steps, so the isoelectric points agreed to the last digit on
# perl 5.44.0. A perl with a longer NV computes each charge more exactly, and
# could take another turn at a step where the charge is within rounding of 0,
# so the points are held to the 0.0001 that the bisection stops at. The
# charges were within 4 parts in 1e15 of Biopython's, and 1e-12 leaves room
# for a sum of more terms.
foreach my $t (
	[$protein, 7.7224523544311525, 0.92581198751496885, 0.0026656096941941598],
	['INGAR', 9.7500211715698235, 0.76009161428930161, 0.37601336711735855],
	['PETER', 4.5320798873901369, -1.0358602083752255, -1.1852991766633507],
	['DDDD', 4.0500284194946286, -4.2322344404440155, -4.6224711303820385],
	['RRRR', 11.999967765808105, 3.7600616145892984, 3.3758559331415365],
	['ACDEFGHIKLMNPQRSTVWY', 6.7845521926879879, -0.12492899297528393, -0.61594799447794157],
	['mkwvtfisllflfssaysrgv', 9.9924222946167021, 1.4983466856433418, 1.1496230788906241],
	['E', 4.5992635726928706, -1.157935101534517, -1.5099037752892051],
	['A', 5.5700166702270497, -0.20412541214591307, -0.57421259992755802],
) {
	my ($s, $pi, $at7, $at772) = @{ $t };
	my $name = length $s > 30 ? 'the protein' : $s;
	ok abs(isoelectric_point($s) - $pi) <= 0.0001, "isoelectric_point of $name" or diag 'got ' . isoelectric_point($s) . ", wanted $pi";
	near(protein_charge($s, 7), $at7, 1e-12, "charge of $name at pH 7");
	near(protein_charge($s, 7.72), $at772, 1e-12, "charge of $name at pH 7.72");
}

#  subseq

# BioPerl, t/Seq/PrimarySeq.t: subseq()
is subseq('TTGGTGGCGTCAACT', 2, 5), 'TGGT', 'subseq';
is subseq('TTGGTGGCGTCAACT', 1, 15), 'TTGGTGGCGTCAACT', 'the whole sequence';
is subseq('TTGGTGGCGTCAACT', 12), 'AACT', 'to the end, when no end is given';
is subseq('TTGGTGGCGTCAACT', 15, 15), 'T', 'one letter';
# EMBOSS: extractseq -regions of the plasmid
is subseq($plasmid, 101, 130), 'GACAGTTATGGAAATTAAAATCCTGCACAA', "a part of the plasmid is extractseq's";
is subseq($plasmid, 9580, 9609), 'CGCATGAGGGAATGCGTACCCCGACCCCTG', 'and so is its end';
# BioPerl throws on these too
dies_like(sub { subseq('TTGGTGGCGTCAACT', 5, 2) }, qr/^subseq: the start, 5, is after the end, 2/, 'a start after the end dies');
dies_like(sub { subseq('TTGGTGGCGTCAACT', 2, 16) }, qr/^subseq: the end, 16, is beyond the sequence's length, 15/, 'an end past the sequence dies');
dies_like(sub { subseq('TTGGTGGCGTCAACT', 0, 3) }, qr/^subseq: the start must be a whole number, 1 or more, not "0"/, 'a start of 0 dies');

#  motif_search

# Where Biopython 1.87's nt_search() found each motif, counted from 0, from
# t/data/seq_reference.py. Its hits may overlap, as here.
foreach my $t (
	['ACGTACGTNACGT', 'ACGY', [0, 4, 9]],
	['AAAAAA', 'AA', [0, 1, 2, 3, 4]],
	['GAATTCGGATCCGAATTC', 'GAATTC', [0, 12]],
	['GAATTCGGATCCGAATTC', 'GRATYC', [0, 6, 12]],
	['TTTTGGCCAATTTT', 'NGGCCN', [3]],
	['ACGT', 'TTT', []],
) {
	my ($s, $motif, $at) = @{ $t };
	my $hits = motif_search($s, $motif);
	is_deeply [map { $_->{start} - 1 } @{ $hits }], $at, "$motif in $s is found where nt_search finds it";
	is_deeply [map { $_->{match} } @{ $hits }], [map { substr $s, $_, length $motif } @{ $at }], 'and each hit is what was matched';
}
is_deeply motif_search('ACGTACGTNACGT', 'ACGY')->[1], { start => 5, end => 8, strand => 1, match => 'ACGT' }, 'the fields of a hit';
# nt_search matches case as it is written; here a motif of letters finds either
is_deeply [map { $_->{start} } @{ motif_search('gaattcGGATCC', 'gratyc') }], [1, 7], 'a motif of letters is found in either case, where nt_search is not';
is_deeply [map { $_->{start} } @{ motif_search('GAAUUCGGAUCC', 'GRATYC') }], [1, 7], 'and T in it finds U';
is_deeply [map { $_->{start} } @{ motif_search('GAATTCGGATCC', 'GRAUYC', type => 'RNA') }], [1, 7], 'as U finds T';
# EMBOSS: fuzznuc -complement on the plasmid, as [start, end] on each strand.
# The four motifs are a palindrome with ambiguous letters, one that is not a
# palindrome, one with N, and a run whose hits overlap.
my %fuzznuc = (
	GRATYC => { '+' => [[546, 551], [1962, 1967], [6900, 6905], [8753, 8758]], '-' => [[546, 551], [1962, 1967], [6900, 6905], [8753, 8758]] },
	TTGACA => { '+' => [[1949, 1954], [2464, 2469], [7748, 7753]], '-' => [[5435, 5440], [5995, 6000]] },
	GGNCC => {
		'+' => [[941, 945], [1433, 1437], [1561, 1565], [1597, 1601], [1783, 1787], [1906, 1910], [2145, 2149], [5628, 5632], [8326, 8330], [9420, 9424]],
		'-' => [[941, 945], [1433, 1437], [1561, 1565], [1597, 1601], [1783, 1787], [1906, 1910], [2145, 2149], [5628, 5632], [8326, 8330], [9420, 9424]],
	},
	AAAAAA => {
		'+' => [
			[1002, 1007], [2132, 2137], [2526, 2531], [2746, 2751], [2747, 2752], [3492, 3497], [4094, 4099], [4095, 4100], [4413, 4418],
			[4414, 4419], [4550, 4555], [4699, 4704], [4700, 4705], [5910, 5915], [5911, 5916], [5912, 5917], [5927, 5932], [5928, 5933],
			[6094, 6099], [6095, 6100], [6364, 6369], [6365, 6370], [9077, 9082], [9078, 9083], [9079, 9084], [9414, 9419], [9539, 9544],
		],
		'-' => [
			[2015, 2020], [2373, 2378], [2385, 2390], [2652, 2657], [2653, 2658], [2705, 2710], [4061, 4066], [4264, 4269], [4265, 4270],
			[4266, 4271], [8703, 8708], [9219, 9224], [9232, 9237], [9233, 9238], [9354, 9359], [9355, 9360],
		],
	},
);
foreach my $motif (sort keys %fuzznuc) {
	my $both = motif_search($plasmid, $motif, strand => 'both');
	foreach my $strand ('+', '-') {
		my $n = $strand eq '+' ? 1 : -1;
		my $want = $fuzznuc{$motif}{$strand};
		is_deeply [map { [$_->{start}, $_->{end}] } grep { $_->{strand} == $n } @{ $both }], $want, "$motif on the plasmid's $strand strand is where fuzznuc finds it";
		is_deeply [map { [$_->{start}, $_->{end}] } @{ motif_search($plasmid, $motif, strand => $strand) }], $want, "and with strand => '$strand'";
	}
	is_deeply [map { $_->{start} } @{ $both }], [sort { $a <=> $b } map { $_->{start} } @{ $both }], 'the hits of both strands come in order';
}
# a hit on the minus strand is given as that strand reads
is_deeply motif_search($plasmid, 'TTGACA', strand => '-')->[0], { start => 5435, end => 5440, strand => -1, match => 'TTGACA' },
	'a hit on the minus strand has the motif as its match';
is subseq($plasmid, 5435, 5440), 'TGTCAA', 'where the plus strand has its reverse complement';
# a pattern is used as it is written
is_deeply [map { [$_->{start}, $_->{match}] } @{ motif_search('GATTACAGATTTACA', qr/T+A/) }], [[3, 'TTA'], [4, 'TA'], [10, 'TTTA'], [11, 'TTA'], [12, 'TA']],
	'a qr// pattern, whose hits overlap too';
is_deeply motif_search('gattaca', qr/TTA/), [], 'matches case as written';
is_deeply [map { $_->{start} } @{ motif_search('gattaca', qr/TTA/i) }], [3], 'unless it says otherwise';
is_deeply motif_search('ACGT', qr/X*/), [], 'a pattern that matches nothing finds nothing';
# a protein motif: B is D or N, Z is E or Q, J is I or L, and X is anything
is_deeply [map { [$_->{start}, $_->{match}] } @{ motif_search('MKNEIDQLW', 'BZJ', type => 'protein') }], [[3, 'NEI'], [6, 'DQL']], 'a protein motif with B, Z and J';
is_deeply [map { $_->{match} } @{ motif_search('MKNGSW', 'NXS', type => 'protein') }], ['NGS'], 'and with X';

SKIP: {
	skip 'Test::LeakTrace is not installed', 5 unless eval { require Test::LeakTrace; 1 };
	local $SIG{__WARN__} = sub { };
	Test::LeakTrace::no_leaks_ok(sub { translate('ATGAARCTGTAANNN') }, 'translate does not leak');
	Test::LeakTrace::no_leaks_ok(sub { eval { translate('ATGAA?') } }, 'nor when it dies');
	Test::LeakTrace::no_leaks_ok(sub { translate('GTGGCCATTGTAATGGGCCGCTGAAAGGGTGCCCGATAG', table => 2, cds => 1) }, 'nor with "cds"');
	Test::LeakTrace::no_leaks_ok(sub { kmer_count('GATTACAGATTACA', 3) }, 'kmer_count does not leak');
	Test::LeakTrace::no_leaks_ok(sub { kmer_count($latin, 2, relative => 1) }, 'nor with a sequence held as UTF-8');
}
done_testing;
