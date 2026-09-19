#!/usr/bin/env perl
# aa3to1(), res1() and res_type() -- the residue name table in the XS.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

#--------
# the twenty
#--------
my %STANDARD = (
	ALA => 'A', ARG => 'R', ASN => 'N', ASP => 'D', CYS => 'C',
	GLN => 'Q', GLU => 'E', GLY => 'G', HIS => 'H', ILE => 'I',
	LEU => 'L', LYS => 'K', MET => 'M', PHE => 'F', PRO => 'P',
	SER => 'S', THR => 'T', TRP => 'W', TYR => 'Y', VAL => 'V',
);
is(aa3to1($_), $STANDARD{$_}, "aa3to1: $_ is $STANDARD{$_}") for sort keys %STANDARD;

# every one of the twenty gets a different letter, which is the one property
# the table cannot get away with breaking
my %seen;
$seen{ aa3to1($_) }++ for keys %STANDARD;
is(scalar keys %seen, 20, 'aa3to1: the twenty map to twenty distinct letters');

#--------
# the codes the format allows for an ambiguous or unusual residue
#--------
is(aa3to1('ASX'), 'B', 'aa3to1: ASX is B (ASP or ASN)');
is(aa3to1('GLX'), 'Z', 'aa3to1: GLX is Z (GLU or GLN)');
is(aa3to1('XLE'), 'J', 'aa3to1: XLE is J (LEU or ILE)');
is(aa3to1('SEC'), 'U', 'aa3to1: SEC is U (selenocysteine)');
is(aa3to1('PYL'), 'O', 'aa3to1: PYL is O (pyrrolysine)');
is(aa3to1('UNK'), 'X', 'aa3to1: UNK is X');

#--------
# The whole table, name by name.
#
# Modified residues map to the residue they were made from: a structure solved
# with selenomethionine has the same sequence as one without it, and an X every
# seventh position is no use to anyone.  Every name the switch in Parser.xs
# knows is written out here rather than a sample of them, because a switch is
# exactly the shape where a name is dropped or given the wrong letter by a
# careless edit and nothing else notices -- the parse of a structure that
# happens not to contain it says the same thing either way.
#
# Checked against gemmi 0.7.5's find_tabulated_residue().one_letter_code on
# 2026-09-15: of the 150 names below, gemmi's built-in table carries 119 and
# agrees about 116 of them.  It disagrees about three, and each is a judgement
# rather than a mistake on either side:
#
#   ORN, DAB  gemmi maps both to alanine; here they are X.  Ornithine and
#             2,4-diaminobutyrate are neither alanine nor one of the twenty,
#             and a sequence that calls them A is a sequence that has lost them.
#   5MU       gemmi calls it a U; here it is a T.  It is ribothymidine, the T
#             of the TPsiC loop of tRNA, which is where it is nearly always
#             found.
#
# The remaining 31 are names gemmi's table does not carry at all, most of them
# the spellings AMBER and CHARMM use (HID, HIE, HIP, HSD, HSE, HSP, CYX) and
# the pre-v3 nucleotide names (ADE, CYT, GUA, THY, URI).
#--------
my %AMINO = (
	'ALA' => 'A', 'ARG' => 'R', 'ASN' => 'N', 'ASP' => 'D', 'CYS' => 'C', 'GLN' => 'Q',
	'GLU' => 'E', 'GLY' => 'G', 'HIS' => 'H', 'ILE' => 'I', 'LEU' => 'L', 'LYS' => 'K',
	'MET' => 'M', 'PHE' => 'F', 'PRO' => 'P', 'SER' => 'S', 'THR' => 'T', 'TRP' => 'W',
	'TYR' => 'Y', 'VAL' => 'V', 'ASX' => 'B', 'GLX' => 'Z', 'XLE' => 'J', 'SEC' => 'U',
	'PYL' => 'O', 'UNK' => 'X', 'XAA' => 'X', 'MSE' => 'M', 'MHO' => 'M', 'FME' => 'M',
	'CXM' => 'M', 'SME' => 'M', 'MED' => 'M', 'CSO' => 'C', 'CSD' => 'C', 'CSS' => 'C',
	'CSX' => 'C', 'CSW' => 'C', 'CME' => 'C', 'CMT' => 'C', 'CYX' => 'C', 'CAS' => 'C',
	'CAF' => 'C', 'OCS' => 'C', 'SMC' => 'C', 'SNC' => 'C', 'YCM' => 'C', 'SEP' => 'S',
	'SAC' => 'S', 'TPO' => 'T', 'PTR' => 'Y', 'TYS' => 'Y', 'TYI' => 'Y', 'TYQ' => 'Y',
	'TPQ' => 'Y', 'PAQ' => 'Y', 'STY' => 'Y', 'IYR' => 'Y', 'KCX' => 'K', 'LLP' => 'K',
	'MLY' => 'K', 'MLZ' => 'K', 'M3L' => 'K', 'ALY' => 'K', 'LYZ' => 'K', 'HYP' => 'P',
	'HY3' => 'P', 'PCA' => 'E', 'CGU' => 'E', 'GMA' => 'E', 'HIC' => 'H', 'HID' => 'H',
	'HIE' => 'H', 'HIP' => 'H', 'HSD' => 'H', 'HSE' => 'H', 'HSP' => 'H', 'MHS' => 'H',
	'NEP' => 'H', 'AIB' => 'A', 'ABA' => 'A', 'ALM' => 'A', 'AYA' => 'A', 'BAL' => 'A',
	'SAR' => 'G', 'MLE' => 'L', 'NLE' => 'L', 'MVA' => 'V', 'CIR' => 'R', 'ORN' => 'X',
	'DAB' => 'X', 'TRO' => 'W', 'PHI' => 'F', 'PHL' => 'F', 'MEA' => 'F', 'DAL' => 'A',
	'DAR' => 'R', 'DSG' => 'N', 'DAS' => 'D', 'DCY' => 'C', 'DGN' => 'Q', 'DGL' => 'E',
	'DHI' => 'H', 'DIL' => 'I', 'DLE' => 'L', 'DLY' => 'K', 'DPN' => 'F', 'DPR' => 'P',
	'DSN' => 'S', 'DTH' => 'T', 'DTR' => 'W', 'DTY' => 'Y', 'DVA' => 'V', 'DIV' => 'V',
);
# the nucleotides, DNA and RNA, under every spelling the archive has used
my %NUCLEIC = (
	'DA'  => 'A', 'DC'  => 'C', 'DG'  => 'G', 'DT'  => 'T', 'DU'  => 'U', 'DI'  => 'I',
	'A'   => 'A', 'C'   => 'C', 'G'   => 'G', 'T'   => 'T', 'U'   => 'U', 'I'   => 'I',
	'N'   => 'N', 'ADE' => 'A', 'CYT' => 'C', 'GUA' => 'G', 'THY' => 'T', 'URI' => 'U',
	'PSU' => 'U', 'H2U' => 'U', '4SU' => 'U', '5MU' => 'T', '5MC' => 'C', 'OMC' => 'C',
	'1MA' => 'A', '2MG' => 'G', '7MG' => 'G', '1MG' => 'G', 'M2G' => 'G', 'OMG' => 'G',
);
my @WATER = qw(HOH WAT DOD H2O SOL TIP);

is(scalar keys %AMINO, 114, 'the amino acid half of the table is all of it');
is(scalar keys %NUCLEIC, 30, 'and so is the nucleic half');
for my $n (sort keys %AMINO) {
	is(aa3to1($n), $AMINO{$n}, "aa3to1: $n is $AMINO{$n}");
	is(res_type($n), 'amino_acid', "res_type: $n is an amino acid");
}
for my $n (sort keys %NUCLEIC) {
	is(res1($n), $NUCLEIC{$n}, "res1: $n is $NUCLEIC{$n}");
	is(res_type($n), 'nucleotide', "res_type: $n is a nucleotide");
	is(aa3to1($n), '', "aa3to1: $n is not an amino acid");
}
for my $n (@WATER) {
	is(res_type($n), 'water', "res_type: $n is water");
	is(res1($n), '', "res1: $n has no single-letter code");
}
# every amino acid answers res1() the same way it answers aa3to1(): the two
# read one table, and the whole point of that is that they cannot disagree
is_deeply([ map { res1($_) } sort keys %AMINO ],
          [ map { aa3to1($_) } sort keys %AMINO ],
	'res1 and aa3to1 give the same letter for every amino acid in the table');

#--------
# things that are not amino acids
#--------
is(aa3to1($_), '', "aa3to1: $_ is not an amino acid") for qw(HOH WAT NAG ZN SO4 DA A ATP);

#--------
# whitespace and case: names arrive straight out of columns 18-20, which are
# blank padded, and files are not consistent about case
#--------
is(aa3to1('  ALA'), 'A', 'aa3to1: leading blanks are ignored');
is(aa3to1('ALA  '), 'A', 'aa3to1: trailing blanks are ignored');
is(aa3to1(' ALA '), 'A', 'aa3to1: blanks on both sides are ignored');
is(aa3to1('ala'),   'A', 'aa3to1: lower case is accepted');
is(aa3to1('Ala'),   'A', 'aa3to1: mixed case is accepted');
is(aa3to1(''),      '',  'aa3to1: the empty string is not an amino acid');
is(aa3to1('    '),  '',  'aa3to1: blanks alone are not an amino acid');
is(aa3to1('TOOLONG'), '', 'aa3to1: a name longer than three characters is unknown');

#--------
# res1() widens the same table to nucleotides
#--------
is(res1('ALA'), 'A', 'res1: amino acids answer as aa3to1 does');
is(res1('MSE'), 'M', 'res1: modified amino acids too');
is(res1(' DA'), 'A', 'res1: DA is deoxyadenosine');
is(res1('DA'),  'A', 'res1: DA without its padding blank');
is(res1('DC'),  'C', 'res1: DC');
is(res1('DG'),  'G', 'res1: DG');
is(res1('DT'),  'T', 'res1: DT');
is(res1('  A'), 'A', 'res1: A is adenosine');
is(res1('U'),   'U', 'res1: U is uridine');
is(res1('PSU'), 'U', 'res1: pseudouridine is a U');
is(res1('5MC'), 'C', 'res1: 5-methylcytidine is a C');
is(res1('HOH'), '',  'res1: water has no single-letter code');
is(res1('NAG'), '',  'res1: a sugar has no single-letter code');

# CYS is an amino acid and CYT is cytosine: three-letter names that differ in
# one character must not collide in the packed key
is(aa3to1('CYS'),   'C', 'CYS is cysteine');
is(res_type('CYT'), 'nucleotide', 'CYT is cytosine, not cysteine');

#--------
# res_type()
#--------
is(res_type('ALA'), 'amino_acid', 'res_type: ALA');
is(res_type('MSE'), 'amino_acid', 'res_type: MSE is still an amino acid');
is(res_type('DA'),  'nucleotide', 'res_type: DA');
is(res_type('U'),   'nucleotide', 'res_type: U');
is(res_type($_), 'water', "res_type: $_ is water") for qw(HOH WAT DOD H2O SOL);
is(res_type($_), 'other', "res_type: $_ is neither polymer nor water") for qw(NAG ZN SO4 ATP HEM);

#--------
# aa1to3() -- the other direction
#--------
is(aa1to3($STANDARD{$_}), $_, "aa1to3: $STANDARD{$_} is $_") for sort keys %STANDARD;

is(aa1to3('B'), 'ASX', 'aa1to3: B is ASX (ASP or ASN)');
is(aa1to3('Z'), 'GLX', 'aa1to3: Z is GLX (GLU or GLN)');
is(aa1to3('J'), 'XLE', 'aa1to3: J is XLE (LEU or ILE)');
is(aa1to3('U'), 'SEC', 'aa1to3: U is SEC (selenocysteine)');
is(aa1to3('O'), 'PYL', 'aa1to3: O is PYL (pyrrolysine)');
is(aa1to3('X'), 'UNK', 'aa1to3: X is UNK');

# the reverse table and the switch in the XS are written out separately, so
# every letter goes back through aa3to1() to prove they still agree
is(aa3to1(aa1to3($_)), $_, "aa1to3 then aa3to1: $_ round-trips") for 'A' .. 'Z';

# the letters aa3to1() can produce are exactly the letters aa1to3() knows: no
# letter is a dead end, and none of the twenty-six is missing
is_deeply([ grep { length aa1to3($_) } 'A' .. 'Z' ], [ 'A' .. 'Z' ],
	'aa1to3: every letter of the alphabet is an amino acid code');

is(aa1to3('a'),   'ALA', 'aa1to3: lower case is accepted');
is(aa1to3(' c '), 'CYS', 'aa1to3: blanks on both sides are ignored');
is(aa1to3(''),    '',    'aa1to3: the empty string has no name');
is(aa1to3('  '),  '',    'aa1to3: blanks alone have no name');
is(aa1to3('AC'),  '',    'aa1to3: two letters are not a single-letter code');
is(aa1to3('1'),   '',    'aa1to3: a digit is not a single-letter code');
is(aa1to3('*'),   '',    'aa1to3: nor is a gap character');

# 'A' is alanine here even though res1(' DA') is also 'A'.  A nucleotide has
# no one-letter answer to give back, and guessing between ALA and DA from a
# bare letter would be wrong half the time.
is(aa1to3('A'), 'ALA', 'aa1to3: A is alanine, not adenine');
is(aa1to3('T'), 'THR', 'aa1to3: T is threonine, not thymine');

#--------
# an undefined name is a mistake worth hearing about: it means a column was
# read out of a record that did not have one
#--------
throws_ok { aa3to1(undef)   } qr/undefined/, 'aa3to1: undef dies';
throws_ok { aa1to3(undef)   } qr/undefined/, 'aa1to3: undef dies';
throws_ok { res1(undef)     } qr/undefined/, 'res1: undef dies';
throws_ok { res_type(undef) } qr/undefined/, 'res_type: undef dies';

done_testing();
