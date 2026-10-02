#!/usr/bin/env perl
# The cases other people's test suites know about.
#
# Two well-tested readers of these formats ship a directory of files each, and
# those directories are thirty years of the format's bad behaviour collected by
# people who had to read it too: gemmi's C<tests/> and Biopython's
# C<Tests/PDB/>.  Reading this module's answer beside gemmi's over both
# directories, and beside Biopython's C<parse_pdb_header> and C<pdb-seqres>
# over a spread of PDBbind, is where every case below came from.  The file each
# one came out of is named against it, so that a case can be looked up in the
# suite that first thought of it.
#
# Most of them are written out here as text rather than shipped as files: they
# are a dozen lines each, and a fixture that can be read in the test that uses
# it says more than a file in another directory does.  The one file that is
# shipped -- t/data/pdb1gdr.ent, a 1993 entry, straight out of gemmi's tests --
# is shipped because what is wrong with it is wrong on every line of it and
# cannot be shown in twelve.
#
# t/oracle.t is the other half of this: it runs the comparison itself, against
# gemmi, over as many structures as are to hand.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::More;

my $data = dirname(abs_path(__FILE__)) . '/data';

# a file that keeps its entry id in columns 73-80
#
# Before 1996 every record of an entry carried the id and a line number in its
# last eight columns, and the archive still distributes the files that were
# deposited that way.  gemmi keeps one as tests/pdb1gdr.ent; it is a 1993
# entry, a CA-only model of gamma delta resolvase.
#
# Every record this module reads to the end of the line is wrong on a file like
# this, and the ways it is wrong are not obvious from the answer: a SEQRES of
# 140 residues comes back 162 long with an X every thirteenth place, an element
# column of '1G' makes 105 atoms of element '1', and the compound is the
# compound plus '1GDR   3'.  None of that looks like a parse failure downstream
# -- it looks like the file.
{
	my $i = structure_info("$data/pdb1gdr.ent");

	is($i->{id}, '1GDR', 'the id comes off the HEADER, not the pdb1gdr file name');
	is($i->{header}{classification}, 'SITE-SPECIFIC RECOMBINASE',
		'and the classification stops at column 50');
	is($i->{header}{deposit_date}, '31-AUG-93', 'and the date is the date');

	# SEQRES holds thirteen residues in columns 20-70 and the stationery after
	# it.  The record says how many residues the chain has, which is the check:
	# a reader that took the whole line would have 162 for a 140-long chain.
	my $s = $i->{seqres}{''};
	ok($s, 'the SEQRES of a file whose chain id column is blank is keyed by ""');
	is($s->{length}, 140, 'SEQRES declares 140 residues');
	is(scalar @{ $s->{residues} }, 140, 'and 140 is what was read off the lines');
	unlike($s->{sequence}, qr/X/, 'so the sequence has no X in it');
	is(substr($s->{sequence}, 0, 12), 'MRLFGYARVSTS', 'and it starts where it should');

	# the coordinates: 105 ATOM records, all of them CA, and columns 77-78 of
	# every one of them hold '1G' -- part of the id, not an element
	is($i->{stats}{n_atoms}, 105, 'every ATOM record was read');
	is_deeply($i->{stats}{elements}, { C => 105 },
		'and the element columns of a file that has none are not believed');
	my $ca = $i->{chains}{''}{residues}{1}{atoms}{CA};
	is($ca->{element}, 'C', 'the element comes from the atom name instead');
	is($ca->{charge}, '', 'and the charge column, which holds "09", reads as empty');

	# the text records: COMPND and SOURCE predate the MOL_ID convention here
	# and are free text, which a reader looking only for 'MOLECULE:' drops
	is($i->{chains}{''}{molecule}, 'GAMMA DELTA RESOLVASE',
		'a free-text COMPND is the molecule of every chain in the file');
	is($i->{chains}{''}{organism}, 'ESCHERICHIA COLI',
		'and a free-text SOURCE is its organism, without the parentheses');
	ok($i->{compound}{1}{free_text}, 'the entity says it was read that way');
	is_deeply($i->{authors}, [ 'P.A.RICE', 'T.A.STEITZ' ],
		'the authors are two authors and not one with a line number on it');
	is($i->{journal}{ref}, 'TO BE PUBLISHED', 'and the journal reference is clean');

	# HELIX carries its length in columns 72-76, where this file has '1GDR'
	is($i->{helix}[0]{init_resname}, 'SER', 'a HELIX record still parses');
	is($i->{helix}[0]{length}, '', 'and a length that is not a number is not a length');

	# a chain with no id at all is a chain, and the module keys it by ''
	is_deeply($i->{chain_order}, [ '' ], 'a blank chain id is one chain');
	is($i->{chains}{''}{type}, 'protein', 'a CA-only model is still a protein');
	is($i->{chains}{''}{n_missing}, 35, 'and it knows what SEQRES has that it does not');
}

# --- the same file name rule, without the file
{
	# _id_from strips the archive's 'pdb' prefix and the '.ent' from a file
	# named the way the archive names them, which is how pdb1gdr.ent would have
	# been read if it had had no HEADER
	my $i = structure_info_string("ATOM      1  CA  ALA A   1      1.000 2.000 3.000\n");
	is($i->{id}, undef, 'a string has no name to take an id from');
}

# --- DBREF1 and DBREF2 ---------------------------------------------------
#
# A cross-reference whose accession or entry name will not fit DBREF's columns
# is written as a pair of lines instead.  Bio.SeqIO.PdbIO of Biopython 1.87
# reads the pair -- the database and entry name off DBREF1, the accession off
# DBREF2 -- and gives 2qtr's chain A the dbxrefs 'UNP:A0A2B6C295' and
# 'UNP:A0A2B6C295_BACAN'.  These are 2qtr's lines for chains A and B; the
# ranges are from the same columns of the wwPDB format v3.3, which Biopython
# reads and does not keep.
{
	my $i = structure_info_string(<<'PDB');
DBREF1 2QTR A    1   189  UNP                  A0A2B6C295_BACAN
DBREF2 2QTR A     A0A2B6C295                          1         189
DBREF1 2QTR B    1   189  UNP                  A0A2B6C295_BACAN
DBREF2 2QTR B     A0A2B6C295                          1         189
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
ATOM      2  CA  ALA B   1      20.000  10.000  10.000  1.00 20.00           C
PDB
	for my $c (qw(A B)) {
		my $d = $i->{dbref}{$c}[0];
		is(join(':', $d->{database}, $d->{accession}), 'UNP:A0A2B6C295',
			"2qtr chain $c: the accession Biopython reads off DBREF2");
		is(join(':', $d->{database}, $d->{db_id}), 'UNP:A0A2B6C295_BACAN',
			"2qtr chain $c: and the entry name it reads off DBREF1");
	}
	is_deeply([ @{ $i->{dbref}{A}[0] }{qw(seq_begin seq_end db_begin db_end)} ],
	          [ 1, 189, 1, 189 ], 'and the two ranges beside them');
	is($i->{chains}{A}{dbref}[0]{accession}, 'A0A2B6C295', 'which the chain carries too');
}

# --- an atom whose first record has no altloc letter
#
# Biopython's Tests/PDB/disordered.pdb writes ARG 27's CZ twice: once with a
# blank altloc column and once as B.  Both are conformers of one atom, and a
# list of them that holds only the lettered one has lost half the answer --
# occupancies that should sum to 1.0 sum to 0.5, and a caller writing the
# conformers back out writes one of the two.
{
	my $i = structure_info_string(<<'PDB');
ATOM    221  NE  ARG A  27      59.504  20.850  26.023  1.00 26.89           N
ATOM    222  CZ  ARG A  27      59.081  20.674  24.762  0.50 26.69           C
ATOM    223  CZ BARG A  27      60.798  20.732  26.326  0.50 26.95           C
ATOM    224  NH1AARG A  27      57.848  21.002  24.386  0.50 27.16           N
ATOM    225  NH1BARG A  27      61.262  21.064  27.522  0.50 27.39           N
PDB
	my $r = $i->{chains}{A}{residues}{27};
	is($r->{n_atoms}, 5, 'both records of a two-conformer atom are counted');
	is_deeply($r->{atom_order}, [qw(NE CZ NH1)], 'and the atom is one atom');

	my $cz = $r->{atoms}{CZ};
	is($cz->{altloc}, '', 'altloc => first takes the first record, blank altloc and all');
	is($cz->{x}, 59.081, 'so the coordinates are that record\'s');
	is(scalar @{ $cz->{altlocs} }, 2, 'and both conformers are on the list');
	is($cz->{altlocs}[0]{altloc}, '', 'the chosen one first');
	is($cz->{altlocs}[1]{altloc}, 'B', 'and the other after it');
	my $sum = 0;
	$sum += $_->{occupancy} for @{ $cz->{altlocs} };
	is($sum, 1, 'so the occupancies of an atom add up to what the file says');

	# the ordinary case, both records lettered, was already right
	my $nh1 = $r->{atoms}{NH1};
	is(scalar @{ $nh1->{altlocs} }, 2, 'a lettered pair is two conformers as well');
	is($nh1->{altlocs}[0]{altloc}, 'A', 'in the order the file wrote them');

	# an atom with one conformer and no letter has no list at all
	is($r->{atoms}{NE}{altlocs}, undef, 'an atom written once has no altlocs list');
}

{
	# altloc => highest changes which record supplies the coordinates and not
	# which records are on the list
	my $i = structure_info_string(<<'PDB', altloc => 'highest');
ATOM    222  CZ  ARG A  27      59.081  20.674  24.762  0.30 26.69           C
ATOM    223  CZ BARG A  27      60.798  20.732  26.326  0.70 26.95           C
PDB
	my $cz = $i->{chains}{A}{residues}{27}{atoms}{CZ};
	is($cz->{altloc}, 'B', 'the highest occupancy wins');
	is(scalar @{ $cz->{altlocs} }, 2, 'and the one it beat is still on the list');
}

# --- a coordinate line that stops early
#
# Biopython's Tests/PDB/occupancy.pdb has a line cut off after the z
# coordinate, which it says is what some programs write.  Occupancy and
# B-factor are then not zero -- zero is a real occupancy, and "no occupancy" is
# not the same answer.
{
	my $i = structure_info_string(<<'PDB');
ATOM      9  N   ASP A 152      21.554  34.953  27.691
ATOM     10  CA  ASP A 152      21.835  36.306  28.144  1.00 20.88           C
ATOM     11  C   ASP A 152      21.947  37.322  27.000  0.00 19.01           C
PDB
	my $r = $i->{chains}{A}{residues}{152};
	is($r->{n_atoms}, 3, 'a short line is still an atom');
	is($r->{atoms}{N}{occupancy}, undef, 'an occupancy the line does not have is undef');
	is($r->{atoms}{N}{bfactor}, undef, 'and so is the B-factor');
	is($r->{atoms}{N}{element}, 'N', 'the element still comes off the name');
	is($r->{atoms}{C}{occupancy}, 0, 'while an occupancy of 0.00 is zero');
	is($i->{stats}{bfactor}{n}, 2, 'and the B-factor statistics count what there was');
}

# --- the same record twice
#
# Biopython's Tests/PDB/a_structure.pdb repeats records to see what a reader
# does with them: an atom written twice identically, and a residue whose second
# copy is named differently.  Neither is a second atom or a second residue.
{
	my $i = structure_info_string(<<'PDB');
ATOM     26  N   GLY A   4      -4.122   9.328  18.863  1.00 15.45           N
ATOM     27  CA  GLY A   4      -4.129  10.656  19.402  1.00 17.05           C
ATOM     28  C   GLY A   4      -5.029  11.674  18.735  1.00 16.11           C
ATOM     29  O   GLY A   4      -6.039  11.345  18.125  1.00 17.88           O
ATOM     29  O   SER A   4      -6.039  11.345  18.125  1.00 17.88           O
PDB
	my $c = $i->{chains}{A};
	is_deeply($c->{residue_order}, [ '4' ], 'a residue named twice is one residue');
	my $r = $c->{residues}{4};
	is($r->{resname}, 'GLY', 'and it keeps the name written first');
	is_deeply($r->{atom_order}, [qw(N CA C O)], 'the repeated atom is one atom');
	is($r->{n_atoms}, 5, 'and both records are counted, which is how the file adds up');
	is($i->{stats}{n_atoms}, 5, 'as they are in the file total');
}

# --- MODEL with no serial number, and atoms outside it
#
# a_structure.pdb opens with a bare 'MODEL' and closes it, then goes on with
# 880 more atoms that are in no model at all.  There is no reading of that
# which is right; what matters is that one reading is given, and that the
# atoms are all somewhere.
{
	my $i = structure_info_string(<<'PDB');
MODEL
ATOM      1  N   PCA A   1       0.525   2.690  13.317  1.00 20.26
ENDMDL
ATOM      2  N   ARG A   2      -2.607   4.673  13.504  1.00 20.57           N
PDB
	is($i->{n_models}, 1, 'a MODEL record with no number does not make a model');
	is($i->{stats}{n_atoms}, 2, 'and no atom is left out of the one there is');
	is($i->{stats}{total_atoms}, 2, 'which is what the file has');
}

# --- a serial number that spills out of its columns -----
#
# a_structure.pdb writes one atom as 'ATOM 111757', which puts the seventh
# digit in column 12 and the first in column 6 -- so columns 1-6 are 'ATOM 1'
# and not 'ATOM  '.  This module reads the record name from its columns, so the
# line is not a coordinate record; what it must not do is lose it silently, and
# it does not: the count of records by name says where it went.
{
	my $i = structure_info_string(<<'PDB');
ATOM    756  CG1 VAL B  52       5.661  -6.261  42.321  1.00 30.99           C
ATOM 111757  CG3 VAL B  52       7.588  -6.386  43.856  1.00 23.53           C
PDB
	is($i->{stats}{n_atoms}, 1, 'a record whose name field is not ATOM is not an atom');
	is($i->{records}{'ATOM 1'}, 1, 'and it is counted under the name it does have');
}

# --- one residue in two chemical states, in mmCIF ------
#
# 3JQH writes residue 1 as PRO in altloc A and SER in altloc B, and 1pfe writes
# a cysteine as N2C and NCY: one position modelled in two chemical states at
# once, which is one residue and not two.  gemmi makes two residues of it,
# which is the other defensible answer; this module makes one, named by the
# state written first, holding the atoms of both so that nothing about either
# is lost.
{
	my $i = structure_info_string(<<'CIF');
data_3jqh
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.label_atom_id
_atom_site.label_alt_id
_atom_site.label_comp_id
_atom_site.label_asym_id
_atom_site.label_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
_atom_site.occupancy
_atom_site.B_iso_or_equiv
_atom_site.auth_seq_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
ATOM 1  N N   A PRO A 1 3.278  21.202 20.087 0.83 56.23 1 PRO A
ATOM 2  C CA  A PRO A 1 3.746  20.507 21.289 0.83 65.19 1 PRO A
ATOM 3  C CB  A PRO A 1 2.447  19.968 21.886 0.83 60.62 1 PRO A
ATOM 4  C CG  A PRO A 1 1.419  20.950 21.455 0.83 52.80 1 PRO A
ATOM 5  N N   B SER A 1 3.302  21.148 20.087 0.17 56.57 1 SER A
ATOM 6  C CA  B SER A 1 3.772  20.496 21.302 0.17 64.89 1 SER A
ATOM 7  C CB  B SER A 1 2.583  20.022 22.135 0.17 60.79 1 SER A
ATOM 8  O OG  B SER A 1 1.653  21.073 22.323 0.17 58.19 1 SER A
CIF
	is($i->{format}, 'mmcif', 'the text was read as mmCIF');
	my $c = $i->{chains}{A};
	is_deeply($c->{residue_order}, [ '1' ], 'two chemical states are one residue');
	my $r = $c->{residues}{1};
	is($r->{resname}, 'PRO', 'named by the state written first');
	is($r->{one}, 'P', 'and its letter is that state\'s');
	is($r->{n_atoms}, 8, 'every record is counted');
	is_deeply([ sort @{ $r->{atom_order} } ], [qw(CA CB CG N OG)],
		'and the atoms that tell the two apart are both there');
	is(scalar @{ $r->{atoms}{CA}{altlocs} }, 2, 'a shared atom has both conformers');
	is($i->{chains}{A}{sequence}, 'P', 'the sequence has one residue in it, not two');
}

# --- the element rules, with no element columns --------
#
# Files written before columns 77-78 existed, and files written by programs
# that ignore them, leave the atom name as the only evidence.  a_structure.pdb
# has a calcium written 'CA  ' and a carbon alpha written ' CA ' in the same
# residue, which is the pair the rule exists for.
{
	my @want = (
		[ ' CA ', 'CA',  'C',  'a name right-justified from column 14 is one letter' ],
		[ 'CA  ', 'CA',  'Ca', 'and one starting in column 13 is two' ],
		[ 'HG11', 'HG11','H',  'a hydrogen that fills the field is not mercury' ],
		[ '1HB ', '1HB', 'H',  'a hydrogen count in column 13 is not an element' ],
		[ 'FE  ', 'FE',  'Fe', 'iron' ],
		[ ' N  ', 'N',   'N',  'nitrogen' ],
		[ 'CL  ', 'CL',  'Cl', 'chlorine' ],
	);
	for my $w (@want) {
		my ($cols, $name, $element, $why) = @$w;
		my $i = structure_info_string(
			sprintf("HETATM    1 %-4s LIG A   1       1.000   2.000   3.000  1.00 10.00\n", $cols));
		my $r = $i->{chains}{A}{residues}{1};
		is($r->{atoms}{$name} && $r->{atoms}{$name}{element}, $element, $why);
	}
}

# The case correction knows the 118 symbols and nothing else, so a field that
# spells no element keeps the spelling the file gave it rather than being
# dressed up as one.  'XX' is not an element and 'Xx' would look like one.
{
	my $line = sprintf("%-76s%-2s\n",
		'HETATM    1  X1  LIG A   1       1.000   2.000   3.000  1.00 10.00', 'XX');
	my $i = structure_info_string($line);
	is($i->{chains}{A}{residues}{1}{atoms}{X1}{element}, 'XX',
		'a two-letter field that is not an element is left as the file wrote it');
	is_deeply($i->{stats}{elements}, { XX => 1 }, 'and is tallied under that spelling');
	is_deeply($i->{chains}{A}{elements}, { XX => 1 }, 'in the chain as well as the structure');
}

# a resolution that is only in REMARK 3
#
# gemmi's tests/5cvz_final.pdb is a refinement program's output: it has the
# whole of REMARK 3 and no REMARK 2 at all.  The high resolution limit of the
# refinement is the same number _refine.ls_d_res_high gives an mmCIF reader,
# which is where this module already takes it from for a .cif, so a file like
# this is not a structure of unknown resolution.
{
	my $i = structure_info_string(<<'PDB');
REMARK   3   RESOLUTION RANGE HIGH (ANGSTROMS) :   3.29
REMARK   3   RESOLUTION RANGE LOW  (ANGSTROMS) : 160.05
REMARK   3   BIN RESOLUTION RANGE HIGH           :    3.291
REMARK   3   R VALUE            (WORKING SET) : 0.239
REMARK   3   FREE R VALUE                     : 0.281
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
PDB
	is($i->{resolution}, 3.29, 'REMARK 3 says the resolution when REMARK 2 does not');
	is($i->{r_work}, 0.239, 'and the R values are still read');
	is($i->{r_free}, 0.281, 'both of them');
}
{
	# REMARK 2 is still the first answer where there is one, and a bin is never
	# the answer
	my $i = structure_info_string(<<'PDB');
REMARK   2 RESOLUTION.    2.60 ANGSTROMS.
REMARK   3   BIN RESOLUTION RANGE HIGH           :    3.291
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
PDB
	is($i->{resolution}, 2.6, 'REMARK 2 wins where the file has one');
}

# --- line endings 
#
# gemmi keeps tests/eol-test.cif for this.  A file that came through a Windows
# machine is read the same as one that did not.
{
	my $pdb = "HEADER    TEST                                    01-JAN-00   1TST\n"
	        . "ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C\n"
	        . "ATOM      2  CA  GLY A   2      11.000  11.000  11.000  1.00 21.00           C\n";
	my $lf   = structure_info_string($pdb);
	(my $crlf_text = $pdb) =~ s/\n/\r\n/g;
	my $crlf = structure_info_string($crlf_text);
	is($crlf->{stats}{n_atoms}, $lf->{stats}{n_atoms}, 'CRLF reads the same atoms');
	is($crlf->{chains}{A}{sequence}, $lf->{chains}{A}{sequence}, 'and the same sequence');
	is($crlf->{id}, $lf->{id}, 'and the same header');
	my $ca = $crlf->{chains}{A}{residues}{1}{atoms}{CA};
	is($ca->{element}, 'C', 'the last field on the line is not the carriage return');
	is($ca->{charge}, '', 'nor is the field after it');
}

# --- a CIF that is not a structure -
#
# gemmi's tests/ has several: HEM.cif and SO3.cif are chemical component
# definitions, 2013551.cif is a small-molecule CIF out of the COD, and
# r5wkdsf.ent is structure factors under a name that says PDB.  None of them
# has an _atom_site loop, and the answer for all of them is a structure with
# nothing in it rather than a die or an invention.
{
	my $ccd = structure_info_string(<<'CIF');
data_HEM
_chem_comp.id                 HEM
_chem_comp.name               "PROTOPORPHYRIN IX CONTAINING FE"
_chem_comp.formula            "C34 H32 Fe N4 O4"
loop_
_chem_comp_atom.comp_id
_chem_comp_atom.atom_id
_chem_comp_atom.type_symbol
HEM FE FE
HEM CHA C
CIF
	is($ccd->{format}, 'mmcif', 'a chemical component definition is still mmCIF');
	is($ccd->{stats}{n_atoms}, 0, 'and it has no atoms, because _atom_site is what atoms are');
	is_deeply($ccd->{chain_order}, [], 'so there are no chains');
	is($ccd->{stats}{total_atoms}, 0, 'and nothing was skipped to get there');

	my $cod = structure_info_string(<<'CIF');
data_2013551
_cell_length_a     10.0
_cell_length_b     11.0
loop_
_atom_site_label
_atom_site_fract_x
C1 0.1234
CIF
	is($cod->{stats}{n_atoms}, 0,
		'a small-molecule CIF has _atom_site_fract_x, which is not _atom_site.Cartn_x');
	is(scalar @{ $cod->{chain_order} }, 0, 'and no chains come out of it');
}

# --- what a chain of one residue is ------------------
#
# gemmi's tests/5wkd.pdb and ions.pdb in Biopython's suite are both mostly
# this: an ion given a chain of its own, which a loop over chain_order asking
# for sequences has to put aside.
{
	my $i = structure_info_string(<<'PDB');
ATOM      1  N   ALA A   1      10.000  10.000  10.000  1.00 20.00           N
ATOM      2  CA  ALA A   1      11.000  10.000  10.000  1.00 20.00           C
ATOM      3  N   GLY A   2      12.000  10.000  10.000  1.00 20.00           N
ATOM      4  CA  GLY A   2      13.000  10.000  10.000  1.00 20.00           C
HETATM    5 ZN    ZN E 101      20.000  20.000  20.000  1.00 25.00          ZN
HETATM    6  S   SO4 F 102      30.000  30.000  30.000  1.00 25.00           S
HETATM    7  O1  SO4 F 102      31.000  30.000  30.000  1.00 25.00           O
HETATM    8  B   BF4 G 103      40.000  40.000  40.000  1.00 25.00           B
HETATM    9  F1  BF4 G 103      41.000  40.000  40.000  1.00 25.00           F
PDB
	ok(is_single_ion($i, 'E'), 'a chain that is one zinc is one residue');
	ok(is_single_ion($i, 'F'), 'and so is a chain that is one sulphate');
	ok(!is_single_ion($i, 'A'), 'a chain of two residues is not');
	is($i->{chains}{E}{residues}{101}{type}, 'ion', 'the zinc is an ion');
	is($i->{chains}{F}{residues}{102}{type}, 'ion', 'and so is a sulphate, which is on the list');
	is($i->{chains}{G}{residues}{103}{type}, 'ligand',
		'while BF4, which is not on it, is a ligand -- a fact about the list');
	is($i->{chains}{E}{residues}{101}{atoms}{ZN}{element}, 'Zn',
		'a two-letter element in columns 77-78 is read whole, and spelled as IUPAC does');
}

# --- the chain is column 22, and column 21 is nothing --------------------
#
# Biopython 1.87's Bio/PDB/PDBParser.py reads the chain as line[21] and the
# residue name as line[17:20], and nothing else: column 21 belongs to no field.
# What a file puts there in practice is the fourth letter of a CHARMM or NAMD
# residue name -- TIP3, POPC -- in a record whose chain column those programs
# leave blank and whose segment id is in columns 73-76 instead.  The two lines
# below are the TIP3 water such a file writes and a two-character chain id, and
# Biopython answers chain ' ' with resname TIP for the first and chain 'B' for
# the second.  This module used to fall back to column 21 whenever column 22
# was blank, which read that water as chain '3'.
#
# gemmi 0.7.5 reads columns 21-22 as one field, and so answers '3' and 'AB'.
# Its reading of the second line is the more generous one, but column 21 is
# not in the format and the first line is what it costs; no entry of PDBbind
# v2020's 10,116 puts anything in column 21 of an ATOM or HETATM record, so the
# two rules part company only on files that were never deposited.
{
	my $p = Chem::Structure::Parser::_parse_string(<<'PDB', {});
ATOM      1  OH2 TIP3    1       1.000   2.000   3.000  1.00  0.00      WT1  O
ATOM      2  CA  ALAAB   1       1.000   2.000   3.000  1.00  0.00           C
PDB
	is_deeply($p->{chain}, [ '', 'B' ],
		'the chain is column 22 alone, as Biopython reads it');
	is_deeply($p->{resname}, [ 'TIP', 'ALA' ],
		'and the residue name is columns 18-20, whatever is beside it');
}

# --- half-sphere exposure counts only CaPPBuilder's polypeptides ----------
#
# Biopython 1.87's Bio/PDB/HSExposure.py builds its residues with
# Bio/PDB/Polypeptide.py's CaPPBuilder, which keeps a standard amino acid only
# when it is next to another in its chain and their CAs are within 4.3 A.  A
# standard residue with no such neighbour is in no polypeptide: it gets no
# figure and counts towards nobody else's.  1a08 is an SH2 domain holding the
# peptide ACE-FTY-GLU-DIP, whose one standard residue is that GLU C102.  Below
# are the N, CA, C and CB of chain A 203-206 and of chain C 101-103, cut out of
# the entry's own lines, and HSExposureCB's answer on exactly that text:
# LYS 203 1/2, HIS 204 1/2, TYR 205 0/3, LYS 206 0/3, and nothing on chain C.
# This module used to give the GLU 3/1 and count it towards all four.
{
	my $i = structure_info_string(<<'PDB');
ATOM    544  N   LYS A 203      37.699  14.856  24.059  1.00 18.02           N
ATOM    545  CA  LYS A 203      37.937  13.704  23.194  1.00 14.80           C
ATOM    546  C   LYS A 203      39.428  13.801  22.827  1.00 14.75           C
ATOM    548  CB  LYS A 203      37.167  13.753  21.858  1.00 20.10           C
ATOM    557  N   HIS A 204      40.198  12.720  22.786  1.00 13.24           N
ATOM    558  CA  HIS A 204      41.613  12.816  22.485  1.00 12.61           C
ATOM    559  C   HIS A 204      41.843  12.008  21.219  1.00 14.48           C
ATOM    561  CB  HIS A 204      42.465  12.234  23.594  1.00  8.01           C
ATOM    570  N   TYR A 205      42.592  12.474  20.251  1.00 14.67           N
ATOM    571  CA  TYR A 205      42.820  11.792  18.990  1.00 13.05           C
ATOM    572  C   TYR A 205      44.321  11.556  18.864  1.00 14.08           C
ATOM    574  CB  TYR A 205      42.330  12.679  17.882  1.00 12.71           C
ATOM    584  N   LYS A 206      44.850  10.330  18.893  1.00 12.80           N
ATOM    585  CA  LYS A 206      46.275  10.152  18.761  1.00 11.66           C
ATOM    586  C   LYS A 206      46.779  10.644  17.406  1.00 13.75           C
ATOM    588  CB  LYS A 206      46.516   8.663  19.009  1.00 14.90           C
HETATM 1025  N   FTY C 101      41.611   7.121  23.475  1.00 15.39           N
HETATM 1026  CA  FTY C 101      41.464   7.847  22.229  1.00 17.53           C
HETATM 1027  C   FTY C 101      40.236   7.389  21.460  1.00 13.42           C
HETATM 1029  CB  FTY C 101      42.750   7.655  21.404  1.00 14.75           C
ATOM   1044  N   GLU C 102      39.853   8.264  20.562  1.00 14.85           N
ATOM   1045  CA  GLU C 102      38.741   8.062  19.674  1.00 16.19           C
ATOM   1046  C   GLU C 102      39.175   7.311  18.407  1.00 19.94           C
ATOM   1048  CB  GLU C 102      38.190   9.390  19.305  1.00 21.28           C
HETATM 1054  N   DIP C 103      38.340   6.458  17.692  1.00 18.28           N
END
PDB
	my $A = $i->{chains}{A}{residues};
	is_deeply([ map { [ $A->{$_}{hse_up}, $A->{$_}{hse_down} ] } 203 .. 206 ],
		[ [ 1, 2 ], [ 1, 2 ], [ 0, 3 ], [ 0, 3 ] ],
		"1a08: HSExposureCB's figures, with the lone GLU counted by nobody");
	ok(!exists $i->{chains}{C}{residues}{102}{hse_up},
		'and the GLU itself, in no polypeptide, has none');
}

# --- a side chain without its CB has no half-sphere exposure --------------
#
# HSExposureCB._get_cb(), in the same Biopython 1.87 file, builds the virtual CB
# for a GLY and for nothing else: any other residue with no CB has no side
# chain direction and no figure, though its CA still counts towards its
# neighbours'.  5x0w deposits several side chains cut back to the backbone; this
# is its chain A 513-517, N, CA, C and CB as written, where SER 515 is one of
# them and GLY 516 is a real glycine.  HSExposureCB on exactly this text gives
# GLN 513 0/4, TYR 514 0/4, nothing for SER 515, GLY 516 1/3 and THR 517 1/3.
# This module used to build the glycine CB for the serine as well.
{
	my $i = structure_info_string(<<'PDB');
ATOM    224  N   GLN A 513      57.243   0.314  12.333  1.00 70.39           N
ATOM    225  CA  GLN A 513      56.432   1.106  11.413  1.00 76.22           C
ATOM    226  C   GLN A 513      55.654   2.205  12.124  1.00 83.94           C
ATOM    228  CB  GLN A 513      55.460   0.207  10.646  1.00 69.43           C
ATOM    230  N   TYR A 514      55.259   1.992  13.377  1.00 92.76           N
ATOM    231  CA  TYR A 514      54.586   3.033  14.154  1.00 97.80           C
ATOM    232  C   TYR A 514      55.631   3.725  15.028  1.00 97.01           C
ATOM    234  CB  TYR A 514      53.446   2.437  14.974  1.00103.44           C
ATOM    242  N   SER A 515      56.205   4.818  14.524  1.00 93.49           N
ATOM    243  CA  SER A 515      57.299   5.496  15.214  1.00 91.80           C
ATOM    244  C   SER A 515      58.549   4.626  15.300  1.00 93.82           C
ATOM    246  N   GLY A 516      59.426   4.746  14.304  1.00 96.22           N
ATOM    247  CA  GLY A 516      60.592   3.893  14.175  1.00 99.02           C
ATOM    248  C   GLY A 516      61.570   3.930  15.331  1.00100.95           C
ATOM    250  N   THR A 517      61.194   3.331  16.458  1.00106.65           N
ATOM    251  CA  THR A 517      62.124   3.176  17.568  1.00112.89           C
ATOM    252  C   THR A 517      63.289   2.275  17.174  1.00120.70           C
ATOM    254  CB  THR A 517      61.398   2.598  18.783  1.00112.44           C
END
PDB
	my $A = $i->{chains}{A}{residues};
	is_deeply([ map { [ $A->{$_}{hse_up}, $A->{$_}{hse_down} ] } 513, 514, 516, 517 ],
		[ [ 0, 4 ], [ 0, 4 ], [ 1, 3 ], [ 1, 3 ] ],
		"5x0w: HSExposureCB's figures, the serine's CA counted");
	ok(!exists $A->{515}{hse_up}, 'and the serine with no CB has none of its own');
}

# --- an edge-to-face stack is found whichever ring comes first ------------
#
# mdtraj 1.11.1's mdtraj/geometry/pi_stacking.py projects its first group's
# centroid onto the line where the two ring planes meet, and measures the
# second group's from that projected point rather than from the line, so the
# one pair can be a stack or not depending on which ring it is handed first.
# These are the ring atoms of TRP A59 and PHE A99 of 1b6c, as the entry writes
# them: pi_stacking() with the defaults structure_pi_stacking() takes finds the
# six-membered rings edge-stacked when handed PHE first and not when handed TRP
# first.  PHE's centroid is 0.66 A from the line, TRP's 5.06 A.  This module
# takes the centroid nearer the line, which is the union of mdtraj's two
# answers; it used to take the tryptophan first, as it comes in the file, and
# miss the pair.
{
	my $i = structure_info_string(<<'PDB');
ATOM    463  CG  TRP A  59     -33.314  11.911 -26.717  1.00 38.02           C
ATOM    464  CD1 TRP A  59     -34.137  10.904 -27.118  1.00 37.63           C
ATOM    465  CD2 TRP A  59     -33.909  12.471 -25.545  1.00 37.69           C
ATOM    466  NE1 TRP A  59     -35.209  10.799 -26.269  1.00 37.45           N
ATOM    467  CE2 TRP A  59     -35.094  11.749 -25.292  1.00 37.51           C
ATOM    468  CE3 TRP A  59     -33.555  13.513 -24.679  1.00 37.34           C
ATOM    469  CZ2 TRP A  59     -35.932  12.033 -24.215  1.00 37.56           C
ATOM    470  CZ3 TRP A  59     -34.391  13.797 -23.604  1.00 37.34           C
ATOM    471  CH2 TRP A  59     -35.566  13.057 -23.383  1.00 37.43           C
ATOM    760  CG  PHE A  99     -38.090   9.137 -26.757  1.00 34.52           C
ATOM    761  CD1 PHE A  99     -37.240   8.452 -27.621  1.00 34.57           C
ATOM    762  CD2 PHE A  99     -37.954   8.948 -25.384  1.00 33.74           C
ATOM    763  CE1 PHE A  99     -36.251   7.598 -27.129  1.00 34.18           C
ATOM    764  CE2 PHE A  99     -36.982   8.103 -24.885  1.00 34.27           C
ATOM    765  CZ  PHE A  99     -36.121   7.425 -25.766  1.00 34.19           C
END
PDB
	my %got = map { ("$_->{ring1}$_->{ring2}" => $_) } @{ $i->{features}{pi_stacking} };
	ok($got{66} && $got{66}{type} eq 'edge',
		"1b6c: TRP A59 and PHE A99's six-membered rings are edge-stacked");
	# 0.660559745 A is the same geometry over mdtraj's coordinates, which are
	# float32 nanometres; this reads 0.660558301 from the file's decimals.  The
	# 1.4e-6 A between them is about one float32 ulp of a coordinate 40 A out
	# (2.4e-6 A), and 1e-5 leaves four of those
	ok($got{66} && abs($got{66}{intersect_distance} - 0.660559745) < 1e-5,
		'at the distance mdtraj measures with PHE first');
}

# --- residue and serial numbers past the decimal columns -------------------
#
# A four-column residue number and a five-column serial are written in
# hybrid-36 once they run out: Grosse-Kunstleve's encoding, which cctbx, phenix
# and gemmi write, defined at https://cci.lbl.gov/hybrid_36/ with the reference
# hy36decode() in hybrid_36_c.c.  t/data/numbering.pdb crosses the first
# boundary of both fields, and gemmi 0.7.5 reads it as below.  Before this was
# decoded, A000 and A001 were not numbers, both came back as the empty key, and
# the three waters were one residue whose oxygen had three 'alternate
# conformers'.
{
	my $i = structure_info("$data/numbering.pdb", features => 0);
	my $w = $i->{chains}{W};
	is_deeply($w->{residue_order}, [qw(9999 10000 10001)],
		'hybrid-36 residue numbers are the numbers gemmi reads: A000 is 10000');
	is_deeply([ map { $w->{residues}{$_}{atoms}{O}{serial} } @{ $w->{residue_order} } ],
		[ 99998, 99999, 100000 ], 'and a hybrid-36 serial too: A0000 is 100000');
	ok(!grep({ $w->{residues}{$_}{atoms}{O}{altlocs} } @{ $w->{residue_order} }),
		'three waters are three atoms, and not one atom with three conformers');

	# a water numbered 0 beside one with no number: gemmi has two residues,
	# numbered 0 and None
	my $y = $i->{chains}{Y};
	is_deeply($y->{residue_order}, [ '0', '' ],
		'a residue with no number is not the residue numbered 0 before it');
	ok(!defined $y->{residues}{''}{number}, 'and its number is undef');
}
# The lower-case half, against the reference rather than against gemmi, which
# decodes base 36 without regard to case and so reads 'a000' as 10000, the same
# number as 'A000'.  The values are the reference's: the first lower-case number
# of width four is 10000 + 26 * 36**3, and 'zzzz' and 'zzzzz' are the largest
# numbers the two widths hold, 2436111 and 87440031.  A field that mixes the two
# cases is not hybrid-36 and is no number at all.
{
	my $rec = sub {
		my ($ser, $num) = @_;
		return sprintf("HETATM%5s  O   HOH W%4s       1.000   1.000   1.000  1.00 20.00           O\n",
		               $ser, $num);
	};
	my $i = structure_info_string($rec->('a0000', 'a000') . $rec->('zzzzz', 'zzzz')
	                              . $rec->('9', 'A00a'), features => 0);
	my $w = $i->{chains}{W};
	is_deeply($w->{residue_order}, [ '1223056', '2436111', '' ],
		'lower-case hybrid-36 follows the upper-case range, to zzzz = 2436111');
	is($w->{residues}{1223056}{atoms}{O}{serial}, 43770016, 'a0000 is 100000 + 26 * 36**4');
	is($w->{residues}{2436111}{atoms}{O}{serial}, 87440031, 'and zzzzz is 87440031');
	ok(!defined $w->{residues}{''}{number}, 'a field that mixes the cases is not a number');
}

done_testing();
