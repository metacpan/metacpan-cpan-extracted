#!/usr/bin/env perl
# The header and annotation records, which is everything above the
# coordinates: who made the structure, how, out of what, and what is bonded
# to what.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

my $data = dirname(abs_path(__FILE__)) . '/data';
my $i = structure_info("$data/mini.pdb");

#--------
# HEADER, TITLE
#--------
is($i->{header}{classification}, 'HYDROLASE/PEPTIDE INHIBITOR', 'HEADER: classification');
is($i->{header}{deposit_date},   '01-JAN-20', 'HEADER: deposition date');
is($i->{header}{id_code},        '9XYZ',      'HEADER: id code');
is($i->{title},
	'A SMALL TEST STRUCTURE WITH A GAP, AN INSERTION CODE, AN ALTERNATE CONFORMER AND A LIGAND',
	'TITLE: continuation lines are joined with a space');

#--------
# KEYWDS -- the awkward one.  A keyword can break across lines mid-word with
# a hyphen, and the two halves must not be joined with a space in between.
#--------
is_deeply($i->{keywords},
	[ 'HYDROLASE', 'TEST STRUCTURE', 'COMPLEX (HYDROLASE-PEPTIDE)' ],
	'KEYWDS: split on commas, and a hyphenated word broken across lines is rejoined without a space');

#--------
# EXPDTA, AUTHOR, REVDAT, NUMMDL
#--------
is_deeply($i->{experiment}, [ 'X-RAY DIFFRACTION' ], 'EXPDTA');
is_deeply($i->{authors}, [ 'D.E.CONDON', 'A.N.OTHER' ], 'AUTHOR: split on commas');
is($i->{n_models_declared}, 1, 'NUMMDL');
is($i->{revdat}[0]{date}, '01-JAN-20', 'REVDAT');

#--------
# JRNL, whose sub-record name is in columns 13-16
#--------
is_deeply($i->{journal}{auth}, [ 'D.E.CONDON', 'A.N.OTHER' ], 'JRNL AUTH');
is($i->{journal}{titl}, 'A STRUCTURE MADE UP FOR A TEST SUITE, AND WHAT IT CONTAINS',
	'JRNL TITL, continued across two lines');
is($i->{journal}{pmid}, '12345678', 'JRNL PMID');
is($i->{journal}{doi}, '10.1000/INVENTED.2020.42', 'JRNL DOI');
like($i->{journal}{ref}, qr/J\.INVENTED\.RES\./, 'JRNL REF');

#--------
# REMARKs.  The useful numbers are pulled out; the rest are kept by number.
#--------
is($i->{resolution}, 1.85, 'REMARK 2: resolution');
is($i->{r_work}, 0.174, 'REMARK 3: R work');
is($i->{r_free}, 0.219, 'REMARK 3: R free');
isnt($i->{r_free}, 0.999,
	'REMARK 3: BIN FREE R VALUE is not mistaken for the R free');
is($i->{temperature}, 100.0, 'REMARK 200: temperature');
is($i->{ph}, 7.5, 'REMARK 200: pH');
is(ref $i->{remarks}, 'HASH', 'remarks are kept by number');
ok(scalar @{ $i->{remarks}{465} }, 'including the ones nothing is pulled out of');
like($i->{remarks}{2}[1], qr/RESOLUTION/, 'and they are the text of the record');

#--------
# COMPND and SOURCE, which are "TOKEN: value;" lists grouped by MOL_ID
#--------
is($i->{compound}{1}{molecule}, 'TEST PROTEIN', 'COMPND: molecule of entity 1');
is_deeply($i->{compound}{1}{chain}, ['A'], 'COMPND: chain list is split');
is($i->{compound}{1}{engineered}, 'YES', 'COMPND: other tokens are kept as they come');
is($i->{compound}{2}{molecule}, 'TEST DNA', 'COMPND: a second MOL_ID starts a second entity');
is($i->{source}{1}{organism_scientific}, 'HOMO SAPIENS', 'SOURCE: organism');
is($i->{source}{1}{organism_taxid}, '9606', 'SOURCE: taxid');
is($i->{source}{2}{synthetic}, 'YES', 'SOURCE: the second entity');

# the shapes of that record an entry is allowed to have and mini.pdb does not:
# a first entity that never says MOL_ID, a token given twice, and the stray
# semicolons a depositor leaves behind
{
	my $c = structure_info_string(<<'PDB');
HEADER    TEST                                    01-JAN-94   9XYZ
COMPND    MOLECULE: FIRST THING;;
COMPND   2 CHAIN: A, B;
COMPND   3 OTHER_DETAILS: SOMETHING;
COMPND   4 OTHER_DETAILS: AND MORE;
COMPND   5 MOL_ID: 2;
COMPND   6 MOLECULE: SECOND THING;
COMPND   7 CHAIN: C;
SOURCE    ORGANISM_SCIENTIFIC: HOMO SAPIENS;
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
ATOM      2  CA  ALA B   1      12.000  10.000  10.000  1.00 20.00           C
ATOM      3  CA  ALA C   1      14.000  10.000  10.000  1.00 20.00           C
PDB
	is($c->{compound}{1}{molecule}, 'FIRST THING',
		'COMPND: an entity that never names a MOL_ID is entity 1');
	is($c->{compound}{1}{other_details}, 'SOMETHING AND MORE',
		'COMPND: a token given twice is joined rather than overwritten');
	is_deeply($c->{compound}{1}{chain}, [ 'A', 'B' ], 'COMPND: with both its chains');
	is($c->{compound}{2}{molecule}, 'SECOND THING', 'COMPND: and the MOL_ID after it is its own');
	is($c->{chains}{B}{molecule}, 'FIRST THING', 'every chain of an entity is that molecule');
	is($c->{chains}{C}{molecule}, 'SECOND THING', 'and the next entity names its own');
	is($c->{chains}{A}{organism}, 'HOMO SAPIENS',
		'a SOURCE with no MOL_ID belongs to the first entity, as the COMPND did');
}

#--------
# SEQRES, DBREF, SEQADV, MODRES
#--------
is_deeply($i->{seqres}{A}{residues},
	[ qw(MET ALA GLY LEU LYS CYS MSE HIS HIS SER CYS) ],
	'SEQRES: the three-letter residues, in order');
is($i->{seqres}{A}{length}, 11, 'SEQRES: the declared length');
is($i->{seqres}{A}{sequence}, 'MAGLKCMHHSC', 'SEQRES: as single letters');
is($i->{dbref}{A}[0]{database},  'UNP',        'DBREF: database');
is($i->{dbref}{A}[0]{accession}, 'P12345',     'DBREF: accession');
is($i->{dbref}{A}[0]{db_id},     'TEST_HUMAN', 'DBREF: entry name');
is($i->{seqadv}[0]{resname}, 'MSE', 'SEQADV: the residue that differs');
is($i->{seqadv}[0]{database}, 'UNP', 'SEQADV: the database it differs from');
is($i->{seqadv}[0]{comment}, 'MODIFIED RESIDUE', 'SEQADV: why');
is($i->{modres}{MSE}{standard}, 'MET', 'MODRES: what the modified residue stands for');

#--------
# heterogens
#--------
is($i->{het}{NAG}{name}, '2-ACETAMIDO-2-DEOXY-BETA-D-GLUCOPYRANOSE', 'HETNAM');
is($i->{het}{NAG}{formula}, 'C8 H15 N O6', 'FORMUL');
is($i->{het}{NAG}{instances}[0]{chain}, 'A', 'HET: which chain the heterogen is in');
is($i->{het}{NAG}{instances}[0]{natoms}, '14', 'HET: how many atoms it should have');
is($i->{het}{ZN}{name}, 'ZINC ION', 'HETNAM for a two-letter het id');
is($i->{het}{HOH}{water}, 1, 'FORMUL: the asterisk marks the water');

#--------
# secondary structure and bonds
#--------
is($i->{helix}[0]{init_resname}, 'MET', 'HELIX: first residue');
is($i->{helix}[0]{end_resseq},   '3',   'HELIX: last residue');
is($i->{helix}[0]{init_chain},   'A',   'HELIX: chain');
is($i->{sheet}[0]{init_resname}, 'CYS', 'SHEET: first residue');
is($i->{sheet}[0]{n_strands},    '2',   'SHEET: strand count');
is_deeply($i->{ssbond}[0], { chain1 => 'A', resseq1 => '6', chain2 => 'A', resseq2 => '10', length => '2.03' },
	'SSBOND: both ends and the distance');
is($i->{link}[0]{name1}, 'ZN',  'LINK: first atom');
is($i->{link}[0]{chain1}, 'A',  'LINK: first chain, which is two columns right of the residue name');
is($i->{link}[0]{name2}, 'SG',  'LINK: second atom');
is($i->{link}[0]{resseq2}, '6', 'LINK: second residue');
is($i->{cispep}[0]{resname1}, 'GLY', 'CISPEP');
is($i->{cispep}[0]{angle}, '-0.42', 'CISPEP: the measured angle');

#--------
# crystal and connectivity
#--------
is($i->{cryst1}{a}, 40.1, 'CRYST1: a');
is($i->{cryst1}{b}, 50.2, 'CRYST1: b');
is($i->{cryst1}{c}, 60.3, 'CRYST1: c');
is($i->{cryst1}{alpha}, 90, 'CRYST1: alpha');
is($i->{cryst1}{beta}, 95.5, 'CRYST1: beta');
is($i->{cryst1}{sgroup}, 'P 1 21 1', 'CRYST1: space group');
is($i->{cryst1}{z}, '4', 'CRYST1: Z');
is_deeply($i->{conect}[0], [ '57', '58', '59' ], 'CONECT: the bonded serial numbers');

#--------
# a tally of every record in the file, so that a record the module does not
# parse can still be seen to be there
#--------
is($i->{records}{REMARK}, 9, 'records: how many of each record the file has');
is($i->{records}{SEQRES}, 2, 'records: SEQRES');
ok(exists $i->{records}{MASTER}, 'records: even the ones nothing is done with');

#--------
# meta => 0 skips all of it
#--------
{
	my $n = structure_info("$data/mini.pdb", meta => 0);
	is($n->{title}, undef, 'meta => 0: no header parsing');
	is($n->{chains}{A}{sequence}, 'MAGCMHHSC', 'but the coordinates are still read');
	is($n->{id}, 'MINI', 'and the id falls back to the file name');
}

#--------
# Header fields that are not what they are declared to be.  These are not
# hypothetical: every one is taken from an entry in PDBbind v2020, and each of
# them used to be fatal or wrong.
#--------
{
	# 5m04 writes its pH as a range, with a stray dot in it
	my $i = structure_info_string(<<'PDB');
REMARK 200  TEMPERATURE           (KELVIN) : 100
REMARK 200  PH                             : 5.4.-5.8
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
PDB
	is($i->{ph}, 5.4, 'a pH written as "5.4.-5.8" gives up the number in it rather than dying');
	is($i->{temperature}, 100, 'and the temperature beside it is unharmed');
}
{
	# an unrefined structure has NULL where its R values should be
	my $i = structure_info_string(<<'PDB');
REMARK   3   R VALUE            (WORKING SET) : NULL
REMARK   3   FREE R VALUE                     : NULL
REMARK   2 RESOLUTION.    NULL ANGSTROMS.
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
PDB
	is($i->{r_work}, undef, 'an R value of NULL stays undef rather than becoming zero');
	is($i->{r_free}, undef, 'and so does the R free');
	is($i->{resolution}, undef, 'and the resolution');
}
{
	# right-trimmed annotation records: the field the parser wants is simply
	# past the end of the line.  15 of the 10,116 entries in PDBbind v2020 have
	# one, and a bare substr() dies on every one of them.
	my $i = structure_info_string(<<'PDB');
HELIX    1 AA1 MET A    1  GLY A    3  1
SHEET    1 AA1 2 CYS A   6  HIS A   8
SSBOND   1 CYS A    6    CYS A   10
CRYST1   40.100   50.200   60.300  90.00  95.50  90.00
HET    NAG  A 201
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
PDB
	is($i->{helix}[0]{init_resname}, 'MET', 'a HELIX record with no length on it still parses');
	is($i->{helix}[0]{length}, '', 'and the field it does not have reads as empty');
	is($i->{sheet}[0]{init_resname}, 'CYS', 'a SHEET record with no sense field parses');
	is($i->{sheet}[0]{sense}, '', 'and its missing field is empty');
	is($i->{ssbond}[0]{resseq2}, '10', 'an SSBOND with no symmetry or distance parses');
	is($i->{cryst1}{gamma}, 90, 'a CRYST1 with no space group parses');
	is($i->{cryst1}{sgroup}, '', 'and the space group is empty');
	is($i->{het}{NAG}{instances}[0]{chain}, 'A', 'a HET record with no atom count parses');
}
{
	# The records an entry has one of and most entries have none of.  Each is
	# one line of the reader and they are grouped here rather than spread over
	# the fixtures, because a fixture carrying all of them at once would not be
	# a structure anybody deposited.  The columns are built with sprintf where
	# they are not obvious, because a hand-typed record shifts a column
	# silently -- which is the reason t/data is generated rather than typed.
	my $seqres = sprintf('SEQRES %3d %s %4s  %s', 1, 'A', '??', 'ALA GLY SER');
	is(length $seqres, 30, 'the SEQRES line puts its residues in column 20');
	my $pdb = <<"PDB";
HEADER    HYDROLASE                               01-JAN-94   9XYZ
OBSLTE     31-JAN-94 9XYZ      2ABC
CAVEAT     9XYZ    CHIRALITY ERROR AT CA OF RESIDUE 12
SPLIT      1VOQ 1VOR 1VOS
MDLTYP    CA ATOMS ONLY, CHAIN A, B
NUMMDL    20
$seqres
JRNL
JRNL        AUTH   A.B.SMITH,C.D.JONES
JRNL        TITL   A PAPER ABOUT A
JRNL        TITL 2 STRUCTURE
REMARK
CONECT 1179  746 1184 1195 1203
CONECT 1180
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
ATOM      2  CA  GLY A   2      13.000  10.000  10.000  1.00 20.00           C
ATOM      3  CA  SER A   3      16.000  10.000  10.000  1.00 20.00           C
PDB
	my $h = structure_info_string($pdb);
	is($h->{caveat}, 'CHIRALITY ERROR AT CA OF RESIDUE 12',
		'CAVEAT is read, with the entry id cut off the front of the text');
	is($h->{obsolete}, '31-JAN-94 9XYZ      2ABC', 'OBSLTE is kept whole');
	is_deeply($h->{split}, [ '1VOQ', '1VOR', '1VOS' ], 'SPLIT is a list of entry ids');
	is($h->{model_type}, 'CA ATOMS ONLY, CHAIN A, B', 'MDLTYP is kept as written');
	is($h->{n_models_declared}, 20,
		'NUMMDL says how many models the file claims, which is not how many it has');
	is($h->{n_models}, 1, 'and the count of the ones that are really there is its own key');
	is($h->{journal}{titl}, 'A PAPER ABOUT A STRUCTURE',
		'a JRNL sub-record continued across two lines is glued back together');
	is_deeply($h->{journal}{auth}, [ 'A.B.SMITH', 'C.D.JONES' ],
		'and the authors are a list');
	# a JRNL or REMARK line with nothing on it names no sub-record and no
	# number, and is passed over rather than filed under the empty string
	ok(!exists $h->{journal}{''}, 'a JRNL line with no sub-record is not a sub-record');
	ok(!exists $h->{remarks}{''}, 'and a REMARK with no number is not a remark');
	is_deeply($h->{conect}, [ [ 1179, 746, 1184, 1195, 1203 ] ],
		'CONECT gives the atom and what it is bonded to');
	is($h->{records}{CONECT}, 2,
		'both CONECT lines were read, though the one bonded to nothing is not a bond');
	is($h->{seqres}{A}{length}, 3,
		'a SEQRES whose residue count is not a number is as long as the residues it lists');
	is($h->{seqres}{A}{sequence}, 'AGS', 'and the residues themselves are read as usual');
}
{
	# A numeric field that is digits and dots and is not a number.  The archive
	# writes them -- 5m04's pH is '5.4.-5.8' -- and the cell edge below is the
	# same shape in a field that is read with _n().  It used to match a pattern
	# of "digits and dots" and then be added to 0, which under
	# warnings FATAL => 'all' took the whole read down with
	# `Argument "1.2.3" isn't numeric in addition (+)'; a field that is not a
	# number is undef, which is what every other unreadable field here gives.
	my $i;
	lives_ok { $i = structure_info_string(<<'PDB') } 'a CRYST1 with a malformed cell edge is read';
CRYST1    1.2.3   50.200   60.300  90.00  95.50  90.00 P 1           1
ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C
PDB
	is($i->{cryst1}{a}, undef, 'and the field that is not a number reads as undef');
	is($i->{cryst1}{b}, 50.2,  'while the fields beside it are unharmed');
	is($i->{cryst1}{sgroup}, 'P 1', 'and so is the rest of the record');
}

done_testing();
