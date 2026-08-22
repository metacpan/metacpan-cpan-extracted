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
require 5.010;
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

done_testing();
