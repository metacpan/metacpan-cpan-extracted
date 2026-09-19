#!/usr/bin/env perl
# Writes the fixtures in this directory.
#
# The fixtures are generated rather than typed because a PDB record is a
# fixed-column format: an atom name in the wrong column is a different
# element, and a residue number shifted by one is a different residue.  Hand
# editing gets that wrong silently.  Run this from t/data/ after changing a
# fixture, and commit both the script and what it wrote.
require 5.010;
use strict;
use warnings FATAL => 'all';
use autodie ':default';

# atom_line() -- one ATOM/HETATM record, in the columns the format wants.
#
# The atom name is the fiddly part: a one-letter element is right-justified
# from column 14 (" CA " is a carbon alpha), a two-letter element starts in
# column 13 ("CA  " is a calcium).  That is the rule the parser's element
# guess relies on, so the fixtures have to follow it exactly.
sub atom_line {
	my (%a) = @_;
	my $name = length($a{element}) == 2 || length($a{name}) == 4
	         ? sprintf('%-4s', $a{name})
	         : sprintf(' %-3s', $a{name});
	return sprintf(
		'%-6s%5d %4s%1s%3s %1s%4d%1s   %8.3f%8.3f%8.3f%6.2f%6.2f          %2s%-2s',
		$a{record}, $a{serial}, $name, ($a{altloc} // ''), $a{resname},
		$a{chain}, $a{resseq}, ($a{icode} // ''),
		$a{x}, $a{y}, $a{z}, ($a{occ} // 1), ($a{b} // 20),
		$a{element}, ($a{charge} // '')
	);
}

my $serial = 0;
sub atom {
	my ($rec, $chain, $resname, $resseq, $icode, $atoms, $base) = @_;
	my @out;
	my $i = 0;
	for my $a (@$atoms) {
		my ($name, $element, $altloc, $occ) = @$a;
		$serial++;
		push @out, atom_line(
			record => $rec, serial => $serial, name => $name, element => $element,
			altloc => $altloc, resname => $resname, chain => $chain,
			resseq => $resseq, icode => $icode,
			x => $base->[0] + $i * 1.5, y => $base->[1] + $i, z => $base->[2] + $i * 0.5,
			occ => $occ, b => 15 + $i,
		);
		$i++;
	}
	return @out;
}

# backbone of a residue, plus whatever side-chain atoms are named
sub bb { my @s = @_; return ([ 'N', 'N' ], [ 'CA', 'C' ], [ 'C', 'C' ], [ 'O', 'O' ], @s) }

# cols() -- build a record by column number rather than by counting spaces.
# Takes (start, width, value) triples, with start being the 1-based column the
# format specification gives, optionally followed by 'R' for a right-justified
# field.  Records below can then be checked against the spec by reading the
# numbers rather than counting anything.
sub cols {
	my @spec = @_;
	my $line = ' ' x 80;
	while (@spec) {
		my ($start, $width, $value) = splice @spec, 0, 3;
		# a start column is always a number, so an 'R' here is this field's
		# justification and not the beginning of the next one
		my $just = (@spec && defined $spec[0] && $spec[0] =~ /\A[LR]\z/) ? shift(@spec) : 'L';
		$value = '' unless defined $value;
		$value = $just eq 'R' ? sprintf('%*s', $width, $value)
		                      : sprintf('%-*s', $width, $value);
		substr($line, $start - 1, $width) = substr($value, 0, $width);
	}
	$line =~ s/\s+\z//;
	return $line;
}

# --- mini.pdb -- one of everything the reader knows how to look at ---------
my @mini = (
'HEADER    HYDROLASE/PEPTIDE INHIBITOR             01-JAN-20   9XYZ              ',
'TITLE     A SMALL TEST STRUCTURE WITH A GAP, AN INSERTION CODE, AN              ',
'TITLE    2 ALTERNATE CONFORMER AND A LIGAND                                     ',
'COMPND    MOL_ID: 1;                                                            ',
'COMPND   2 MOLECULE: TEST PROTEIN;                                              ',
'COMPND   3 CHAIN: A;                                                            ',
'COMPND   4 EC: 3.4.21.5;                                                        ',
'COMPND   5 ENGINEERED: YES;                                                     ',
'COMPND   6 MOL_ID: 2;                                                           ',
'COMPND   7 MOLECULE: TEST DNA;                                                  ',
'COMPND   8 CHAIN: B                                                             ',
'SOURCE    MOL_ID: 1;                                                            ',
'SOURCE   2 ORGANISM_SCIENTIFIC: HOMO SAPIENS;                                   ',
'SOURCE   3 ORGANISM_COMMON: HUMAN;                                              ',
'SOURCE   4 ORGANISM_TAXID: 9606;                                                ',
'SOURCE   5 EXPRESSION_SYSTEM: ESCHERICHIA COLI;                                 ',
'SOURCE   6 MOL_ID: 2;                                                           ',
'SOURCE   7 SYNTHETIC: YES                                                       ',
'KEYWDS    HYDROLASE, TEST STRUCTURE, COMPLEX (HYDROLASE-                        ',
'KEYWDS   2 PEPTIDE)                                                             ',
'EXPDTA    X-RAY DIFFRACTION                                                     ',
'NUMMDL    1                                                                     ',
'AUTHOR    D.E.CONDON,A.N.OTHER                                                  ',
'REVDAT   1   01-JAN-20 9XYZ    0                                                ',
'JRNL        AUTH   D.E.CONDON,A.N.OTHER                                         ',
'JRNL        TITL   A STRUCTURE MADE UP FOR A TEST SUITE, AND WHAT IT            ',
'JRNL        TITL 2 CONTAINS                                                     ',
'JRNL        REF    J.INVENTED.RES.               V.  10    42 2020              ',
'JRNL        PMID   12345678                                                     ',
'JRNL        DOI    10.1000/INVENTED.2020.42                                     ',
'REMARK   2                                                                      ',
'REMARK   2 RESOLUTION.    1.85 ANGSTROMS.                                       ',
'REMARK   3                                                                      ',
'REMARK   3   R VALUE            (WORKING SET) : 0.174                           ',
'REMARK   3   FREE R VALUE                     : 0.219                           ',
'REMARK   3   BIN FREE R VALUE                    : 0.999                        ',
'REMARK 200   TEMPERATURE           (KELVIN) : 100.0                             ',
'REMARK 200   PH                             : 7.5                               ',
'REMARK 465   MISSING RESIDUES                                                   ',
);

# The fixed-field annotation records, placed by the column numbers in the PDB
# format specification (v3.3).  Written this way so that a record can be
# checked against the spec by reading the numbers, not by counting spaces --
# which is how the LINK record in an earlier draft of this file ended up two
# columns to the left and silently parsed its chain ids as blanks.
push @mini,
	# DBREF: idCode 8-11, chain 13, seqBegin 15-18, seqEnd 21-24,
	#        database 27-32, dbAccession 34-41, dbIdCode 43-54,
	#        dbseqBegin 56-60, dbseqEnd 63-67
	cols(1,6,'DBREF', 8,4,'9XYZ', 13,1,'A', 15,4,1,'R', 21,4,11,'R',
	     27,6,'UNP', 34,8,'P12345', 43,12,'TEST_HUMAN', 56,5,1,'R', 63,5,11,'R'),
	# SEQADV: resName 13-15, chain 17, seqNum 19-22, database 25-28,
	#         dbAccession 30-38, dbRes 40-42, dbSeq 44-48, conflict 50-70
	cols(1,6,'SEQADV', 8,4,'9XYZ', 13,3,'MSE', 17,1,'A', 19,4,7,'R',
	     25,4,'UNP', 30,9,'P12345', 40,3,'MET', 44,5,7,'R', 50,21,'MODIFIED RESIDUE'),
	# SEQRES: serNum 8-10, chain 12, numRes 14-17, residues from 20 in 4s
	cols(1,6,'SEQRES', 8,3,1,'R', 12,1,'A', 14,4,11,'R',
	     20,51,join('', map { sprintf('%3s ', $_) } qw(MET ALA GLY LEU LYS CYS MSE HIS HIS SER CYS))),
	cols(1,6,'SEQRES', 8,3,1,'R', 12,1,'B', 14,4,4,'R',
	     20,51,join('', map { sprintf('%3s ', $_) } qw(DA DC DG DT))),
	# MODRES: idCode 8-11, resName 13-15, chain 17, seqNum 19-22,
	#         stdRes 25-27, comment 30-70
	cols(1,6,'MODRES', 8,4,'9XYZ', 13,3,'MSE', 17,1,'A', 19,4,7,'R',
	     25,3,'MET', 30,41,'SELENOMETHIONINE'),
	# HET: hetID 8-10, chain 13, seqNum 14-17, iCode 18, numHetAtoms 21-25
	cols(1,6,'HET', 8,3,'NAG','R', 13,1,'A', 14,4,201,'R', 21,5,14,'R'),
	cols(1,6,'HET', 8,3,'ZN', 'R', 13,1,'A', 14,4,202,'R', 21,5,1, 'R'),
	# HETNAM: continuation 9-10, hetID 12-14, text 16-70
	cols(1,6,'HETNAM', 12,3,'NAG','R', 16,55,'2-ACETAMIDO-2-DEOXY-BETA-D-GLUCOPYRANOSE'),
	cols(1,6,'HETNAM', 12,3,'ZN', 'R', 16,55,'ZINC ION'),
	# FORMUL: compNum 9-10, hetID 13-15, continuation 17-18, asterisk 19, text 20-70
	cols(1,6,'FORMUL', 9,2,3,'R', 13,3,'NAG','R', 20,51,'C8 H15 N O6'),
	cols(1,6,'FORMUL', 9,2,4,'R', 13,3,'ZN', 'R', 20,51,'ZN 2+'),
	cols(1,6,'FORMUL', 9,2,5,'R', 13,3,'HOH','R', 19,1,'*', 20,51,'2(H2 O)'),
	# HELIX: serNum 8-10, helixID 12-14, initResName 16-18, initChain 20,
	#        initSeqNum 22-25, endResName 28-30, endChain 32, endSeqNum 34-37,
	#        helixClass 39-40, length 72-76
	cols(1,6,'HELIX', 8,3,1,'R', 12,3,'AA1', 16,3,'MET', 20,1,'A', 22,4,1,'R',
	     28,3,'GLY', 32,1,'A', 34,4,3,'R', 39,2,1,'R', 72,5,3,'R'),
	# SHEET: strand 8-10, sheetID 12-14, numStrands 15-16, initResName 18-20,
	#        initChain 22, initSeqNum 23-26, endResName 29-31, endChain 33,
	#        endSeqNum 34-37, sense 39-40
	cols(1,6,'SHEET', 8,3,1,'R', 12,3,'AA1', 15,2,2,'R', 18,3,'CYS', 22,1,'A',
	     23,4,6,'R', 29,3,'HIS', 33,1,'A', 34,4,8,'R', 39,2,0,'R'),
	# SSBOND: serNum 8-10, CYS 12-14, chain1 16, seqNum1 18-21,
	#         CYS 26-28, chain2 30, seqNum2 32-35, sym1 60-65, sym2 67-72, length 74-78
	cols(1,6,'SSBOND', 8,3,1,'R', 12,3,'CYS', 16,1,'A', 18,4,6,'R',
	     26,3,'CYS', 30,1,'A', 32,4,10,'R', 60,6,'1555', 67,6,'1555', 74,5,'2.03','R'),
	# LINK: name1 13-16, resName1 18-20, chain1 22, resSeq1 23-26,
	#       name2 43-46, resName2 48-50, chain2 52, resSeq2 53-56, length 74-78
	cols(1,6,'LINK', 13,4,'ZN', 18,3,'ZN','R', 22,1,'A', 23,4,202,'R',
	     43,4,' SG', 48,3,'CYS', 52,1,'A', 53,4,6,'R', 74,5,'2.31','R'),
	# CISPEP: serNum 8-10, pep1 12-14, chain1 16, seqNum1 18-21,
	#         pep2 26-28, chain2 30, seqNum2 32-35, modNum 44-46, measure 54-59
	cols(1,6,'CISPEP', 8,3,1,'R', 12,3,'GLY', 16,1,'A', 18,4,3,'R',
	     26,3,'CYS', 30,1,'A', 32,4,6,'R', 44,3,0,'R', 54,6,'-0.42','R'),
	# CRYST1: a 7-15, b 16-24, c 25-33, alpha 34-40, beta 41-47, gamma 48-54,
	#         sGroup 56-66, z 67-70
	cols(1,6,'CRYST1', 7,9,'40.100','R', 16,9,'50.200','R', 25,9,'60.300','R',
	     34,7,'90.00','R', 41,7,'95.50','R', 48,7,'90.00','R',
	     56,11,'P 1 21 1', 67,4,4,'R');

push @mini, atom('ATOM  ', 'A', 'MET',  1, '', [ bb([ 'CB', 'C' ]) ], [ 10, 10, 10 ]);
# an alternate conformer: two CB records, altlocs A and B, unequal occupancy
push @mini, atom('ATOM  ', 'A', 'ALA',  2, '', [ bb() ], [ 13, 11, 11 ]);
push @mini, atom_line(record => 'ATOM  ', serial => ++$serial, name => 'CB', element => 'C',
	altloc => 'A', resname => 'ALA', chain => 'A', resseq => 2, icode => '',
	x => 19.0, y => 15.0, z => 13.0, occ => 0.40, b => 22);
push @mini, atom_line(record => 'ATOM  ', serial => ++$serial, name => 'CB', element => 'C',
	altloc => 'B', resname => 'ALA', chain => 'A', resseq => 2, icode => '',
	x => 19.5, y => 15.5, z => 13.5, occ => 0.60, b => 25);
push @mini, atom('ATOM  ', 'A', 'GLY',  3, '', [ bb() ], [ 16, 12, 12 ]);
# residues 4 and 5 are in SEQRES but were never modelled: a gap
push @mini, atom('ATOM  ', 'A', 'CYS',  6, '', [ bb([ 'SG', 'S' ]) ], [ 19, 13, 13 ]);
# a modified residue, written as HETATM, that is still an M in the sequence
push @mini, atom('HETATM', 'A', 'MSE',  7, '', [ bb([ 'CB', 'C' ], [ 'SE', 'SE' ]) ], [ 22, 14, 14 ]);
push @mini, atom('ATOM  ', 'A', 'HIS',  8, '',  [ bb([ 'CB', 'C' ]) ], [ 25, 15, 15 ]);
push @mini, atom('ATOM  ', 'A', 'HIS',  8, 'A', [ bb([ 'CB', 'C' ]) ], [ 28, 16, 16 ]);
# a hydrogen, so that hydrogens => 0 has something to remove
push @mini, atom('ATOM  ', 'A', 'SER',  9, '', [ bb([ 'CB', 'C' ], [ 'HB2', 'H' ]) ], [ 31, 17, 17 ]);
push @mini, atom('ATOM  ', 'A', 'CYS', 10, '', [ bb([ 'SG', 'S' ]) ], [ 34, 18, 18 ]);
push @mini, sprintf('%-6s%5d      %3s %1s%4d%1s', 'TER', ++$serial, 'CYS', 'A', 10, '');
push @mini, atom('HETATM', 'A', 'NAG', 201, '', [ [ 'C1', 'C' ], [ 'C2', 'C' ], [ 'O5', 'O' ], [ 'N2', 'N' ] ], [ 40, 20, 20 ]);
push @mini, atom('HETATM', 'A', 'ZN',  202, '', [ [ 'ZN', 'ZN' ] ], [ 45, 22, 22 ]);
push @mini, atom('HETATM', 'A', 'HOH', 301, '', [ [ 'O', 'O' ] ], [ 50, 24, 24 ]);
push @mini, atom('HETATM', 'A', 'HOH', 302, '', [ [ 'O', 'O' ] ], [ 52, 25, 25 ]);

# a DNA chain, to have a chain that is not a protein
my $z = 0;
for my $r ([ 'DA', 1 ], [ 'DC', 2 ], [ 'DG', 3 ], [ 'DT', 4 ]) {
	push @mini, atom('ATOM  ', 'B', $r->[0], $r->[1], '',
		[ [ 'P', 'P' ], [ 'OP1', 'O' ], [ "C1'", 'C' ] ], [ 60 + $z, 30, 30 ]);
	$z += 3;
}
push @mini, sprintf('%-6s%5d      %3s %1s%4d%1s', 'TER', ++$serial, 'DT', 'B', 4, '');
push @mini, 'CONECT   57   58   59';
push @mini, 'MASTER      000    0    0    1    1    0    0    6   66    2    0    2          ';
push @mini, 'END';

# --- nmr.pdb -- three models of the same tripeptide -----------------------
my @nmr = (
'HEADER    TEST                                    01-JAN-20   9NMR              ',
'TITLE     A THREE MODEL ENSEMBLE                                                ',
'EXPDTA    SOLUTION NMR                                                          ',
'NUMMDL    3                                                                     ',
'SEQRES   1 A    3  GLY SER TRP                                                  ',
);
for my $m (1 .. 3) {
	$serial = 0;
	push @nmr, sprintf('MODEL     %4d', $m);
	my $i = 0;
	for my $r ([ 'GLY', 1 ], [ 'SER', 2 ], [ 'TRP', 3 ]) {
		push @nmr, atom('ATOM  ', 'A', $r->[0], $r->[1], '', [ bb() ], [ 5 + $m, 5 + $i, 5 ]);
		$i++;
	}
	push @nmr, 'ENDMDL';
}
push @nmr, 'END';

# --- ensemble.pdb -- four models of a real NMR ensemble --------------------
#
# Chain B of 1K9R (the YAP65 WW domain bound to the acetyl-PLPPY peptide,
# solution NMR, 20 models), models 1 to 4, lifted whole from
# /home/con/ui/pepPriML/PPB/PDB/PDBbind.v2020/1k9r.ent.pdb with their
# coordinates exactly as deposited.  It is the fixture t/rmsd.t measures
# against gemmi and Biopython, and the models have to differ the way an
# ensemble's models really differ: nmr.pdb's three models are one tripeptide
# moved a whole angstrom along x, which superposes onto itself exactly and so
# says nothing about the fit.  These four have real conformational spread
# (1.0 to 2.7 A over all atoms), a HETATM cap on the N terminus, an OXT on the
# C terminus, and the hydrogens an NMR entry carries -- so select => 'heavy'
# and select => 'backbone' have something to leave out.
#
# The atoms are listed once and the coordinates four times because that is
# what the file says: every model has the same atoms in the same order, and
# only the positions move.
my @ens_atom = (
	[ 'HETATM', 'ACE', 45, 'C',   'C' ],
	[ 'HETATM', 'ACE', 45, 'O',   'O' ],
	[ 'HETATM', 'ACE', 45, 'CH3', 'C' ],
	[ 'HETATM', 'ACE', 45, 'H1',  'H' ],
	[ 'HETATM', 'ACE', 45, 'H2',  'H' ],
	[ 'HETATM', 'ACE', 45, 'H3',  'H' ],
	[ 'ATOM  ', 'PRO', 46, 'N',   'N' ],
	[ 'ATOM  ', 'PRO', 46, 'CA',  'C' ],
	[ 'ATOM  ', 'PRO', 46, 'C',   'C' ],
	[ 'ATOM  ', 'PRO', 46, 'O',   'O' ],
	[ 'ATOM  ', 'PRO', 46, 'CB',  'C' ],
	[ 'ATOM  ', 'PRO', 46, 'CG',  'C' ],
	[ 'ATOM  ', 'PRO', 46, 'CD',  'C' ],
	[ 'ATOM  ', 'PRO', 46, 'HA',  'H' ],
	[ 'ATOM  ', 'PRO', 46, 'HB2', 'H' ],
	[ 'ATOM  ', 'PRO', 46, 'HB3', 'H' ],
	[ 'ATOM  ', 'PRO', 46, 'HG2', 'H' ],
	[ 'ATOM  ', 'PRO', 46, 'HG3', 'H' ],
	[ 'ATOM  ', 'PRO', 46, 'HD2', 'H' ],
	[ 'ATOM  ', 'PRO', 46, 'HD3', 'H' ],
	[ 'ATOM  ', 'LEU', 47, 'N',   'N' ],
	[ 'ATOM  ', 'LEU', 47, 'CA',  'C' ],
	[ 'ATOM  ', 'LEU', 47, 'C',   'C' ],
	[ 'ATOM  ', 'LEU', 47, 'O',   'O' ],
	[ 'ATOM  ', 'LEU', 47, 'CB',  'C' ],
	[ 'ATOM  ', 'LEU', 47, 'CG',  'C' ],
	[ 'ATOM  ', 'LEU', 47, 'CD1', 'C' ],
	[ 'ATOM  ', 'LEU', 47, 'CD2', 'C' ],
	[ 'ATOM  ', 'LEU', 47, 'H',   'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HA',  'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HB2', 'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HB3', 'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HG',  'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HD11', 'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HD12', 'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HD13', 'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HD21', 'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HD22', 'H' ],
	[ 'ATOM  ', 'LEU', 47, 'HD23', 'H' ],
	[ 'ATOM  ', 'PRO', 48, 'N',   'N' ],
	[ 'ATOM  ', 'PRO', 48, 'CA',  'C' ],
	[ 'ATOM  ', 'PRO', 48, 'C',   'C' ],
	[ 'ATOM  ', 'PRO', 48, 'O',   'O' ],
	[ 'ATOM  ', 'PRO', 48, 'CB',  'C' ],
	[ 'ATOM  ', 'PRO', 48, 'CG',  'C' ],
	[ 'ATOM  ', 'PRO', 48, 'CD',  'C' ],
	[ 'ATOM  ', 'PRO', 48, 'HA',  'H' ],
	[ 'ATOM  ', 'PRO', 48, 'HB2', 'H' ],
	[ 'ATOM  ', 'PRO', 48, 'HB3', 'H' ],
	[ 'ATOM  ', 'PRO', 48, 'HG2', 'H' ],
	[ 'ATOM  ', 'PRO', 48, 'HG3', 'H' ],
	[ 'ATOM  ', 'PRO', 48, 'HD2', 'H' ],
	[ 'ATOM  ', 'PRO', 48, 'HD3', 'H' ],
	[ 'ATOM  ', 'PRO', 49, 'N',   'N' ],
	[ 'ATOM  ', 'PRO', 49, 'CA',  'C' ],
	[ 'ATOM  ', 'PRO', 49, 'C',   'C' ],
	[ 'ATOM  ', 'PRO', 49, 'O',   'O' ],
	[ 'ATOM  ', 'PRO', 49, 'CB',  'C' ],
	[ 'ATOM  ', 'PRO', 49, 'CG',  'C' ],
	[ 'ATOM  ', 'PRO', 49, 'CD',  'C' ],
	[ 'ATOM  ', 'PRO', 49, 'HA',  'H' ],
	[ 'ATOM  ', 'PRO', 49, 'HB2', 'H' ],
	[ 'ATOM  ', 'PRO', 49, 'HB3', 'H' ],
	[ 'ATOM  ', 'PRO', 49, 'HG2', 'H' ],
	[ 'ATOM  ', 'PRO', 49, 'HG3', 'H' ],
	[ 'ATOM  ', 'PRO', 49, 'HD2', 'H' ],
	[ 'ATOM  ', 'PRO', 49, 'HD3', 'H' ],
	[ 'ATOM  ', 'TYR', 50, 'N',   'N' ],
	[ 'ATOM  ', 'TYR', 50, 'CA',  'C' ],
	[ 'ATOM  ', 'TYR', 50, 'C',   'C' ],
	[ 'ATOM  ', 'TYR', 50, 'O',   'O' ],
	[ 'ATOM  ', 'TYR', 50, 'CB',  'C' ],
	[ 'ATOM  ', 'TYR', 50, 'CG',  'C' ],
	[ 'ATOM  ', 'TYR', 50, 'CD1', 'C' ],
	[ 'ATOM  ', 'TYR', 50, 'CD2', 'C' ],
	[ 'ATOM  ', 'TYR', 50, 'CE1', 'C' ],
	[ 'ATOM  ', 'TYR', 50, 'CE2', 'C' ],
	[ 'ATOM  ', 'TYR', 50, 'CZ',  'C' ],
	[ 'ATOM  ', 'TYR', 50, 'OH',  'O' ],
	[ 'ATOM  ', 'TYR', 50, 'OXT', 'O' ],
	[ 'ATOM  ', 'TYR', 50, 'H',   'H' ],
	[ 'ATOM  ', 'TYR', 50, 'HA',  'H' ],
	[ 'ATOM  ', 'TYR', 50, 'HB2', 'H' ],
	[ 'ATOM  ', 'TYR', 50, 'HB3', 'H' ],
	[ 'ATOM  ', 'TYR', 50, 'HD1', 'H' ],
	[ 'ATOM  ', 'TYR', 50, 'HD2', 'H' ],
	[ 'ATOM  ', 'TYR', 50, 'HE1', 'H' ],
	[ 'ATOM  ', 'TYR', 50, 'HE2', 'H' ],
	[ 'ATOM  ', 'TYR', 50, 'HH',  'H' ],
);

my @ens_xyz = (
	[ # model 1
		[   6.837,  15.215,   1.139], [   5.848,  15.736,   1.616], [   7.295,  15.560,  -0.280],
		[   6.513,  15.313,  -0.981], [   8.184,  14.995,  -0.518], [   7.513,  16.616,  -0.341],
		[   7.576,  14.340,   1.765], [   7.785,  12.994,   1.167], [   6.440,  12.347,   0.818],
		[   5.393,  12.890,   1.099], [   8.492,  12.209,   2.266], [   8.095,  12.882,   3.538],
		[   7.837,  14.331,   3.211], [   8.415,  13.059,   0.294], [   8.160,  11.180,   2.263],
		[   9.562,  12.261,   2.137], [   7.199,  12.425,   3.932], [   8.896,  12.811,   4.258],
		[   6.975,  14.690,   3.757], [   8.706,  14.930,   3.435], [   6.472,  11.187,   0.207],
		[   5.205,  10.481,  -0.172], [   4.385,  11.333,  -1.158], [   4.294,  12.535,  -1.008],
		[   4.439,  10.272,   1.139], [   3.253,   9.339,   0.893], [   3.758,   7.904,   0.732],
		[   2.291,   9.412,   2.080], [   7.336,  10.775,  -0.004], [   5.439,   9.525,  -0.611],
		[   5.097,   9.832,   1.874], [   4.076,  11.221,   1.504], [   2.740,   9.642,  -0.007],
		[   4.652,   7.902,   0.126], [   2.998,   7.306,   0.253], [   3.981,   7.489,   1.705],
		[   1.275,   9.452,   1.718], [   2.502,  10.300,   2.659], [   2.419,   8.539,   2.702],
		[   3.814,  10.682,  -2.147], [   3.006,  11.406,  -3.160], [   1.647,  11.819,  -2.575],
		[   0.832,  10.973,  -2.269], [   2.812,  10.375,  -4.268], [   2.940,   9.049,  -3.589],
		[   3.866,   9.236,  -2.416], [   3.542,  12.258,  -3.541], [   1.831,  10.477,  -4.709],
		[   3.577,  10.485,  -5.022], [   1.971,   8.719,  -3.244], [   3.351,   8.323,  -4.273],
		[   3.512,   8.679,  -1.562], [   4.870,   8.935,  -2.675], [   1.436,  13.107,  -2.444],
		[   0.149,  13.603,  -1.898], [  -0.959,  13.460,  -2.948], [  -1.028,  14.216,  -3.896],
		[   0.427,  15.073,  -1.601], [   1.545,  15.452,  -2.521], [   2.354,  14.205,  -2.779],
		[  -0.110,  13.081,  -0.992], [  -0.449,  15.670,  -1.810], [   0.729,  15.197,  -0.572],
		[   1.146,  15.830,  -3.450], [   2.166,  16.203,  -2.055], [   2.644,  14.152,  -3.819],
		[   3.224,  14.180,  -2.140], [  -1.824,  12.494,  -2.789], [  -2.924,  12.306,  -3.784],
		[  -3.669,  13.625,  -4.010], [  -3.555,  14.167,  -5.096], [  -3.857,  11.266,  -3.156],
		[  -4.482,  10.408,  -4.239], [  -4.890,  10.983,  -5.452], [  -4.656,   9.036,  -4.026],
		[  -5.469,  10.185,  -6.446], [  -5.236,   8.238,  -5.020], [  -5.642,   8.812,  -6.230],
		[  -6.213,   8.027,  -7.210], [  -4.339,  14.069,  -3.091], [  -1.751,  11.892,  -2.020],
		[  -2.529,  11.931,  -4.715], [  -3.293,  10.638,  -2.482], [  -4.637,  11.772,  -2.606],
		[  -4.756,  12.041,  -5.619], [  -4.342,   8.590,  -3.094], [  -5.782,  10.628,  -7.379],
		[  -5.368,   7.179,  -4.854], [  -5.518,   7.749,  -7.811],
	],
	[ # model 2
		[   8.052,  11.569,   5.232], [   6.844,  11.503,   5.107], [   8.679,  12.450,   6.314],
		[   8.691,  13.477,   5.978], [   9.691,  12.123,   6.504], [   8.099,  12.374,   7.221],
		[   8.900,  10.917,   4.485], [   8.645,  10.789,   3.025], [   7.240,  10.234,   2.770],
		[   6.876,   9.189,   3.272], [   9.708,   9.804,   2.551], [  10.055,   8.999,   3.760],
		[   9.828,   9.880,   4.960], [   8.775,  11.739,   2.530], [   9.308,   9.166,   1.773],
		[  10.579,  10.331,   2.196], [   9.419,   8.126,   3.813], [  11.090,   8.701,   3.719],
		[   9.383,   9.311,   5.764], [  10.756,  10.330,   5.279], [   6.450,  10.925,   1.995],
		[   5.068,  10.441,   1.706], [   4.399,  11.357,   0.667], [   4.130,  12.508,   0.949],
		[   4.339,  10.517,   3.057], [   2.968,   9.820,   2.984], [   2.002,  10.653,   2.139],
		[   3.114,   8.425,   2.371], [   6.765,  11.766,   1.600], [   5.094,   9.421,   1.360],
		[   4.942,  10.034,   3.811], [   4.198,  11.553,   3.324], [   2.570,   9.726,   3.983],
		[   2.328,  11.683,   2.130], [   1.010,  10.593,   2.560], [   1.987,  10.272,   1.128],
		[   2.486,   7.728,   2.907], [   4.142,   8.108,   2.439], [   2.814,   8.455,   1.334],
		[   4.146,  10.819,  -0.505], [   3.500,  11.618,  -1.580], [   2.029,  11.896,  -1.230],
		[   1.232,  10.982,  -1.165], [   3.603,  10.717,  -2.810], [   3.711,   9.332,  -2.260],
		[   4.430,   9.443,  -0.943], [   4.039,  12.534,  -1.749], [   2.719,  10.810,  -3.421],
		[   4.485,  10.964,  -3.382], [   2.726,   8.917,  -2.110], [   4.276,   8.709,  -2.938],
		[   4.037,   8.730,  -0.234], [   5.492,   9.302,  -1.080], [   1.710,  13.150,  -1.014],
		[   0.314,  13.523,  -0.668], [  -0.601,  13.361,  -1.886], [  -0.513,  14.106,  -2.843],
		[   0.422,  14.987,  -0.256], [   1.647,  15.492,  -0.949], [   2.593,  14.326,  -1.069],
		[  -0.044,  12.931,   0.159], [  -0.448,  15.535,  -0.585], [   0.536,  15.070,   0.814],
		[   1.390,  15.860,  -1.932], [   2.103,  16.279,  -0.368], [   3.120,  14.360,  -2.010],
		[   3.288,  14.315,  -0.244], [  -1.477,  12.395,  -1.856], [  -2.397,  12.185,  -3.010],
		[  -3.129,  13.486,  -3.349], [  -3.187,  13.824,  -4.520], [  -3.388,  11.120,  -2.537],
		[  -3.996,  10.429,  -3.733], [  -3.170,   9.927,  -4.747], [  -5.386,  10.287,  -3.829],
		[  -3.734,   9.286,  -5.856], [  -5.950,   9.645,  -4.938], [  -5.124,   9.145,  -5.951],
		[  -5.680,   8.512,  -7.044], [  -3.618,  14.124,  -2.430], [  -1.530,  11.806,  -1.075],
		[  -1.851,  11.824,  -3.868], [  -2.872,  10.396,  -1.925], [  -4.170,  11.589,  -1.958],
		[  -2.098,  10.037,  -4.674], [  -6.023,  10.673,  -3.047], [  -3.099,   8.899,  -6.639],
		[  -7.022,   9.536,  -5.011], [  -5.596,   9.097,  -7.800],
	],
	[ # model 3
		[   7.977,  12.111,   4.277], [   6.768,  12.091,   4.158], [   8.692,  13.360,   4.794],
		[   9.282,  13.793,   3.998], [   9.339,  13.091,   5.615], [   7.961,  14.079,   5.133],
		[   8.758,  11.107,   3.979], [   8.609,  10.427,   2.664], [   7.154,  10.004,   2.439],
		[   6.682,   9.040,   3.010], [   9.514,   9.205,   2.779], [   9.607,   8.929,   4.242],
		[   9.441,  10.245,   4.955], [   8.949,  11.066,   1.866], [   9.075,   8.363,   2.260],
		[  10.493,   9.423,   2.382], [   8.822,   8.245,   4.538], [  10.572,   8.508,   4.479],
		[   8.834,  10.119,   5.841], [  10.402,  10.662,   5.209], [   6.440,  10.716,   1.611],
		[   5.017,  10.354,   1.348], [   4.429,  11.272,   0.264], [   4.215,  12.443,   0.504],
		[   4.300,  10.575,   2.680], [   2.809,  10.271,   2.515], [   2.493,   8.913,   3.146],
		[   1.987,  11.359,   3.206], [   6.839,  11.489,   1.159], [   4.939,   9.320,   1.058],
		[   4.720,   9.919,   3.428], [   4.425,  11.603,   2.991], [   2.563,  10.244,   1.463],
		[   3.046,   8.808,   4.069], [   2.777,   8.124,   2.464], [   1.435,   8.849,   3.350],
		[   0.960,  11.299,   2.873], [   2.390,  12.329,   2.957], [   2.027,  11.216,   4.275],
		[   4.184,  10.713,  -0.899], [   3.616,  11.513,  -2.013], [   2.148,  11.862,  -1.728],
		[   1.433,  11.079,  -1.138], [   3.729,  10.584,  -3.219], [   3.754,   9.205,  -2.640],
		[   4.405,   9.313,  -1.288], [   4.197,  12.407,  -2.178], [   2.876,  10.703,  -3.868],
		[   4.644,  10.781,  -3.759], [   2.747,   8.831,  -2.538], [   4.330,   8.549,  -3.277],
		[   3.929,   8.644,  -0.584], [   5.463,   9.101,  -1.356], [   1.743,  13.034,  -2.160],
		[   0.344,  13.477,  -1.941], [  -0.610,  12.704,  -2.854], [  -0.259,  11.685,  -3.414],
		[   0.373,  14.956,  -2.312], [   1.524,  15.097,  -3.257], [   2.534,  14.044,  -2.880],
		[   0.065,  13.361,  -0.905], [  -0.549,  15.238,  -2.800], [   0.533,  15.563,  -1.433],
		[   1.189,  14.940,  -4.272], [   1.962,  16.079,  -3.161], [   2.981,  13.614,  -3.765],
		[   3.294,  14.461,  -2.236], [  -1.816,  13.180,  -3.006], [  -2.792,  12.473,  -3.882],
		[  -3.993,  13.376,  -4.175], [  -4.563,  13.893,  -3.230], [  -3.226,  11.244,  -3.082],
		[  -4.001,  10.308,  -3.977], [  -3.374,   9.718,  -5.083], [  -5.345,  10.028,  -3.704],
		[  -4.092,   8.849,  -5.913], [  -6.062,   9.160,  -4.535], [  -5.435,   8.571,  -5.639],
		[  -6.143,   7.714,  -6.459], [  -4.322,  13.533,  -5.339], [  -2.079,  14.004,  -2.544],
		[  -2.319,  12.164,  -4.802], [  -2.353,  10.738,  -2.698], [  -3.853,  11.554,  -2.260],
		[  -2.336,   9.934,  -5.293], [  -5.828,  10.483,  -2.853], [  -3.607,   8.394,  -6.765],
		[  -7.099,   8.945,  -4.324], [  -6.865,   7.343,  -5.948],
	],
	[ # model 4
		[   7.714,   9.722,   5.430], [   7.384,   8.584,   5.691], [   7.190,  10.898,   6.256],
		[   6.261,  11.251,   5.834], [   7.917,  11.697,   6.247], [   7.023,  10.576,   7.274],
		[   8.518,  10.044,   4.453], [   8.004,  10.847,   3.313], [   6.747,  10.198,   2.722],
		[   6.369,   9.105,   3.094], [   9.146,  10.826,   2.303], [   9.916,   9.586,   2.616],
		[   9.742,   9.318,   4.088], [   7.800,  11.861,   3.621], [   8.755,  10.785,   1.295],
		[   9.775,  11.693,   2.428], [   9.529,   8.759,   2.039], [  10.961,   9.735,   2.396],
		[   9.623,   8.257,   4.266], [  10.583,   9.702,   4.646], [   6.099,  10.863,   1.804],
		[   4.869,  10.283,   1.192], [   4.367,  11.193,   0.059], [   4.224,  12.384,   0.249],
		[   3.849,  10.232,   2.329], [   2.773,   9.195,   2.004], [   2.617,   8.235,   3.186],
		[   1.443,   9.904,   1.744], [   6.421,  11.743,   1.519], [   5.065,   9.289,   0.828],
		[   4.350,   9.958,   3.246], [   3.391,  11.204,   2.446], [   3.062,   8.638,   1.125],
		[   3.044,   8.683,   4.073], [   3.130,   7.310,   2.969], [   1.570,   8.038,   3.353],
		[   0.632,   9.199,   1.847], [   1.442,  10.312,   0.744], [   1.316,  10.705,   2.459],
		[   4.112,  10.608,  -1.089], [   3.625,  11.401,  -2.246], [   2.161,  11.812,  -2.034],
		[   1.412,  11.106,  -1.388], [   3.752,  10.440,  -3.423], [   3.690,   9.074,  -2.816],
		[   4.252,   9.182,  -1.423], [   4.247,  12.268,  -2.405], [   2.934,  10.581,  -4.113],
		[   4.696,  10.585,  -3.926], [   2.666,   8.737,  -2.777], [   4.282,   8.385,  -3.399],
		[   3.679,   8.576,  -0.736], [   5.293,   8.891,  -1.411], [   1.798,  12.945,  -2.587],
		[   0.407,  13.439,  -2.449], [  -0.546,  12.602,  -3.308], [  -0.215,  11.514,  -3.737],
		[   0.481,  14.875,  -2.963], [   1.659,  14.894,  -3.884], [   2.632,  13.861,  -3.380],
		[   0.097,  13.431,  -1.416], [  -0.421,  15.129,  -3.499], [   0.635,  15.559,  -2.141],
		[   1.346,  14.648,  -4.888], [   2.121,  15.871,  -3.872], [   3.089,  13.336,  -4.207],
		[   3.387,  14.322,  -2.759], [  -1.722,  13.102,  -3.565], [  -2.694,  12.334,  -4.397],
		[  -3.536,  13.291,  -5.244], [  -3.102,  13.629,  -6.333], [  -3.574,  11.588,  -3.394],
		[  -4.119,  10.335,  -4.034], [  -4.809,  10.413,  -5.250], [  -3.936,   9.094,  -3.412],
		[  -5.317,   9.250,  -5.843], [  -4.442,   7.932,  -4.005], [  -5.133,   8.010,  -5.221],
		[  -5.633,   6.864,  -5.805], [  -4.603,  13.670,  -4.789], [  -1.970,  13.982,  -3.211],
		[  -2.175,  11.630,  -5.028], [  -2.985,  11.324,  -2.526], [  -4.393,  12.224,  -3.093],
		[  -4.952,  11.369,  -5.730], [  -3.402,   9.034,  -2.475], [  -5.849,   9.309,  -6.781],
		[  -4.301,   6.974,  -3.525], [  -6.538,   7.037,  -6.070],
	],
);

my @ensemble = (
'HEADER    STRUCTURAL PROTEIN                      30-OCT-01   9ENS              ',
'TITLE     FOUR MODELS OF A BOUND PEPTIDE                                        ',
'EXPDTA    SOLUTION NMR                                                          ',
'NUMMDL    4                                                                     ',
'SEQRES   1 B    6  ACE PRO LEU PRO PRO TYR                                      ',
);
for my $m (1 .. scalar @ens_xyz) {
	$serial = 0;
	push @ensemble, sprintf('MODEL     %4d', $m);
	for my $i (0 .. $#ens_atom) {
		my ($rec, $resname, $resseq, $name, $element) = @{ $ens_atom[$i] };
		$serial++;
		push @ensemble, atom_line(
			record => $rec, serial => $serial, name => $name, element => $element,
			altloc => '', resname => $resname, chain => 'B',
			resseq => $resseq, icode => '',
			x => $ens_xyz[$m - 1][$i][0], y => $ens_xyz[$m - 1][$i][1],
			z => $ens_xyz[$m - 1][$i][2], occ => 1, b => 0,
		);
	}
	push @ensemble, 'ENDMDL';
}
push @ensemble, 'END';

# --- bare.pdb -- coordinates and nothing else -----------------------------
# No header at all, and no element columns, so the element has to be worked
# out from the atom name.  Files this old, and files written by simulation
# programs, both look like this.
my @bare;
$serial = 0;
for my $r ([ 'VAL', 1 ], [ 'LYS', 2 ]) {
	for my $a ([ 'N', 'N' ], [ 'CA', 'C' ], [ 'C', 'C' ], [ 'O', 'O' ], [ 'CB', 'C' ]) {
		$serial++;
		my $l = atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			resname => $r->[0], chain => 'A', resseq => $r->[1], altloc => '', icode => '',
			x => $serial, y => $serial + 1, z => $serial + 2,
		);
		push @bare, substr($l, 0, 66);    # truncate before the element columns
	}
}
push @bare, 'END';

# --- stack.pdb -- aromatic residues that are actually stacked --------------
#
# Seven residues of 1A42 (human carbonic anhydrase II, 1.05 A), lifted whole
# from /home/con/ui/pepPriML/PPB/PDB/PDBbind.v2020/1a42.ent.pdb chain A with
# their coordinates, occupancies and B factors exactly as deposited.  Nothing
# here is invented: the geometry is what makes them stack, so a made-up ring
# would test the arithmetic against itself.
#
# They were chosen by asking the module for every stacked pair in 1A42 and
# keeping the residues of the four that are in one chain and cover both kinds:
#
#   face  TRP 5 six-ring  / HIS 64          planes 4.6 degrees apart, 3.70 A
#   edge  PHE 66          / PHE 226         planes 78.4 apart, 5.36 A
#   edge  TRP 97 five-ring / PHE 226        planes 65.4 apart, 5.53 A
#   edge  HIS 119         / TRP 209 six-ring planes 67.6 apart, 4.86 A
#
# which between them exercise the six-membered ring of a phenylalanine and a
# tyrosine, both rings of a tryptophan, and the five-membered ring of a
# histidine.  The residues are not consecutive and there is no backbone
# between them; that is deliberate, and is why the file has no TER and no
# SEQRES -- it is a set of residues, not a chain that folded.
my @stack_res = (
	[ 'TRP', 5, [
		[ 'N',    'N',     8.257,   -0.414,   10.635,  1.00,  27.01 ],
		[ 'CA',   'C',     7.481,   -1.387,   11.384,  1.00,  19.87 ],
		[ 'C',    'C',     6.510,   -2.204,   10.563,  1.00,  19.91 ],
		[ 'O',    'O',     6.066,   -1.770,    9.486,  1.00,  19.19 ],
		[ 'CB',   'C',     6.719,   -0.667,   12.505,  1.00,  14.02 ],
		[ 'CG',   'C',     5.438,    0.076,   12.142,  1.00,  12.29 ],
		[ 'CD1',  'C',     5.444,    1.400,   11.760,  1.00,   6.38 ],
		[ 'CD2',  'C',     4.172,   -0.466,   12.199,  1.00,   6.22 ],
		[ 'NE1',  'N',     4.172,    1.704,   11.581,  1.00,   8.90 ],
		[ 'CE2',  'C',     3.380,    0.633,   11.826,  1.00,   7.53 ],
		[ 'CE3',  'C',     3.588,   -1.693,   12.512,  1.00,   4.86 ],
		[ 'CZ2',  'C',     1.995,    0.506,   11.767,  1.00,   3.51 ],
		[ 'CZ3',  'C',     2.199,   -1.821,   12.451,  1.00,   2.00 ],
		[ 'CH2',  'C',     1.408,   -0.726,   12.081,  1.00,   4.15 ],
	] ],
	[ 'HIS', 64, [
		[ 'N',    'N',    -0.871,   -2.013,    6.309,  1.00,  10.84 ],
		[ 'CA',   'C',    -1.016,   -2.605,    7.638,  1.00,  14.16 ],
		[ 'C',    'C',    -2.362,   -3.292,    7.812,  1.00,  13.62 ],
		[ 'O',    'O',    -2.465,   -4.335,    8.449,  1.00,  16.31 ],
		[ 'CB',   'C',    -0.853,   -1.521,    8.690,  1.00,  11.37 ],
		[ 'CG',   'C',     0.551,   -0.960,    8.667,  1.00,  12.92 ],
		[ 'ND1',  'N',     1.686,   -1.623,    8.866,  1.00,  16.68 ],
		[ 'CD2',  'C',     0.873,    0.353,    8.418,  1.00,  13.77 ],
		[ 'CE1',  'C',     2.684,   -0.777,    8.748,  1.00,  13.76 ],
		[ 'NE2',  'N',     2.181,    0.404,    8.481,  1.00,  15.68 ],
	] ],
	[ 'PHE', 66, [
		[ 'N',    'N',    -6.779,   -2.621,    6.033,  1.00,   8.55 ],
		[ 'CA',   'C',    -7.541,   -1.754,    5.181,  1.00,   9.88 ],
		[ 'C',    'C',    -8.423,   -0.958,    6.121,  1.00,  10.30 ],
		[ 'O',    'O',    -8.898,   -1.492,    7.127,  1.00,  12.04 ],
		[ 'CB',   'C',    -8.378,   -2.552,    4.184,  1.00,   2.93 ],
		[ 'CG',   'C',    -9.381,   -3.566,    4.720,  1.00,   5.04 ],
		[ 'CD1',  'C',    -8.974,   -4.859,    5.004,  1.00,   5.57 ],
		[ 'CD2',  'C',   -10.717,   -3.200,    4.911,  1.00,   6.77 ],
		[ 'CE1',  'C',    -9.895,   -5.788,    5.477,  1.00,   9.61 ],
		[ 'CE2',  'C',   -11.629,   -4.135,    5.386,  1.00,   6.91 ],
		[ 'CZ',   'C',   -11.221,   -5.428,    5.669,  1.00,   2.26 ],
	] ],
	[ 'TRP', 97, [
		[ 'N',    'N',    -6.638,   -9.426,   11.785,  1.00,   4.96 ],
		[ 'CA',   'C',    -7.086,  -10.799,   11.614,  1.00,   6.57 ],
		[ 'C',    'C',    -5.877,  -11.699,   11.551,  1.00,   6.50 ],
		[ 'O',    'O',    -4.726,  -11.233,   11.412,  1.00,   6.06 ],
		[ 'CB',   'C',    -7.941,  -10.972,   10.316,  1.00,   9.03 ],
		[ 'CG',   'C',    -7.254,  -10.572,    9.015,  1.00,   7.42 ],
		[ 'CD1',  'C',    -6.549,  -11.475,    8.255,  1.00,   3.72 ],
		[ 'CD2',  'C',    -7.228,   -9.295,    8.510,  1.00,   8.60 ],
		[ 'NE1',  'N',    -6.059,  -10.759,    7.276,  1.00,   4.52 ],
		[ 'CE2',  'C',    -6.434,   -9.467,    7.376,  1.00,   9.06 ],
		[ 'CE3',  'C',    -7.753,   -8.040,    8.824,  1.00,   6.27 ],
		[ 'CZ2',  'C',    -6.157,   -8.381,    6.543,  1.00,   8.08 ],
		[ 'CZ3',  'C',    -7.475,   -6.965,    7.991,  1.00,   5.35 ],
		[ 'CH2',  'C',    -6.683,   -7.135,    6.859,  1.00,   7.95 ],
	] ],
	[ 'HIS', 119, [
		[ 'N',    'N',   -12.075,   -2.497,   14.976,  1.00,   4.93 ],
		[ 'CA',   'C',   -11.839,   -1.316,   15.736,  1.00,   5.12 ],
		[ 'C',    'C',   -12.522,   -0.129,   15.084,  1.00,   4.80 ],
		[ 'O',    'O',   -12.185,    0.229,   13.955,  1.00,   2.03 ],
		[ 'CB',   'C',   -10.335,   -1.119,   15.812,  1.00,   7.51 ],
		[ 'CG',   'C',    -9.582,   -2.139,   16.636,  1.00,   3.45 ],
		[ 'ND1',  'N',    -8.293,   -2.403,   16.550,  1.00,   2.88 ],
		[ 'CD2',  'C',   -10.107,   -2.864,   17.672,  1.00,   2.71 ],
		[ 'CE1',  'C',    -8.001,   -3.249,   17.510,  1.00,   2.00 ],
		[ 'NE2',  'N',    -9.095,   -3.514,   18.162,  1.00,   5.49 ],
	] ],
	[ 'TRP', 209, [
		[ 'N',    'N',   -10.711,    2.259,   25.863,  1.00,   6.60 ],
		[ 'CA',   'C',   -11.092,    1.095,   25.119,  1.00,   5.32 ],
		[ 'C',    'C',   -12.423,    0.570,   25.579,  1.00,   6.87 ],
		[ 'O',    'O',   -12.554,    0.309,   26.771,  1.00,   9.07 ],
		[ 'CB',   'C',   -10.045,    0.056,   25.307,  1.00,   3.91 ],
		[ 'CG',   'C',    -8.962,    0.144,   24.258,  1.00,   6.41 ],
		[ 'CD1',  'C',    -7.752,    0.759,   24.456,  1.00,   5.46 ],
		[ 'CD2',  'C',    -9.110,   -0.395,   23.010,  1.00,   8.08 ],
		[ 'NE1',  'N',    -7.128,    0.612,   23.309,  1.00,   5.55 ],
		[ 'CE2',  'C',    -7.885,   -0.068,   22.421,  1.00,   8.97 ],
		[ 'CE3',  'C',   -10.107,   -1.098,   22.314,  1.00,   8.95 ],
		[ 'CZ2',  'C',    -7.649,   -0.456,   21.101,  1.00,   4.36 ],
		[ 'CZ3',  'C',    -9.868,   -1.477,   20.996,  1.00,   6.86 ],
		[ 'CH2',  'C',    -8.644,   -1.152,   20.408,  1.00,   8.25 ],
	] ],
	[ 'PHE', 226, [
		[ 'N',    'N',   -10.267,  -11.466,    3.537,  1.00,  16.86 ],
		[ 'CA',   'C',    -9.378,  -10.545,    4.252,  1.00,  11.14 ],
		[ 'C',    'C',    -7.959,  -10.982,    4.058,  1.00,   8.34 ],
		[ 'O',    'O',    -7.092,  -10.183,    3.737,  1.00,   9.01 ],
		[ 'CB',   'C',    -9.594,  -10.512,    5.778,  1.00,  11.87 ],
		[ 'CG',   'C',   -10.858,   -9.859,    6.337,  1.00,  15.35 ],
		[ 'CD1',  'C',   -11.949,   -9.518,    5.524,  1.00,  13.24 ],
		[ 'CD2',  'C',   -10.920,   -9.623,    7.715,  1.00,  16.54 ],
		[ 'CE1',  'C',   -13.095,   -8.949,    6.086,  1.00,  19.53 ],
		[ 'CE2',  'C',   -12.064,   -9.056,    8.276,  1.00,  19.19 ],
		[ 'CZ',   'C',   -13.153,   -8.718,    7.466,  1.00,  22.23 ],
	] ],
);
my @stack;
$serial = 0;
for my $r (@stack_res) {
	my ($resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @stack, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			altloc => '', resname => $resname, chain => 'A', resseq => $resseq, icode => '',
			x => $a->[2], y => $a->[3], z => $a->[4], occ => $a->[5], b => $a->[6],
		);
	}
}
push @stack, 'END';

# --- bases.pdb -- a stack of nucleobases -----------------------------------
#
# Chain P of 3AU6 (an archaeal PolX bound to a gapped DNA), lifted whole from
# /home/con/ui/pepPriML/PPB/PDB/PDBbind.v2020/3au6.ent.pdb, again exactly as
# deposited.  Seven nucleotides, all four DNA bases, and eight face-to-face
# stacks between consecutive ones -- which is the other half of the ring table:
# the six- and five-membered rings of a purine and the six-membered ring of a
# pyrimidine.
#
# A separate file from stack.pdb rather than a second chain in it, because the
# two came out of different entries and so are in different frames of
# reference: putting them in one file would invite whatever contacts the two
# coordinate systems happened to produce, which would mean nothing.
my @bases_res = (
	[ 'DC', 1, [
		[ "O5'",  'O',    -9.582,  -36.543,   33.130,  1.00,  61.80 ],
		[ "C5'",  'C',    -8.825,  -36.688,   34.320,  1.00,  61.52 ],
		[ "C4'",  'C',    -7.494,  -37.368,   34.079,  1.00,  61.00 ],
		[ "O4'",  'O',    -7.732,  -38.690,   33.607,  1.00,  60.58 ],
		[ "C3'",  'C',    -6.614,  -36.774,   33.007,  1.00,  61.45 ],
		[ "O3'",  'O',    -5.808,  -35.855,   33.628,  1.00,  63.73 ],
		[ "C2'",  'C',    -5.796,  -37.931,   32.458,  1.00,  60.15 ],
		[ "C1'",  'C',    -6.715,  -39.096,   32.717,  1.00,  60.16 ],
		[ 'N1',   'N',    -7.426,  -39.650,   31.567,  1.00,  58.92 ],
		[ 'C2',   'C',    -6.743,  -40.331,   30.565,  1.00,  59.75 ],
		[ 'O2',   'O',    -5.498,  -40.451,   30.600,  1.00,  59.27 ],
		[ 'N3',   'N',    -7.501,  -40.835,   29.553,  1.00,  59.87 ],
		[ 'C4',   'C',    -8.824,  -40.676,   29.534,  1.00,  56.89 ],
		[ 'N4',   'N',    -9.539,  -41.173,   28.541,  1.00,  56.58 ],
		[ 'C5',   'C',    -9.501,  -40.000,   30.549,  1.00,  57.52 ],
		[ 'C6',   'C',    -8.771,  -39.520,   31.535,  1.00,  58.07 ],
	] ],
	[ 'DA', 2, [
		[ 'P',    'P',    -5.110,  -34.750,   32.754,  1.00,  65.30 ],
		[ 'OP1',  'O',    -5.557,  -33.500,   33.406,  1.00,  66.32 ],
		[ 'OP2',  'O',    -5.407,  -34.972,   31.325,  1.00,  66.30 ],
		[ "O5'",  'O',    -3.554,  -35.016,   32.906,  1.00,  65.14 ],
		[ "C5'",  'C',    -3.079,  -35.975,   33.792,  1.00,  67.61 ],
		[ "C4'",  'C',    -2.072,  -36.873,   33.104,  1.00,  68.92 ],
		[ "O4'",  'O',    -2.713,  -37.691,   32.098,  1.00,  69.05 ],
		[ "C3'",  'C',    -0.965,  -36.135,   32.370,  1.00,  69.18 ],
		[ "O3'",  'O',     0.245,  -36.826,   32.590,  1.00,  70.41 ],
		[ "C2'",  'C',    -1.480,  -36.164,   30.936,  1.00,  69.14 ],
		[ "C1'",  'C',    -1.985,  -37.576,   30.888,  1.00,  69.32 ],
		[ 'N9',   'N',    -2.954,  -37.923,   29.873,  1.00,  70.65 ],
		[ 'C8',   'C',    -4.179,  -37.347,   29.699,  1.00,  71.08 ],
		[ 'N7',   'N',    -4.915,  -37.872,   28.760,  1.00,  69.99 ],
		[ 'C5',   'C',    -4.101,  -38.871,   28.301,  1.00,  70.40 ],
		[ 'C6',   'C',    -4.319,  -39.788,   27.285,  1.00,  71.09 ],
		[ 'N6',   'N',    -5.467,  -39.769,   26.600,  1.00,  69.40 ],
		[ 'N1',   'N',    -3.310,  -40.676,   27.030,  1.00,  73.29 ],
		[ 'C2',   'C',    -2.171,  -40.645,   27.772,  1.00,  72.89 ],
		[ 'N3',   'N',    -1.859,  -39.807,   28.771,  1.00,  72.02 ],
		[ 'C4',   'C',    -2.884,  -38.941,   28.969,  1.00,  71.12 ],
	] ],
	[ 'DG', 3, [
		[ 'P',    'P',     1.505,  -36.494,   31.680,  1.00,  74.08 ],
		[ 'OP1',  'O',     2.769,  -36.955,   32.313,  1.00,  73.14 ],
		[ 'OP2',  'O',     1.367,  -35.053,   31.382,  1.00,  75.77 ],
		[ "O5'",  'O',     1.182,  -37.269,   30.306,  1.00,  74.84 ],
		[ "C5'",  'C',     1.414,  -38.659,   30.106,  1.00,  75.73 ],
		[ "C4'",  'C',     2.231,  -38.953,   28.850,  1.00,  76.52 ],
		[ "O4'",  'O',     1.378,  -39.089,   27.681,  1.00,  75.82 ],
		[ "C3'",  'C',     3.272,  -37.926,   28.404,  1.00,  77.07 ],
		[ "O3'",  'O',     4.294,  -38.652,   27.649,  1.00,  78.57 ],
		[ "C2'",  'C',     2.415,  -36.935,   27.613,  1.00,  75.93 ],
		[ "C1'",  'C',     1.450,  -37.898,   26.931,  1.00,  74.90 ],
		[ 'N9',   'N',     0.080,  -37.454,   26.831,  1.00,  73.34 ],
		[ 'C8',   'C',    -0.609,  -36.487,   27.531,  1.00,  72.20 ],
		[ 'N7',   'N',    -1.852,  -36.382,   27.163,  1.00,  71.06 ],
		[ 'C5',   'C',    -1.967,  -37.343,   26.164,  1.00,  71.80 ],
		[ 'C6',   'C',    -3.063,  -37.713,   25.362,  1.00,  71.73 ],
		[ 'O6',   'O',    -4.189,  -37.249,   25.380,  1.00,  72.03 ],
		[ 'N1',   'N',    -2.777,  -38.738,   24.476,  1.00,  72.15 ],
		[ 'C2',   'C',    -1.552,  -39.332,   24.366,  1.00,  73.18 ],
		[ 'N2',   'N',    -1.487,  -40.288,   23.443,  1.00,  75.14 ],
		[ 'N3',   'N',    -0.489,  -39.011,   25.094,  1.00,  72.21 ],
		[ 'C4',   'C',    -0.790,  -38.014,   25.959,  1.00,  72.22 ],
	] ],
	[ 'DT', 4, [
		[ 'P',    'P',     5.307,  -37.953,   26.623,  1.00,  79.20 ],
		[ 'OP1',  'O',     6.568,  -38.728,   26.549,  1.00,  78.67 ],
		[ 'OP2',  'O',     5.338,  -36.498,   26.943,  1.00,  77.91 ],
		[ "O5'",  'O',     4.515,  -38.220,   25.261,  1.00,  79.72 ],
		[ "C5'",  'C',     4.240,  -39.570,   24.895,  1.00,  80.54 ],
		[ "C4'",  'C',     3.606,  -39.640,   23.514,  1.00,  81.11 ],
		[ "O4'",  'O',     2.225,  -39.166,   23.549,  1.00,  80.87 ],
		[ "C3'",  'C',     4.308,  -38.796,   22.454,  1.00,  80.86 ],
		[ "O3'",  'O',     4.141,  -39.371,   21.161,  1.00,  82.80 ],
		[ "C2'",  'C',     3.539,  -37.504,   22.571,  1.00,  79.81 ],
		[ "C1'",  'C',     2.135,  -38.100,   22.630,  1.00,  79.11 ],
		[ 'N1',   'N',     1.081,  -37.120,   23.011,  1.00,  77.00 ],
		[ 'C2',   'C',    -0.126,  -37.213,   22.369,  1.00,  74.84 ],
		[ 'O2',   'O',    -0.356,  -38.076,   21.552,  1.00,  72.68 ],
		[ 'N3',   'N',    -1.046,  -36.262,   22.747,  1.00,  74.84 ],
		[ 'C4',   'C',    -0.865,  -35.248,   23.676,  1.00,  74.32 ],
		[ 'O4',   'O',    -1.714,  -34.432,   23.980,  1.00,  72.54 ],
		[ 'C5',   'C',     0.419,  -35.203,   24.296,  1.00,  75.30 ],
		[ 'C7',   'C',     0.684,  -34.141,   25.313,  1.00,  75.98 ],
		[ 'C6',   'C',     1.329,  -36.122,   23.946,  1.00,  76.20 ],
	] ],
	[ 'DA', 5, [
		[ 'P',    'P',     5.053,  -38.899,   19.929,  1.00,  84.39 ],
		[ 'OP1',  'O',     6.458,  -39.144,   20.384,  1.00,  82.68 ],
		[ 'OP2',  'O',     4.597,  -37.529,   19.558,  1.00,  82.76 ],
		[ "O5'",  'O',     4.692,  -39.866,   18.681,  1.00,  82.05 ],
		[ "C5'",  'C',     3.391,  -40.489,   18.513,  1.00,  82.76 ],
		[ "C4'",  'C',     2.224,  -39.665,   17.908,  1.00,  82.63 ],
		[ "O4'",  'O',     1.803,  -38.578,   18.774,  1.00,  81.80 ],
		[ "C3'",  'C',     2.428,  -39.010,   16.531,  1.00,  83.07 ],
		[ "O3'",  'O',     1.394,  -39.351,   15.581,  1.00,  83.36 ],
		[ "C2'",  'C',     2.378,  -37.518,   16.834,  1.00,  83.13 ],
		[ "C1'",  'C',     1.322,  -37.578,   17.908,  1.00,  82.01 ],
		[ 'N9',   'N',     1.157,  -36.411,   18.728,  1.00,  81.07 ],
		[ 'C8',   'C',     2.102,  -35.766,   19.464,  1.00,  80.77 ],
		[ 'N7',   'N',     1.626,  -34.752,   20.133,  1.00,  80.74 ],
		[ 'C5',   'C',     0.282,  -34.761,   19.807,  1.00,  80.02 ],
		[ 'C6',   'C',    -0.775,  -33.935,   20.193,  1.00,  79.32 ],
		[ 'N6',   'N',    -0.607,  -32.906,   21.031,  1.00,  79.33 ],
		[ 'N1',   'N',    -1.992,  -34.207,   19.677,  1.00,  78.90 ],
		[ 'C2',   'C',    -2.134,  -35.235,   18.832,  1.00,  79.06 ],
		[ 'N3',   'N',    -1.217,  -36.088,   18.398,  1.00,  79.23 ],
		[ 'C4',   'C',    -0.027,  -35.778,   18.935,  1.00,  80.08 ],
	] ],
	[ 'DT', 6, [
		[ 'P',    'P',     1.616,  -39.002,   14.023,  1.00,  83.82 ],
		[ 'OP1',  'O',     1.063,  -40.106,   13.197,  1.00,  82.71 ],
		[ 'OP2',  'O',     3.008,  -38.483,   13.848,  1.00,  82.37 ],
		[ "O5'",  'O',     0.632,  -37.785,   13.842,  1.00,  83.12 ],
		[ "C5'",  'C',    -0.738,  -37.999,   14.025,  1.00,  84.23 ],
		[ "C4'",  'C',    -1.444,  -36.760,   13.535,  1.00,  84.61 ],
		[ "O4'",  'O',    -1.550,  -35.798,   14.638,  1.00,  83.76 ],
		[ "C3'",  'C',    -0.661,  -36.122,   12.384,  1.00,  84.60 ],
		[ "O3'",  'O',    -1.527,  -35.743,   11.285,  1.00,  85.81 ],
		[ "C2'",  'C',     0.042,  -34.965,   13.103,  1.00,  83.83 ],
		[ "C1'",  'C',    -0.941,  -34.593,   14.229,  1.00,  82.44 ],
		[ 'N1',   'N',    -0.358,  -33.819,   15.394,  1.00,  80.40 ],
		[ 'C2',   'C',    -1.218,  -33.092,   16.181,  1.00,  78.33 ],
		[ 'O2',   'O',    -2.410,  -33.061,   16.020,  1.00,  77.70 ],
		[ 'N3',   'N',    -0.631,  -32.391,   17.189,  1.00,  77.77 ],
		[ 'C4',   'C',     0.709,  -32.338,   17.497,  1.00,  78.12 ],
		[ 'O4',   'O',     1.149,  -31.679,   18.414,  1.00,  78.20 ],
		[ 'C5',   'C',     1.573,  -33.110,   16.668,  1.00,  79.26 ],
		[ 'C7',   'C',     3.047,  -33.095,   16.950,  1.00,  79.32 ],
		[ 'C6',   'C',     1.012,  -33.799,   15.659,  1.00,  80.45 ],
	] ],
);
my @bases;
$serial = 0;
for my $r (@bases_res) {
	my ($resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @bases, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			altloc => '', resname => $resname, chain => 'P', resseq => $resseq, icode => '',
			x => $a->[2], y => $a->[3], z => $a->[4], occ => $a->[5], b => $a->[6],
		);
	}
}
push @bases, 'END';

# --- rna.pdb -- a hairpin loop with riboses in it -------------------------
#
# Residues 2657 to 2662 of chain A of 1MSY, the GUAA tetraloop mutant of the
# sarcin/ricin domain of E. coli 23S rRNA, 1.41 A, downloaded from
# https://files.rcsb.org/download/1MSY.pdb and written out exactly as
# deposited.  Six nucleotides: the A and C that close the loop, and the G, U, A
# and A of the tetraloop itself.
#
# bases.pdb is DNA and this is RNA because the sugar is the difference the
# torsion angles are about.  A deoxyribose has no O2' and puckers C2'-endo, a
# ribose has one and puckers C3'-endo, and a fixture with only the first in it
# would exercise half of nuc_torsions()'s answer.  A tetraloop rather than a
# stretch of helix for the same reason: the four loop nucleotides are where an
# RNA does something other than A-form, so the file holds both.
#
# Residues 2663 and 2669 of the entry are the two with alternate conformers in
# them, and neither is in this window: the altloc paths have fixtures of their
# own and this one is about geometry.  The window is cut on both sides, so the
# first residue has no alpha and the last no epsilon or zeta -- which is the
# same thing a gap in a model does, and is worth having in a fixture.
my @rna_res = (
	[ 'A', 2657, [
		[ 'P',     'P',     9.611,    14.500,     0.214,  1.00,  10.65 ],
		[ 'OP1',   'O',     9.993,    13.896,    -1.097,  1.00,  11.48 ],
		[ 'OP2',   'O',     8.227,    14.947,     0.451,  1.00,  10.90 ],
		[ "O5'",   'O',     9.943,    13.444,     1.384,  1.00,  10.06 ],
		[ "C5'",   'C',    11.215,    12.733,     1.326,  1.00,  10.13 ],
		[ "C4'",   'C',    11.356,    11.908,     2.594,  1.00,   9.99 ],
		[ "O4'",   'O',    11.377,    12.808,     3.745,  1.00,   9.83 ],
		[ "C3'",   'C',    10.133,    11.044,     2.910,  1.00,   9.89 ],
		[ "O3'",   'O',    10.197,     9.823,     2.185,  1.00,   9.95 ],
		[ "C2'",   'C',    10.362,    10.754,     4.402,  1.00,   9.87 ],
		[ "O2'",   'O',    11.438,     9.824,     4.568,  1.00,  10.96 ],
		[ "C1'",   'C',    10.873,    12.110,     4.875,  1.00,   9.69 ],
		[ 'N9',    'N',     9.848,    12.950,     5.498,  1.00,   9.16 ],
		[ 'C8',    'C',     9.258,    14.099,     5.058,  1.00,   8.94 ],
		[ 'N7',    'N',     8.350,    14.572,     5.883,  1.00,   8.79 ],
		[ 'C5',    'C',     8.351,    13.676,     6.948,  1.00,   8.82 ],
		[ 'C6',    'C',     7.609,    13.636,     8.147,  1.00,   8.78 ],
		[ 'N6',    'N',     6.731,    14.596,     8.456,  1.00,   8.43 ],
		[ 'N1',    'N',     7.820,    12.611,     9.005,  1.00,   8.88 ],
		[ 'C2',    'C',     8.734,    11.725,     8.614,  1.00,   9.02 ],
		[ 'N3',    'N',     9.501,    11.632,     7.514,  1.00,   9.17 ],
		[ 'C4',    'C',     9.266,    12.678,     6.714,  1.00,   9.02 ],
	] ],
	[ 'C', 2658, [
		[ 'P',     'P',     8.831,     9.187,     1.660,  1.00,  10.05 ],
		[ 'OP1',   'O',     9.207,     7.901,     1.023,  1.00,  10.73 ],
		[ 'OP2',   'O',     8.048,    10.174,     0.885,  1.00,  10.35 ],
		[ "O5'",   'O',     8.002,     8.909,     2.991,  1.00,   9.63 ],
		[ "C5'",   'C',     8.378,     7.849,     3.883,  1.00,   9.54 ],
		[ "C4'",   'C',     7.521,     7.952,     5.132,  1.00,   9.37 ],
		[ "O4'",   'O',     7.738,     9.242,     5.778,  1.00,   8.97 ],
		[ "C3'",   'C',     6.018,     8.038,     4.826,  1.00,   9.29 ],
		[ "O3'",   'O',     5.579,     6.673,     4.660,  1.00,   9.66 ],
		[ "C2'",   'C',     5.519,     8.599,     6.160,  1.00,   8.93 ],
		[ "O2'",   'O',     5.635,     7.675,     7.239,  1.00,   9.73 ],
		[ "C1'",   'C',     6.562,     9.700,     6.426,  1.00,   8.74 ],
		[ 'N1',    'N',     6.153,    10.974,     5.791,  1.00,   8.36 ],
		[ 'C2',    'C',     5.213,    11.754,     6.461,  1.00,   8.21 ],
		[ 'O2',    'O',     4.762,    11.275,     7.521,  1.00,   8.53 ],
		[ 'N3',    'N',     4.813,    12.931,     5.945,  1.00,   7.91 ],
		[ 'C4',    'C',     5.283,    13.331,     4.759,  1.00,   7.87 ],
		[ 'N4',    'N',     4.874,    14.521,     4.303,  1.00,   7.74 ],
		[ 'C5',    'C',     6.233,    12.549,     4.047,  1.00,   8.00 ],
		[ 'C6',    'C',     6.637,    11.376,     4.574,  1.00,   8.25 ],
	] ],
	[ 'G', 2659, [
		[ 'P',     'P',     4.319,     6.444,     3.690,  1.00,   9.86 ],
		[ 'OP1',   'O',     4.075,     4.977,     3.723,  1.00,  11.15 ],
		[ 'OP2',   'O',     4.532,     7.132,     2.410,  1.00,   9.93 ],
		[ "O5'",   'O',     3.153,     7.231,     4.427,  1.00,   9.54 ],
		[ "C5'",   'C',     2.611,     6.681,     5.641,  1.00,   9.55 ],
		[ "C4'",   'C',     1.506,     7.605,     6.143,  1.00,   9.22 ],
		[ "O4'",   'O',     2.103,     8.893,     6.450,  1.00,   8.70 ],
		[ "C3'",   'C',     0.471,     7.995,     5.071,  1.00,   9.24 ],
		[ "O3'",   'O',    -0.465,     6.910,     4.954,  1.00,  10.28 ],
		[ "C2'",   'C',    -0.115,     9.229,     5.764,  1.00,   8.75 ],
		[ "O2'",   'O',    -1.096,     8.903,     6.730,  1.00,   9.00 ],
		[ "C1'",   'C',     1.139,     9.936,     6.389,  1.00,   8.40 ],
		[ 'N9',    'N',     1.571,    10.856,     5.330,  1.00,   7.75 ],
		[ 'C8',    'C',     2.552,    10.678,     4.371,  1.00,   7.60 ],
		[ 'N7',    'N',     2.619,    11.717,     3.549,  1.00,   7.47 ],
		[ 'C5',    'C',     1.607,    12.568,     4.003,  1.00,   7.41 ],
		[ 'C6',    'C',     1.136,    13.819,     3.542,  1.00,   7.45 ],
		[ 'O6',    'O',     1.588,    14.476,     2.554,  1.00,   8.60 ],
		[ 'N1',    'N',     0.087,    14.342,     4.271,  1.00,   7.30 ],
		[ 'C2',    'C',    -0.519,    13.738,     5.348,  1.00,   7.24 ],
		[ 'N2',    'N',    -1.538,    14.407,     5.931,  1.00,   6.92 ],
		[ 'N3',    'N',    -0.086,    12.585,     5.790,  1.00,   7.38 ],
		[ 'C4',    'C',     0.952,    12.055,     5.090,  1.00,   7.44 ],
	] ],
	[ 'U', 2660, [
		[ 'P',     'P',    -0.918,     6.411,     3.501,  1.00,  10.76 ],
		[ 'OP1',   'O',    -1.877,     5.313,     3.710,  1.00,  11.88 ],
		[ 'OP2',   'O',     0.258,     6.170,     2.600,  1.00,  11.12 ],
		[ "O5'",   'O',    -1.679,     7.717,     2.965,  1.00,  10.52 ],
		[ "C5'",   'C',    -2.050,     7.930,     1.590,  1.00,  10.16 ],
		[ "C4'",   'C',    -3.462,     8.479,     1.565,  1.00,   9.82 ],
		[ "O4'",   'O',    -4.353,     7.455,     2.117,  1.00,   9.74 ],
		[ "C3'",   'C',    -3.710,     9.689,     2.452,  1.00,   9.75 ],
		[ "O3'",   'O',    -3.421,    10.867,     1.691,  1.00,   9.59 ],
		[ "C2'",   'C',    -5.214,     9.613,     2.721,  1.00,   9.68 ],
		[ "O2'",   'O',    -5.966,    10.225,     1.654,  1.00,   9.88 ],
		[ "C1'",   'C',    -5.464,     8.119,     2.693,  1.00,   9.67 ],
		[ 'N1',    'N',    -5.794,     7.409,     3.920,  1.00,   9.74 ],
		[ 'C2',    'C',    -7.075,     7.536,     4.406,  1.00,   9.94 ],
		[ 'O2',    'O',    -7.870,     8.248,     3.852,  1.00,  10.33 ],
		[ 'N3',    'N',    -7.362,     6.837,     5.529,  1.00,  10.24 ],
		[ 'C4',    'C',    -6.486,     6.042,     6.240,  1.00,  10.61 ],
		[ 'O4',    'O',    -6.915,     5.484,     7.253,  1.00,  11.80 ],
		[ 'C5',    'C',    -5.161,     5.991,     5.703,  1.00,  10.42 ],
		[ 'C6',    'C',    -4.851,     6.689,     4.611,  1.00,  10.08 ],
	] ],
	[ 'A', 2661, [
		[ 'P',     'P',    -2.367,    11.976,     2.175,  1.00,   8.93 ],
		[ 'OP1',   'O',    -2.043,    12.664,     0.895,  1.00,   8.47 ],
		[ 'OP2',   'O',    -1.339,    11.367,     3.030,  1.00,   8.61 ],
		[ "O5'",   'O',    -3.249,    12.955,     3.066,  1.00,   9.46 ],
		[ "C5'",   'C',    -4.352,    13.736,     2.527,  1.00,   9.62 ],
		[ "C4'",   'C',    -5.494,    13.721,     3.532,  1.00,   9.56 ],
		[ "O4'",   'O',    -5.799,    12.358,     3.944,  1.00,   9.32 ],
		[ "C3'",   'C',    -5.174,    14.430,     4.847,  1.00,   9.73 ],
		[ "O3'",   'O',    -5.534,    15.792,     4.701,  1.00,  10.07 ],
		[ "C2'",   'C',    -6.125,    13.760,     5.832,  1.00,   9.44 ],
		[ "O2'",   'O',    -7.470,    14.228,     5.693,  1.00,   9.84 ],
		[ "C1'",   'C',    -6.077,    12.344,     5.346,  1.00,   9.26 ],
		[ 'N9',    'N',    -5.181,    11.363,     5.949,  1.00,   9.20 ],
		[ 'C8',    'C',    -3.832,    11.174,     5.791,  1.00,   9.37 ],
		[ 'N7',    'N',    -3.362,    10.163,     6.486,  1.00,   9.58 ],
		[ 'C5',    'C',    -4.477,     9.647,     7.132,  1.00,   9.65 ],
		[ 'C6',    'C',    -4.637,     8.560,     8.024,  1.00,  10.01 ],
		[ 'N6',    'N',    -3.644,     7.759,     8.419,  1.00,  10.42 ],
		[ 'N1',    'N',    -5.879,     8.346,     8.466,  1.00,  10.09 ],
		[ 'C2',    'C',    -6.883,     9.132,     8.063,  1.00,   9.90 ],
		[ 'N3',    'N',    -6.881,    10.183,     7.244,  1.00,   9.55 ],
		[ 'C4',    'C',    -5.599,    10.377,     6.816,  1.00,   9.42 ],
	] ],
	[ 'A', 2662, [
		[ 'P',     'P',    -4.774,    16.968,     5.445,  1.00,  10.09 ],
		[ 'OP1',   'O',    -5.351,    18.199,     4.852,  1.00,  10.69 ],
		[ 'OP2',   'O',    -3.316,    16.744,     5.465,  1.00,   9.97 ],
		[ "O5'",   'O',    -5.281,    16.858,     6.959,  1.00,  10.03 ],
		[ "C5'",   'C',    -6.653,    17.102,     7.297,  1.00,  10.13 ],
		[ "C4'",   'C',    -6.870,    16.547,     8.695,  1.00,   9.72 ],
		[ "O4'",   'O',    -6.679,    15.128,     8.639,  1.00,   9.45 ],
		[ "C3'",   'C',    -5.858,    17.026,     9.724,  1.00,   9.80 ],
		[ "O3'",   'O',    -6.372,    18.227,    10.301,  1.00,  10.87 ],
		[ "C2'",   'C',    -5.810,    15.870,    10.725,  1.00,   9.51 ],
		[ "O2'",   'O',    -6.838,    15.918,    11.693,  1.00,   9.53 ],
		[ "C1'",   'C',    -6.054,    14.638,     9.806,  1.00,   9.19 ],
		[ 'N9',    'N',    -4.746,    14.076,     9.399,  1.00,   8.85 ],
		[ 'C8',    'C',    -3.740,    14.630,     8.638,  1.00,   8.88 ],
		[ 'N7',    'N',    -2.714,    13.824,     8.476,  1.00,   8.80 ],
		[ 'C5',    'C',    -3.042,    12.691,     9.204,  1.00,   8.60 ],
		[ 'C6',    'C',    -2.376,    11.488,     9.431,  1.00,   8.62 ],
		[ 'N6',    'N',    -1.159,    11.201,     8.979,  1.00,   8.80 ],
		[ 'N1',    'N',    -2.982,    10.559,    10.189,  1.00,   8.65 ],
		[ 'C2',    'C',    -4.208,    10.836,    10.680,  1.00,   8.64 ],
		[ 'N3',    'N',    -4.949,    11.943,    10.522,  1.00,   8.60 ],
		[ 'C4',    'C',    -4.288,    12.836,     9.767,  1.00,   8.62 ],
	] ],
);
my @rna;
$serial = 0;
for my $r (@rna_res) {
	my ($resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @rna, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			altloc => '', resname => $resname, chain => 'A', resseq => $resseq,
			icode => '', x => $a->[2], y => $a->[3], z => $a->[4],
			occ => $a->[5], b => $a->[6],
		);
	}
}
push @rna, 'END';

# --- aform.pdb -- the A-form RNA stack Condon's Figure 4 measures -----------
#
# Residues 13 to 18 of chain B of 157D -- r(CGCGAAUUAGCG) with two G(anti).A(anti)
# pairs, 1.8 A, Leonard, N J et al. (1994) -- downloaded from
# https://files.rcsb.org/download/157D.pdb and written out exactly as deposited.
# Six nucleotides, C G C G A A, and five consecutive stacks along one strand.
#
# The window starts at 13 because that is where the paper this fixture is for
# starts.  Figure 4 of Condon, D E et al. (2015) J Chem Theory Comput
# 11(6):2729-2742 illustrates its three stacking variables on residues 13 (C)
# and 14 (G) of this entry and reports d0 = 4.5 A, omega = 40.7 degrees and
# Xi = 17.3 degrees for the pair, which is the one worked example either the
# paper or the author's PDB_stacker gives.  t/stacking.t checks base_stacks()
# against those three numbers; nothing else in t/data has a published answer to
# check them against, which is why this file is here and not another stretch of
# the helix already in the directory.
#
# One strand rather than the duplex: Figure 4's pair is along a strand, the 5'
# to 3' order an omega is measured in only means something along one, and the
# second strand would add nine cross-strand pairs whose answer nobody has
# published.  duplex.pdb and wobble.pdb are where two strands are covered.

my @aform_res = (
	[ 'C', 13, [
		[ "O5'",  'O',    12.416,    -3.317,   -14.492,  1.00,  29.73 ],
		[ "C5'",  'C',    12.634,    -3.808,   -13.147,  1.00,  33.58 ],
		[ "C4'",  'C',    13.519,    -5.055,   -13.371,  1.00,  26.09 ],
		[ "O4'",  'O',    14.656,    -4.591,   -14.072,  1.00,  19.29 ],
		[ "C3'",  'C',    14.080,    -5.619,   -12.088,  1.00,  27.10 ],
		[ "O3'",  'O',    13.313,    -6.619,   -11.451,  1.00,  26.37 ],
		[ "C2'",  'C',    15.458,    -6.100,   -12.503,  1.00,  19.28 ],
		[ "O2'",  'O',    15.239,    -7.322,   -13.135,  1.00,  24.40 ],
		[ "C1'",  'C',    15.841,    -5.023,   -13.450,  1.00,  11.62 ],
		[ 'N1',   'N',    16.646,    -3.971,   -12.839,  1.00,  15.40 ],
		[ 'C2',   'C',    17.825,    -4.383,   -12.225,  1.00,  14.14 ],
		[ 'O2',   'O',    18.132,    -5.570,   -12.192,  1.00,  27.52 ],
		[ 'N3',   'N',    18.617,    -3.417,   -11.678,  1.00,  19.77 ],
		[ 'C4',   'C',    18.311,    -2.112,   -11.691,  1.00,   9.01 ],
		[ 'N4',   'N',    19.145,    -1.246,   -11.138,  1.00,  22.41 ],
		[ 'C5',   'C',    17.104,    -1.693,   -12.343,  1.00,  22.36 ],
		[ 'C6',   'C',    16.336,    -2.642,   -12.900,  1.00,  11.25 ],
	] ],
	[ 'G', 14, [
		[ 'P',    'P',    12.665,    -6.270,   -10.020,  1.00,  25.10 ],
		[ 'OP1',  'O',    11.328,    -6.907,   -10.122,  1.00,  35.03 ],
		[ 'OP2',  'O',    12.596,    -4.809,    -9.790,  1.00,  26.88 ],
		[ "O5'",  'O',    13.634,    -7.017,    -9.001,  1.00,  20.79 ],
		[ "C5'",  'C',    13.992,    -8.385,    -9.388,  1.00,  23.59 ],
		[ "C4'",  'C',    15.297,    -8.683,    -8.733,  1.00,  18.22 ],
		[ "O4'",  'O',    16.339,    -7.990,    -9.360,  1.00,  25.68 ],
		[ "C3'",  'C',    15.459,    -8.478,    -7.284,  1.00,  16.41 ],
		[ "O3'",  'O',    14.841,    -9.268,    -6.339,  1.00,  27.15 ],
		[ "C2'",  'C',    16.919,    -8.212,    -7.068,  1.00,  19.58 ],
		[ "O2'",  'O',    17.573,    -9.399,    -6.729,  1.00,  28.41 ],
		[ "C1'",  'C',    17.356,    -7.644,    -8.377,  1.00,  23.06 ],
		[ 'N9',   'N',    17.491,    -6.180,    -8.346,  1.00,  16.73 ],
		[ 'C8',   'C',    16.645,    -5.273,    -8.927,  1.00,  21.58 ],
		[ 'N7',   'N',    17.017,    -4.016,    -8.800,  1.00,  21.54 ],
		[ 'C5',   'C',    18.214,    -4.123,    -8.092,  1.00,  17.75 ],
		[ 'C6',   'C',    19.125,    -3.137,    -7.648,  1.00,  15.51 ],
		[ 'O6',   'O',    19.023,    -1.911,    -7.791,  1.00,  20.81 ],
		[ 'N1',   'N',    20.200,    -3.625,    -6.971,  1.00,  19.92 ],
		[ 'C2',   'C',    20.370,    -4.961,    -6.749,  1.00,  21.49 ],
		[ 'N2',   'N',    21.465,    -5.280,    -6.034,  1.00,  24.47 ],
		[ 'N3',   'N',    19.571,    -5.944,    -7.159,  1.00,  21.97 ],
		[ 'C4',   'C',    18.511,    -5.446,    -7.824,  1.00,  19.14 ],
	] ],
	[ 'C', 15, [
		[ 'P',    'P',    13.977,    -8.645,    -5.130,  1.00,  26.15 ],
		[ 'OP1',  'O',    13.100,    -9.770,    -4.760,  1.00,  44.30 ],
		[ 'OP2',  'O',    13.231,    -7.433,    -5.522,  1.00,  27.35 ],
		[ "O5'",  'O',    15.090,    -8.388,    -4.001,  1.00,  23.86 ],
		[ "C5'",  'C',    16.419,    -8.911,    -4.223,  1.00,  20.33 ],
		[ "C4'",  'C',    17.264,    -8.596,    -3.039,  1.00,  19.63 ],
		[ "O4'",  'O',    18.469,    -8.001,    -3.438,  1.00,  22.60 ],
		[ "C3'",  'C',    16.710,    -7.810,    -1.875,  1.00,  20.59 ],
		[ "O3'",  'O',    16.126,    -8.596,    -0.828,  1.00,  27.59 ],
		[ "C2'",  'C',    17.972,    -7.083,    -1.391,  1.00,  17.10 ],
		[ "O2'",  'O',    18.695,    -8.087,    -0.677,  1.00,  18.13 ],
		[ "C1'",  'C',    18.727,    -6.831,    -2.674,  1.00,  14.75 ],
		[ 'N1',   'N',    18.248,    -5.622,    -3.385,  1.00,  16.42 ],
		[ 'C2',   'C',    18.961,    -4.445,    -3.133,  1.00,  10.26 ],
		[ 'O2',   'O',    19.891,    -4.463,    -2.333,  1.00,  16.60 ],
		[ 'N3',   'N',    18.578,    -3.341,    -3.785,  1.00,   9.78 ],
		[ 'C4',   'C',    17.587,    -3.310,    -4.684,  1.00,  14.18 ],
		[ 'N4',   'N',    17.240,    -2.188,    -5.328,  1.00,  12.68 ],
		[ 'C5',   'C',    16.855,    -4.525,    -4.939,  1.00,  21.07 ],
		[ 'C6',   'C',    17.226,    -5.629,    -4.276,  1.00,  15.26 ],
	] ],
	[ 'G', 16, [
		[ 'P',    'P',    14.976,    -8.039,     0.176,  1.00,  19.16 ],
		[ 'OP1',  'O',    14.371,    -9.237,     0.764,  1.00,  29.17 ],
		[ 'OP2',  'O',    14.072,    -7.187,    -0.627,  1.00,  21.28 ],
		[ "O5'",  'O',    15.797,    -7.184,     1.235,  1.00,  22.47 ],
		[ "C5'",  'C',    16.035,    -7.620,     2.570,  1.00,  17.12 ],
		[ "C4'",  'C',    17.026,    -6.578,     3.077,  1.00,  19.25 ],
		[ "O4'",  'O',    17.862,    -6.249,     1.984,  1.00,  19.02 ],
		[ "C3'",  'C',    16.378,    -5.231,     3.387,  1.00,  17.98 ],
		[ "O3'",  'O',    15.757,    -5.235,     4.686,  1.00,  32.27 ],
		[ "C2'",  'C',    17.680,    -4.414,     3.421,  1.00,  13.10 ],
		[ "O2'",  'O',    18.336,    -4.933,     4.559,  1.00,  16.78 ],
		[ "C1'",  'C',    18.282,    -4.892,     2.119,  1.00,  15.44 ],
		[ 'N9',   'N',    17.725,    -4.082,     1.003,  1.00,  19.66 ],
		[ 'C8',   'C',    16.729,    -4.376,     0.104,  1.00,  12.22 ],
		[ 'N7',   'N',    16.496,    -3.424,    -0.741,  1.00,   8.53 ],
		[ 'C5',   'C',    17.396,    -2.420,    -0.408,  1.00,  14.04 ],
		[ 'C6',   'C',    17.636,    -1.129,    -0.955,  1.00,  11.77 ],
		[ 'O6',   'O',    17.070,    -0.557,    -1.882,  1.00,  14.96 ],
		[ 'N1',   'N',    18.621,    -0.422,    -0.323,  1.00,  17.87 ],
		[ 'C2',   'C',    19.308,    -0.928,     0.744,  1.00,  17.60 ],
		[ 'N2',   'N',    20.235,    -0.118,     1.279,  1.00,  17.02 ],
		[ 'N3',   'N',    19.105,    -2.115,     1.296,  1.00,  16.00 ],
		[ 'C4',   'C',    18.143,    -2.811,     0.672,  1.00,  13.67 ],
	] ],
	[ 'A', 17, [
		[ 'P',    'P',    14.537,    -4.186,     4.972,  1.00,  25.57 ],
		[ 'OP1',  'O',    13.971,    -4.694,     6.248,  1.00,  36.07 ],
		[ 'OP2',  'O',    13.638,    -4.165,     3.792,  1.00,  27.40 ],
		[ "O5'",  'O',    15.278,    -2.787,     5.165,  1.00,  21.14 ],
		[ "C5'",  'C',    16.337,    -2.693,     6.138,  1.00,  13.79 ],
		[ "C4'",  'C',    16.945,    -1.347,     5.901,  1.00,  21.17 ],
		[ "O4'",  'O',    17.428,    -1.284,     4.597,  1.00,  23.04 ],
		[ "C3'",  'C',    15.945,    -0.163,     5.929,  1.00,  25.64 ],
		[ "O3'",  'O',    15.699,     0.218,     7.287,  1.00,  32.91 ],
		[ "C2'",  'C',    16.904,     0.914,     5.346,  1.00,  18.81 ],
		[ "O2'",  'O',    17.838,     1.063,     6.411,  1.00,  20.12 ],
		[ "C1'",  'C',    17.504,     0.114,     4.236,  1.00,  17.32 ],
		[ 'N9',   'N',    16.660,     0.249,     3.039,  1.00,  14.65 ],
		[ 'C8',   'C',    15.858,    -0.689,     2.455,  1.00,  15.10 ],
		[ 'N7',   'N',    15.258,    -0.277,     1.378,  1.00,   8.62 ],
		[ 'C5',   'C',    15.712,     1.025,     1.233,  1.00,  10.74 ],
		[ 'C6',   'C',    15.452,     2.018,     0.255,  1.00,   9.90 ],
		[ 'N6',   'N',    14.642,     1.856,    -0.777,  1.00,  15.31 ],
		[ 'N1',   'N',    16.086,     3.175,     0.479,  1.00,  14.48 ],
		[ 'C2',   'C',    16.911,     3.396,     1.528,  1.00,  12.48 ],
		[ 'N3',   'N',    17.205,     2.534,     2.473,  1.00,  23.21 ],
		[ 'C4',   'C',    16.567,     1.361,     2.259,  1.00,  16.91 ],
	] ],
	[ 'A', 18, [
		[ 'P',    'P',    14.282,     0.533,     7.898,  1.00,  27.04 ],
		[ 'OP1',  'O',    14.391,    -0.010,     9.286,  1.00,  33.89 ],
		[ 'OP2',  'O',    13.164,    -0.100,     7.147,  1.00,  42.79 ],
		[ "O5'",  'O',    14.215,     2.126,     7.834,  1.00,  24.88 ],
		[ "C5'",  'C',    15.376,     2.912,     7.554,  1.00,  14.09 ],
		[ "C4'",  'C',    15.054,     4.203,     6.948,  1.00,  13.82 ],
		[ "O4'",  'O',    15.474,     4.272,     5.634,  1.00,  16.36 ],
		[ "C3'",  'C',    13.656,     4.785,     6.979,  1.00,  32.15 ],
		[ "O3'",  'O',    13.300,     5.498,     8.183,  1.00,  42.21 ],
		[ "C2'",  'C',    13.758,     5.844,     5.850,  1.00,  28.01 ],
		[ "O2'",  'O',    14.539,     6.879,     6.472,  1.00,  27.29 ],
		[ "C1'",  'C',    14.596,     5.117,     4.837,  1.00,  25.62 ],
		[ 'N9',   'N',    13.881,     4.269,     3.876,  1.00,  25.38 ],
		[ 'C8',   'C',    13.538,     2.950,     4.116,  1.00,  17.22 ],
		[ 'N7',   'N',    12.960,     2.375,     3.102,  1.00,  17.51 ],
		[ 'C5',   'C',    12.922,     3.358,     2.122,  1.00,  16.15 ],
		[ 'C6',   'C',    12.391,     3.330,     0.805,  1.00,  20.35 ],
		[ 'N6',   'N',    11.842,     2.271,     0.239,  1.00,  20.19 ],
		[ 'N1',   'N',    12.474,     4.518,     0.122,  1.00,  23.69 ],
		[ 'C2',   'C',    13.045,     5.619,     0.713,  1.00,  28.46 ],
		[ 'N3',   'N',    13.564,     5.705,     1.943,  1.00,  17.31 ],
		[ 'C4',   'C',    13.467,     4.525,     2.580,  1.00,  16.69 ],
	] ],
);
my @aform;
$serial = 0;
for my $r (@aform_res) {
	my ($resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @aform, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			altloc => '', resname => $resname, chain => 'B', resseq => $resseq, icode => '',
			x => $a->[2], y => $a->[3], z => $a->[4], occ => $a->[5], b => $a->[6],
		);
	}
}
push @aform, 'END';


# --- duplex.pdb -- four base pairs of B-form DNA --------------------------
#
# Residues 3 to 6 of chain A and 19 to 22 of chain B of 1BNA, the
# Drew-Dickerson dodecamer d(CGCGAATTCGCG)2 at 1.9 A -- the structure B-DNA is
# usually quoted from -- downloaded from
# https://files.rcsb.org/download/1BNA.pdb and written out exactly as
# deposited.  The strands are antiparallel and run A 3, 4, 5, 6 against B 22,
# 21, 20, 19, so the four pairs are C-G, G-C, A-T and A-T and all four bases
# are in the file twice, once on each strand.
#
# Two chains rather than one, and no TER record between them: a nucleic acid
# is normally read as a duplex, and a reader that needs the TER to tell the
# strands apart would get this wrong.  bases.pdb is a single strand and this is
# the pair, which is also what makes it the fixture to add base pairing to if
# that is ever written.
my @duplex_res = (
	[ 'A', 'DC', 3, [
		[ 'P',     'P',    25.064,    25.621,    19.252,  1.00,  44.67 ],
		[ 'OP1',   'O',    26.506,    25.316,    19.220,  1.00,  53.89 ],
		[ 'OP2',   'O',    24.559,    26.412,    18.115,  1.00,  57.79 ],
		[ "O5'",   'O',    24.260,    24.246,    19.327,  1.00,  35.42 ],
		[ "C5'",   'C',    24.584,    23.285,    20.335,  1.00,  45.75 ],
		[ "C4'",   'C',    23.523,    22.233,    20.245,  1.00,  43.02 ],
		[ "O4'",   'O',    22.256,    22.844,    20.453,  1.00,  36.85 ],
		[ "C3'",   'C',    23.424,    21.557,    18.903,  1.00,  40.14 ],
		[ "O3'",   'O',    24.121,    20.309,    18.928,  1.00,  49.62 ],
		[ "C2'",   'C',    21.930,    21.406,    18.661,  1.00,  53.79 ],
		[ "C1'",   'C',    21.278,    21.966,    19.909,  1.00,  22.18 ],
		[ 'N1',    'N',    20.196,    22.889,    19.521,  1.00,  25.44 ],
		[ 'C2',    'C',    18.909,    22.584,    19.816,  1.00,  19.81 ],
		[ 'O2',    'O',    18.685,    21.512,    20.382,  1.00,  29.92 ],
		[ 'N3',    'N',    17.935,    23.447,    19.502,  1.00,  21.59 ],
		[ 'C4',    'C',    18.217,    24.603,    18.897,  1.00,  14.01 ],
		[ 'N4',    'N',    17.221,    25.499,    18.629,  1.00,  26.88 ],
		[ 'C5',    'C',    19.526,    24.945,    18.571,  1.00,  27.59 ],
		[ 'C6',    'C',    20.537,    24.048,    18.899,  1.00,  27.05 ],
	] ],
	[ 'A', 'DG', 4, [
		[ 'P',     'P',    24.249,    19.412,    17.617,  1.00,  44.54 ],
		[ 'OP1',   'O',    25.420,    18.535,    17.765,  1.00,  61.90 ],
		[ 'OP2',   'O',    24.208,    20.296,    16.440,  1.00,  37.36 ],
		[ "O5'",   'O',    22.931,    18.537,    17.670,  1.00,  32.01 ],
		[ "C5'",   'C',    22.714,    17.625,    18.753,  1.00,  37.89 ],
		[ "C4'",   'C',    21.393,    16.960,    18.505,  1.00,  53.00 ],
		[ "O4'",   'O',    20.353,    17.952,    18.496,  1.00,  38.79 ],
		[ "C3'",   'C',    21.264,    16.229,    17.176,  1.00,  56.72 ],
		[ "O3'",   'O',    20.284,    15.214,    17.238,  1.00,  64.12 ],
		[ "C2'",   'C',    20.793,    17.368,    16.288,  1.00,  40.81 ],
		[ "C1'",   'C',    19.716,    17.901,    17.218,  1.00,  30.52 ],
		[ 'N9',    'N',    19.305,    19.281,    16.869,  1.00,  28.53 ],
		[ 'C8',    'C',    20.017,    20.263,    16.232,  1.00,  27.82 ],
		[ 'N7',    'N',    19.313,    21.394,    16.077,  1.00,  28.01 ],
		[ 'C5',    'C',    18.121,    21.100,    16.635,  1.00,  23.22 ],
		[ 'C6',    'C',    16.952,    21.904,    16.749,  1.00,  29.21 ],
		[ 'O6',    'O',    16.769,    23.057,    16.368,  1.00,  38.58 ],
		[ 'N1',    'N',    15.933,    21.214,    17.352,  1.00,  27.94 ],
		[ 'C2',    'C',    15.972,    19.930,    17.816,  1.00,  23.44 ],
		[ 'N2',    'N',    14.831,    19.416,    18.353,  1.00,  42.64 ],
		[ 'N3',    'N',    17.068,    19.179,    17.717,  1.00,  21.56 ],
		[ 'C4',    'C',    18.084,    19.825,    17.121,  1.00,  23.44 ],
	] ],
	[ 'A', 'DA', 5, [
		[ 'P',     'P',    20.356,    13.969,    16.245,  1.00,  57.01 ],
		[ 'OP1',   'O',    21.116,    12.891,    16.892,  1.00,  58.59 ],
		[ 'OP2',   'O',    20.837,    14.423,    14.910,  1.00,  51.96 ],
		[ "O5'",   'O',    18.810,    13.581,    16.161,  1.00,  47.12 ],
		[ "C5'",   'C',    18.015,    13.569,    17.362,  1.00,  47.67 ],
		[ "C4'",   'C',    16.672,    14.088,    16.957,  1.00,  64.79 ],
		[ "O4'",   'O',    16.842,    15.447,    16.561,  1.00,  47.60 ],
		[ "C3'",   'C',    16.019,    13.393,    15.764,  1.00,  51.50 ],
		[ "O3'",   'O',    14.762,    12.796,    16.120,  1.00,  52.18 ],
		[ "C2'",   'C',    15.952,    14.498,    14.696,  1.00,  45.00 ],
		[ "C1'",   'C',    15.851,    15.732,    15.569,  1.00,  26.88 ],
		[ 'N9',    'N',    16.391,    16.916,    14.867,  1.00,  16.69 ],
		[ 'C8',    'C',    17.658,    17.103,    14.382,  1.00,  28.14 ],
		[ 'N7',    'N',    17.863,    18.346,    13.913,  1.00,  34.85 ],
		[ 'C5',    'C',    16.673,    18.953,    14.098,  1.00,  22.49 ],
		[ 'C6',    'C',    16.230,    20.279,    13.819,  1.00,  18.12 ],
		[ 'N6',    'N',    17.045,    21.222,    13.268,  1.00,  29.30 ],
		[ 'N1',    'N',    14.966,    20.578,    14.118,  1.00,  27.61 ],
		[ 'C2',    'C',    14.178,    19.652,    14.669,  1.00,  18.53 ],
		[ 'N3',    'N',    14.463,    18.392,    14.984,  1.00,  29.16 ],
		[ 'C4',    'C',    15.750,    18.110,    14.661,  1.00,  15.08 ],
	] ],
	[ 'A', 'DA', 6, [
		[ 'P',     'P',    13.866,    12.006,    15.063,  1.00,  43.68 ],
		[ 'OP1',   'O',    13.028,    11.039,    15.800,  1.00,  42.55 ],
		[ 'OP2',   'O',    14.715,    11.499,    13.968,  1.00,  54.20 ],
		[ "O5'",   'O',    12.879,    13.111,    14.480,  1.00,  28.20 ],
		[ "C5'",   'C',    11.802,    13.597,    15.290,  1.00,  42.29 ],
		[ "C4'",   'C',    11.111,    14.603,    14.435,  1.00,  33.23 ],
		[ "O4'",   'O',    12.152,    15.460,    13.962,  1.00,  41.48 ],
		[ "C3'",   'C',    10.417,    14.070,    13.187,  1.00,  18.16 ],
		[ "O3'",   'O',     9.007,    14.369,    13.181,  1.00,  30.42 ],
		[ "C2'",   'C',    11.240,    14.692,    12.061,  1.00,  52.97 ],
		[ "C1'",   'C',    11.699,    15.974,    12.719,  1.00,  38.93 ],
		[ 'N9',    'N',    12.918,    16.526,    12.078,  1.00,  19.06 ],
		[ 'C8',    'C',    14.115,    15.899,    11.868,  1.00,  17.83 ],
		[ 'N7',    'N',    15.049,    16.714,    11.356,  1.00,  29.55 ],
		[ 'C5',    'C',    14.416,    17.901,    11.246,  1.00,  19.88 ],
		[ 'C6',    'C',    14.873,    19.187,    10.815,  1.00,  17.26 ],
		[ 'N6',    'N',    16.161,    19.418,    10.427,  1.00,  19.85 ],
		[ 'N1',    'N',    13.999,    20.191,    10.852,  1.00,  17.93 ],
		[ 'C2',    'C',    12.753,    19.962,    11.272,  1.00,  23.00 ],
		[ 'N3',    'N',    12.210,    18.824,    11.698,  1.00,  21.37 ],
		[ 'C4',    'C',    13.116,    17.823,    11.657,  1.00,  15.93 ],
	] ],
	[ 'B', 'DT', 19, [
		[ 'P',     'P',    14.604,    29.545,     6.020,  1.00,  48.40 ],
		[ 'OP1',   'O',    13.792,    30.696,     5.582,  1.00,  50.18 ],
		[ 'OP2',   'O',    15.852,    29.836,     6.749,  1.00,  44.42 ],
		[ "O5'",   'O',    13.633,    28.628,     6.885,  1.00,  53.86 ],
		[ "C5'",   'C',    12.398,    28.171,     6.303,  1.00,  55.04 ],
		[ "C4'",   'C',    11.809,    27.217,     7.302,  1.00,  44.86 ],
		[ "O4'",   'O',    12.767,    26.184,     7.534,  1.00,  48.52 ],
		[ "C3'",   'C',    11.515,    27.822,     8.669,  1.00,  41.77 ],
		[ "O3'",   'O',    10.103,    27.952,     8.891,  1.00,  57.02 ],
		[ "C2'",   'C',    12.267,    26.906,     9.630,  1.00,  39.28 ],
		[ "C1'",   'C',    12.426,    25.645,     8.799,  1.00,  27.68 ],
		[ 'N1',    'N',    13.609,    24.850,     9.205,  1.00,  21.67 ],
		[ 'C2',    'C',    13.442,    23.575,     9.656,  1.00,  31.71 ],
		[ 'O2',    'O',    12.311,    23.101,     9.802,  1.00,  36.00 ],
		[ 'N3',    'N',    14.551,    22.825,     9.913,  1.00,  24.66 ],
		[ 'C4',    'C',    15.815,    23.321,     9.777,  1.00,  40.64 ],
		[ 'O4',    'O',    16.755,    22.570,    10.029,  1.00,  31.47 ],
		[ 'C5',    'C',    15.972,    24.647,     9.362,  1.00,  31.79 ],
		[ 'C7',    'C',    17.345,    25.239,     9.234,  1.00,  30.05 ],
		[ 'C6',    'C',    14.844,    25.405,     9.048,  1.00,  14.35 ],
	] ],
	[ 'B', 'DT', 20, [
		[ 'P',     'P',     9.513,    28.533,    10.260,  1.00,  48.24 ],
		[ 'OP1',   'O',     8.145,    29.007,     9.998,  1.00,  41.28 ],
		[ 'OP2',   'O',    10.455,    29.513,    10.841,  1.00,  53.39 ],
		[ "O5'",   'O',     9.395,    27.223,    11.153,  1.00,  36.57 ],
		[ "C5'",   'C',     8.576,    26.148,    10.664,  1.00,  50.41 ],
		[ "C4'",   'C',     8.655,    25.060,    11.678,  1.00,  32.08 ],
		[ "O4'",   'O',    10.003,    24.615,    11.764,  1.00,  48.38 ],
		[ "C3'",   'C',     8.272,    25.471,    13.087,  1.00,  29.99 ],
		[ "O3'",   'O',     7.199,    24.657,    13.553,  1.00,  45.14 ],
		[ "C2'",   'C',     9.586,    25.307,    13.860,  1.00,  32.42 ],
		[ "C1'",   'C',    10.190,    24.148,    13.089,  1.00,  39.56 ],
		[ 'N1',    'N',    11.660,    24.070,    13.205,  1.00,  20.36 ],
		[ 'C2',    'C',    12.257,    22.880,    13.486,  1.00,  27.55 ],
		[ 'O2',    'O',    11.583,    21.866,    13.691,  1.00,  38.33 ],
		[ 'N3',    'N',    13.620,    22.829,    13.497,  1.00,  29.60 ],
		[ 'C4',    'C',    14.402,    23.914,    13.225,  1.00,  30.11 ],
		[ 'O4',    'O',    15.625,    23.764,    13.252,  1.00,  32.92 ],
		[ 'C5',    'C',    13.774,    25.126,    12.933,  1.00,  24.11 ],
		[ 'C7',    'C',    14.563,    26.358,    12.612,  1.00,  23.96 ],
		[ 'C6',    'C',    12.385,    25.187,    12.926,  1.00,  19.78 ],
	] ],
	[ 'B', 'DC', 21, [
		[ 'P',     'P',     6.594,    24.823,    15.016,  1.00,  54.73 ],
		[ 'OP1',   'O',     5.169,    24.424,    14.987,  1.00,  53.98 ],
		[ 'OP2',   'O',     6.870,    26.189,    15.511,  1.00,  65.53 ],
		[ "O5'",   'O',     7.409,    23.731,    15.839,  1.00,  50.67 ],
		[ "C5'",   'C',     7.331,    22.352,    15.433,  1.00,  60.86 ],
		[ "C4'",   'C',     8.100,    21.598,    16.461,  1.00,  40.86 ],
		[ "O4'",   'O',     9.478,    21.902,    16.263,  1.00,  36.88 ],
		[ "C3'",   'C',     7.766,    22.045,    17.879,  1.00,  53.80 ],
		[ "O3'",   'O',     7.036,    21.041,    18.611,  1.00,  79.04 ],
		[ "C2'",   'C',     9.123,    22.414,    18.469,  1.00,  48.43 ],
		[ "C1'",   'C',    10.107,    21.743,    17.523,  1.00,  36.51 ],
		[ 'N1',    'N',    11.328,    22.556,    17.331,  1.00,  24.72 ],
		[ 'C2',    'C',    12.534,    21.939,    17.329,  1.00,  30.96 ],
		[ 'O2',    'O',    12.560,    20.731,    17.579,  1.00,  34.53 ],
		[ 'N3',    'N',    13.639,    22.639,    17.035,  1.00,  31.69 ],
		[ 'C4',    'C',    13.560,    23.938,    16.739,  1.00,  21.53 ],
		[ 'N4',    'N',    14.685,    24.628,    16.404,  1.00,  23.72 ],
		[ 'C5',    'C',    12.338,    24.609,    16.736,  1.00,  30.74 ],
		[ 'C6',    'C',    11.193,    23.878,    17.035,  1.00,  27.58 ],
	] ],
	[ 'B', 'DG', 22, [
		[ 'P',     'P',     6.509,    21.324,    20.099,  1.00,  56.50 ],
		[ 'OP1',   'O',     5.387,    20.397,    20.396,  1.00,  50.81 ],
		[ 'OP2',   'O',     6.235,    22.774,    20.306,  1.00,  53.84 ],
		[ "O5'",   'O',     7.767,    20.924,    20.993,  1.00,  66.30 ],
		[ "C5'",   'C',     8.216,    19.559,    21.073,  1.00,  73.42 ],
		[ "C4'",   'C',     9.422,    19.557,    21.977,  1.00,  42.96 ],
		[ "O4'",   'O',    10.493,    20.260,    21.319,  1.00,  52.87 ],
		[ "C3'",   'C',     9.267,    20.267,    23.325,  1.00,  38.51 ],
		[ "O3'",   'O',    10.088,    19.657,    24.293,  1.00,  60.28 ],
		[ "C2'",   'C',     9.751,    21.670,    22.990,  1.00,  22.00 ],
		[ "C1'",   'C',    10.988,    21.226,    22.256,  1.00,  24.85 ],
		[ 'N9',    'N',    11.599,    22.357,    21.543,  1.00,  25.91 ],
		[ 'C8',    'C',    11.037,    23.545,    21.159,  1.00,  23.91 ],
		[ 'N7',    'N',    11.921,    24.362,    20.566,  1.00,  39.18 ],
		[ 'C5',    'C',    13.072,    23.653,    20.580,  1.00,  25.66 ],
		[ 'C6',    'C',    14.370,    24.003,    20.102,  1.00,  28.34 ],
		[ 'O6',    'O',    14.747,    25.057,    19.585,  1.00,  31.85 ],
		[ 'N1',    'N',    15.268,    22.983,    20.308,  1.00,  25.22 ],
		[ 'C2',    'C',    15.023,    21.776,    20.891,  1.00,  11.07 ],
		[ 'N2',    'N',    16.066,    20.914,    21.038,  1.00,  25.92 ],
		[ 'N3',    'N',    13.815,    21.452,    21.350,  1.00,  19.05 ],
		[ 'C4',    'C',    12.902,    22.429,    21.151,  1.00,  23.69 ],
	] ],
);
my @duplex;
$serial = 0;
for my $r (@duplex_res) {
	my ($chain, $resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @duplex, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			altloc => '', resname => $resname, chain => $chain, resseq => $resseq,
			icode => '', x => $a->[2], y => $a->[3], z => $a->[4],
			occ => $a->[5], b => $a->[6],
		);
	}
}
push @duplex, 'END';

# --- wobble.pdb -- an RNA duplex with a G-U wobble in it -------------------
#
# Residues 2647 to 2652 and 2668 to 2673 of chain A of 1MSY, the two strands of
# the sarcin/ricin domain's lower helix, downloaded from
# https://files.rcsb.org/download/1MSY.pdb and written out exactly as
# deposited, altlocs and partial occupancies included.
#
# The window is the one the entry's own base pair annotation makes interesting.
# _ndb_struct_na_base_pair of 1MSY numbers the six pairs it spans, in Saenger's
# scheme, as
#
#   U2647-G2673  no type: the pair is there and is none of the twenty-eight
#   G2648-U2672  28, the wobble
#   C2649-G2671  19
#   U2650-A2670  20
#   C2651-G2669  19
#   C2652-G2668  19
#
# so the file holds all three of the pairs base_pairs() looks for and one that
# it must leave alone.  rna.pdb is a hairpin loop and duplex.pdb is B-form DNA;
# this is the third case, an A-form RNA helix, and the only fixture with a
# wobble in it.
#
# Both strands are chain A with residues 2653 to 2667 -- the loop between them
# -- left out, which is what a gap in a model looks like and means the pairs
# here are within one chain rather than between two.  Residue 2669 keeps the
# two conformers of its phosphate that the entry deposits, and 2647 keeps the
# half occupancy it was refined at: neither touches a base atom, so the pairs
# are unaffected and the altloc paths get walked on a nucleic acid.
my @wobble_res = (
	[ 'U', 2647, [
		[ "O5'",   '',  'O',     20.283,     15.639,     26.904,  0.50,  22.26 ],
		[ "C5'",   '',  'C',     21.326,     16.498,     27.426,  0.50,  21.79 ],
		[ "C4'",   '',  'C',     20.788,     17.269,     28.593,  0.50,  21.61 ],
		[ "O4'",   '',  'O',     21.803,     17.848,     29.454,  0.50,  21.49 ],
		[ "C3'",   '',  'C',     19.861,     18.441,     28.274,  0.50,  21.47 ],
		[ "O3'",   '',  'O',     18.621,     17.982,     27.797,  0.50,  21.48 ],
		[ "C2'",   '',  'C',     19.762,     19.045,     29.679,  0.50,  21.43 ],
		[ "O2'",   '',  'O',     19.028,     18.222,     30.570,  0.50,  21.37 ],
		[ "C1'",   '',  'C',     21.253,     19.020,     30.059,  0.50,  21.37 ],
		[ 'N1',    '',  'N',     21.982,     20.165,     29.489,  0.50,  21.16 ],
		[ 'C2',    '',  'C',     21.652,     21.438,     29.913,  0.50,  21.05 ],
		[ 'O2',    '',  'O',     20.778,     21.685,     30.730,  0.50,  20.84 ],
		[ 'N3',    '',  'N',     22.377,     22.445,     29.325,  0.50,  20.92 ],
		[ 'C4',    '',  'C',     23.381,     22.315,     28.389,  0.50,  20.92 ],
		[ 'O4',    '',  'O',     23.944,     23.328,     27.973,  0.50,  20.79 ],
		[ 'C5',    '',  'C',     23.639,     20.970,     27.986,  0.50,  20.97 ],
		[ 'C6',    '',  'C',     22.979,     19.958,     28.562,  0.50,  21.10 ],
	] ],
	[ 'G', 2648, [
		[ 'P',     '',  'P',     17.881,     18.473,     26.479,  0.50,  21.26 ],
		[ 'OP1',   '',  'O',     16.662,     17.610,     26.354,  0.50,  21.63 ],
		[ 'OP2',   '',  'O',     18.830,     18.620,     25.363,  0.50,  21.41 ],
		[ "O5'",   '',  'O',     17.332,     19.929,     26.810,  0.50,  20.66 ],
		[ "C5'",   '',  'C',     16.907,     20.180,     28.154,  1.00,  20.59 ],
		[ "C4'",   '',  'C',     16.850,     21.657,     28.391,  1.00,  19.94 ],
		[ "O4'",   '',  'O',     18.178,     22.096,     28.787,  1.00,  19.57 ],
		[ "C3'",   '',  'C',     16.481,     22.512,     27.179,  1.00,  19.77 ],
		[ "O3'",   '',  'O',     15.060,     22.702,     27.167,  1.00,  20.00 ],
		[ "C2'",   '',  'C',     17.140,     23.842,     27.568,  1.00,  19.43 ],
		[ "O2'",   '',  'O',     16.386,     24.501,     28.584,  1.00,  20.91 ],
		[ "C1'",   '',  'C',     18.442,     23.342,     28.193,  1.00,  19.24 ],
		[ 'N9',    '',  'N',     19.560,     23.163,     27.282,  1.00,  18.28 ],
		[ 'C8',    '',  'C',     20.131,     22.002,     26.831,  1.00,  18.03 ],
		[ 'N7',    '',  'N',     21.135,     22.207,     26.024,  1.00,  17.73 ],
		[ 'C5',    '',  'C',     21.221,     23.594,     25.939,  1.00,  17.54 ],
		[ 'C6',    '',  'C',     22.097,     24.431,     25.214,  1.00,  17.29 ],
		[ 'O6',    '',  'O',     23.043,     24.056,     24.451,  1.00,  17.00 ],
		[ 'N1',    '',  'N',     21.849,     25.783,     25.386,  1.00,  17.26 ],
		[ 'C2',    '',  'C',     20.842,     26.274,     26.196,  1.00,  17.35 ],
		[ 'N2',    '',  'N',     20.714,     27.602,     26.278,  1.00,  17.27 ],
		[ 'N3',    '',  'N',     20.004,     25.508,     26.872,  1.00,  17.51 ],
		[ 'C4',    '',  'C',     20.259,     24.200,     26.701,  1.00,  17.73 ],
	] ],
	[ 'C', 2649, [
		[ 'P',     '',  'P',     14.372,     22.749,     25.717,  1.00,  20.03 ],
		[ 'OP1',   '',  'O',     12.913,     22.816,     26.025,  1.00,  21.05 ],
		[ 'OP2',   '',  'O',     14.918,     21.657,     24.903,  1.00,  20.59 ],
		[ "O5'",   '',  'O',     14.792,     24.160,     25.109,  1.00,  19.71 ],
		[ "C5'",   '',  'C',     14.449,     25.368,     25.815,  1.00,  19.27 ],
		[ "C4'",   '',  'C',     15.211,     26.527,     25.228,  1.00,  18.76 ],
		[ "O4'",   '',  'O',     16.639,     26.382,     25.533,  1.00,  18.50 ],
		[ "C3'",   '',  'C',     15.172,     26.611,     23.694,  1.00,  18.33 ],
		[ "O3'",   '',  'O',     14.030,     27.258,     23.193,  1.00,  17.77 ],
		[ "C2'",   '',  'C',     16.423,     27.452,     23.426,  1.00,  18.31 ],
		[ "O2'",   '',  'O',     16.208,     28.828,     23.676,  1.00,  18.92 ],
		[ "C1'",   '',  'C',     17.405,     26.871,     24.447,  1.00,  18.22 ],
		[ 'N1',    '',  'N',     18.233,     25.801,     23.901,  1.00,  17.67 ],
		[ 'C2',    '',  'C',     19.347,     26.163,     23.118,  1.00,  17.52 ],
		[ 'O2',    '',  'O',     19.530,     27.372,     22.930,  1.00,  17.56 ],
		[ 'N3',    '',  'N',     20.159,     25.223,     22.588,  1.00,  17.23 ],
		[ 'C4',    '',  'C',     19.897,     23.934,     22.811,  1.00,  17.23 ],
		[ 'N4',    '',  'N',     20.759,     23.036,     22.304,  1.00,  16.83 ],
		[ 'C5',    '',  'C',     18.755,     23.526,     23.578,  1.00,  17.33 ],
		[ 'C6',    '',  'C',     17.950,     24.476,     24.065,  1.00,  17.55 ],
	] ],
	[ 'U', 2650, [
		[ 'P',     '',  'P',     13.375,     26.805,     21.793,  1.00,  17.08 ],
		[ 'OP1',   '',  'O',     12.068,     27.435,     21.664,  1.00,  18.75 ],
		[ 'OP2',   '',  'O',     13.590,     25.343,     21.547,  1.00,  18.08 ],
		[ "O5'",   '',  'O',     14.362,     27.455,     20.696,  1.00,  15.46 ],
		[ "C5'",   '',  'C',     14.535,     28.867,     20.536,  1.00,  14.27 ],
		[ "C4'",   '',  'C',     15.789,     29.090,     19.720,  1.00,  13.00 ],
		[ "O4'",   '',  'O',     16.894,     28.394,     20.350,  1.00,  12.38 ],
		[ "C3'",   '',  'C',     15.812,     28.488,     18.310,  1.00,  11.95 ],
		[ "O3'",   '',  'O',     15.087,     29.328,     17.415,  1.00,  10.84 ],
		[ "C2'",   '',  'C',     17.322,     28.520,     18.023,  1.00,  11.48 ],
		[ "O2'",   '',  'O',     17.783,     29.864,     17.795,  1.00,  11.59 ],
		[ "C1'",   '',  'C',     17.865,     28.059,     19.373,  1.00,  11.50 ],
		[ 'N1',    '',  'N',     18.100,     26.620,     19.514,  1.00,  11.18 ],
		[ 'C2',    '',  'C',     19.201,     26.108,     18.858,  1.00,  10.76 ],
		[ 'O2',    '',  'O',     19.909,     26.807,     18.154,  1.00,  10.43 ],
		[ 'N3',    '',  'N',     19.419,     24.771,     19.019,  1.00,  10.49 ],
		[ 'C4',    '',  'C',     18.631,     23.896,     19.747,  1.00,  10.69 ],
		[ 'O4',    '',  'O',     19.005,     22.714,     19.779,  1.00,  10.61 ],
		[ 'C5',    '',  'C',     17.480,     24.490,     20.337,  1.00,  11.02 ],
		[ 'C6',    '',  'C',     17.233,     25.807,     20.223,  1.00,  11.29 ],
	] ],
	[ 'C', 2651, [
		[ 'P',     '',  'P',     14.436,     28.682,     16.096,  1.00,  10.08 ],
		[ 'OP1',   '',  'O',     13.624,     29.769,     15.479,  1.00,  10.38 ],
		[ 'OP2',   '',  'O',     13.833,     27.382,     16.408,  1.00,  10.93 ],
		[ "O5'",   '',  'O',     15.679,     28.387,     15.119,  1.00,   9.28 ],
		[ "C5'",   '',  'C',     16.472,     29.513,     14.660,  1.00,   8.73 ],
		[ "C4'",   '',  'C',     17.688,     29.051,     13.876,  1.00,   8.41 ],
		[ "O4'",   '',  'O',     18.551,     28.341,     14.814,  1.00,   8.09 ],
		[ "C3'",   '',  'C',     17.406,     27.957,     12.815,  1.00,   8.49 ],
		[ "O3'",   '',  'O',     16.961,     28.537,     11.601,  1.00,   8.87 ],
		[ "C2'",   '',  'C',     18.828,     27.389,     12.641,  1.00,   8.16 ],
		[ "O2'",   '',  'O',     19.684,     28.333,     12.023,  1.00,   8.41 ],
		[ "C1'",   '',  'C',     19.201,     27.282,     14.116,  1.00,   8.08 ],
		[ 'N1',    '',  'N',     18.869,     26.024,     14.767,  1.00,   8.03 ],
		[ 'C2',    '',  'C',     19.731,     24.936,     14.542,  1.00,   7.99 ],
		[ 'O2',    '',  'O',     20.676,     25.066,     13.742,  1.00,   8.31 ],
		[ 'N3',    '',  'N',     19.504,     23.738,     15.155,  1.00,   8.08 ],
		[ 'C4',    '',  'C',     18.400,     23.595,     15.894,  1.00,   7.87 ],
		[ 'N4',    '',  'N',     18.287,     22.441,     16.569,  1.00,   7.90 ],
		[ 'C5',    '',  'C',     17.472,     24.661,     16.095,  1.00,   7.95 ],
		[ 'C6',    '',  'C',     17.720,     25.833,     15.479,  1.00,   7.94 ],
	] ],
	[ 'C', 2652, [
		[ 'P',     '',  'P',     16.046,     27.627,     10.627,  1.00,   9.23 ],
		[ 'OP1',   '',  'O',     15.614,     28.566,      9.561,  1.00,  10.83 ],
		[ 'OP2',   '',  'O',     15.079,     26.833,     11.417,  1.00,  10.34 ],
		[ "O5'",   '',  'O',     17.084,     26.557,     10.056,  1.00,   9.07 ],
		[ "C5'",   '',  'C',     18.147,     26.984,      9.167,  1.00,   8.65 ],
		[ "C4'",   '',  'C',     19.051,     25.804,      8.872,  1.00,   8.36 ],
		[ "O4'",   '',  'O',     19.563,     25.227,     10.119,  1.00,   8.23 ],
		[ "C3'",   '',  'C',     18.302,     24.631,      8.245,  1.00,   8.13 ],
		[ "O3'",   '',  'O',     18.058,     24.863,      6.871,  1.00,   8.05 ],
		[ "C2'",   '',  'C',     19.317,     23.487,      8.481,  1.00,   8.19 ],
		[ "O2'",   '',  'O',     20.476,     23.701,      7.651,  1.00,   8.30 ],
		[ "C1'",   '',  'C',     19.689,     23.819,      9.916,  1.00,   8.18 ],
		[ 'N1',    '',  'N',     18.966,     23.100,     10.963,  1.00,   8.08 ],
		[ 'C2',    '',  'C',     19.337,     21.770,     11.201,  1.00,   8.29 ],
		[ 'O2',    '',  'O',     20.221,     21.305,     10.454,  1.00,   8.62 ],
		[ 'N3',    '',  'N',     18.722,     21.011,     12.140,  1.00,   8.43 ],
		[ 'C4',    '',  'C',     17.783,     21.587,     12.884,  1.00,   8.35 ],
		[ 'N4',    '',  'N',     17.255,     20.839,     13.871,  1.00,   8.63 ],
		[ 'C5',    '',  'C',     17.307,     22.918,     12.618,  1.00,   8.15 ],
		[ 'C6',    '',  'C',     17.916,     23.626,     11.655,  1.00,   8.03 ],
	] ],
	[ 'G', 2668, [
		[ 'P',     '',  'P',     21.477,     11.427,     17.392,  1.00,  15.38 ],
		[ 'OP1',   '',  'O',     22.539,     10.686,     18.120,  1.00,  16.85 ],
		[ 'OP2',   '',  'O',     20.641,     12.423,     18.090,  1.00,  16.67 ],
		[ "O5'",   '',  'O',     22.121,     12.162,     16.133,  1.00,  15.38 ],
		[ "C5'",   '',  'C',     22.997,     11.429,     15.243,  1.00,  15.28 ],
		[ "C4'",   '',  'C',     23.263,     12.250,     14.004,  1.00,  15.38 ],
		[ "O4'",   '',  'O',     22.063,     12.544,     13.246,  1.00,  14.90 ],
		[ "C3'",   '',  'C',     23.884,     13.614,     14.304,  1.00,  15.29 ],
		[ "O3'",   '',  'O',     25.260,     13.382,     14.648,  1.00,  15.46 ],
		[ "C2'",   '',  'C',     23.650,     14.291,     12.963,  1.00,  14.79 ],
		[ "O2'",   '',  'O',     24.374,     13.695,     11.897,  1.00,  15.44 ],
		[ "C1'",   '',  'C',     22.194,     13.860,     12.698,  1.00,  14.51 ],
		[ 'N9',    '',  'N',     21.244,     14.736,     13.347,  1.00,  13.82 ],
		[ 'C8',    '',  'C',     20.554,     14.470,     14.509,  1.00,  13.68 ],
		[ 'N7',    '',  'N',     19.786,     15.477,     14.852,  1.00,  13.34 ],
		[ 'C5',    '',  'C',     19.982,     16.441,     13.880,  1.00,  12.99 ],
		[ 'C6',    '',  'C',     19.391,     17.725,     13.736,  1.00,  12.58 ],
		[ 'O6',    '',  'O',     18.521,     18.305,     14.478,  1.00,  12.29 ],
		[ 'N1',    '',  'N',     19.865,     18.381,     12.614,  1.00,  12.41 ],
		[ 'C2',    '',  'C',     20.784,     17.853,     11.738,  1.00,  12.58 ],
		[ 'N2',    '',  'N',     21.132,     18.651,     10.700,  1.00,  12.20 ],
		[ 'N3',    '',  'N',     21.337,     16.654,     11.860,  1.00,  12.83 ],
		[ 'C4',    '',  'C',     20.886,     15.999,     12.944,  1.00,  13.19 ],
	] ],
	[ 'G', 2669, [
		[ 'P',     'A', 'P',     25.848,     14.457,     15.719,  0.52,  15.13 ],
		[ 'P',     'B', 'P',     26.177,     14.295,     15.548,  0.48,  15.27 ],
		[ 'OP1',   'A', 'O',     27.111,     13.915,     16.292,  0.52,  15.80 ],
		[ 'OP1',   'B', 'O',     27.558,     13.773,     15.321,  0.48,  15.72 ],
		[ 'OP2',   'A', 'O',     24.794,     14.862,     16.690,  0.52,  14.94 ],
		[ 'OP2',   'B', 'O',     25.542,     14.493,     16.869,  0.48,  15.27 ],
		[ "O5'",   '',  'O',     26.177,     15.735,     14.825,  1.00,  14.51 ],
		[ "C5'",   '',  'C',     26.886,     15.779,     13.577,  1.00,  13.79 ],
		[ "C4'",   '',  'C',     26.571,     17.015,     12.771,  1.00,  12.51 ],
		[ "O4'",   '',  'O',     25.136,     17.079,     12.503,  1.00,  11.69 ],
		[ "C3'",   '',  'C',     26.797,     18.328,     13.530,  1.00,  12.07 ],
		[ "O3'",   '',  'O',     28.165,     18.643,     13.585,  1.00,  12.06 ],
		[ "C2'",   '',  'C',     25.967,     19.296,     12.681,  1.00,  11.26 ],
		[ "O2'",   '',  'O',     26.544,     19.462,     11.389,  1.00,  10.60 ],
		[ "C1'",   '',  'C',     24.710,     18.437,     12.507,  1.00,  10.93 ],
		[ 'N9',    '',  'N',     23.718,     18.595,     13.555,  1.00,  10.33 ],
		[ 'C8',    '',  'C',     23.402,     17.711,     14.559,  1.00,  10.46 ],
		[ 'N7',    '',  'N',     22.450,     18.174,     15.364,  1.00,  10.13 ],
		[ 'C5',    '',  'C',     22.131,     19.423,     14.828,  1.00,   9.58 ],
		[ 'C6',    '',  'C',     21.200,     20.402,     15.241,  1.00,   9.09 ],
		[ 'O6',    '',  'O',     20.395,     20.353,     16.224,  1.00,   8.87 ],
		[ 'N1',    '',  'N',     21.212,     21.562,     14.456,  1.00,   8.70 ],
		[ 'C2',    '',  'C',     22.047,     21.735,     13.363,  1.00,   8.66 ],
		[ 'N2',    '',  'N',     21.938,     22.906,     12.717,  1.00,   7.95 ],
		[ 'N3',    '',  'N',     22.918,     20.830,     12.965,  1.00,   9.12 ],
		[ 'C4',    '',  'C',     22.909,     19.709,     13.721,  1.00,   9.64 ],
	] ],
	[ 'A', 2670, [
		[ 'P',     '',  'P',     28.745,     19.535,     14.776,  1.00,  12.49 ],
		[ 'OP1',   '',  'O',     30.213,     19.622,     14.554,  1.00,  13.29 ],
		[ 'OP2',   '',  'O',     28.254,     19.047,     16.092,  1.00,  13.50 ],
		[ "O5'",   '',  'O',     28.098,     20.963,     14.589,  1.00,  11.54 ],
		[ "C5'",   '',  'C',     28.423,     21.771,     13.442,  1.00,  10.88 ],
		[ "C4'",   '',  'C',     27.506,     22.967,     13.428,  1.00,  10.12 ],
		[ "O4'",   '',  'O',     26.105,     22.531,     13.442,  1.00,   9.97 ],
		[ "C3'",   '',  'C',     27.570,     23.839,     14.679,  1.00,  10.04 ],
		[ "O3'",   '',  'O',     28.680,     24.711,     14.627,  1.00,  10.23 ],
		[ "C2'",   '',  'C',     26.283,     24.656,     14.511,  1.00,   9.88 ],
		[ "O2'",   '',  'O',     26.321,     25.598,     13.454,  1.00,   9.94 ],
		[ "C1'",   '',  'C',     25.352,     23.508,     14.168,  1.00,   9.76 ],
		[ 'N9',    '',  'N',     24.703,     22.831,     15.270,  1.00,   9.43 ],
		[ 'C8',    '',  'C',     24.925,     21.580,     15.801,  1.00,   9.42 ],
		[ 'N7',    '',  'N',     24.140,     21.277,     16.813,  1.00,   9.32 ],
		[ 'C5',    '',  'C',     23.328,     22.393,     16.940,  1.00,   9.18 ],
		[ 'C6',    '',  'C',     22.285,     22.690,     17.827,  1.00,   9.10 ],
		[ 'N6',    '',  'N',     21.838,     21.842,     18.776,  1.00,   9.05 ],
		[ 'N1',    '',  'N',     21.736,     23.910,     17.691,  1.00,   9.11 ],
		[ 'C2',    '',  'C',     22.162,     24.745,     16.746,  1.00,   9.17 ],
		[ 'N3',    '',  'N',     23.144,     24.584,     15.854,  1.00,   9.29 ],
		[ 'C4',    '',  'C',     23.674,     23.362,     16.023,  1.00,   9.30 ],
	] ],
	[ 'G', 2671, [
		[ 'P',     '',  'P',     29.375,     25.125,     16.023,  1.00,  10.63 ],
		[ 'OP1',   '',  'O',     30.716,     25.662,     15.630,  1.00,  10.86 ],
		[ 'OP2',   '',  'O',     29.286,     24.058,     17.018,  1.00,  11.76 ],
		[ "O5'",   '',  'O',     28.479,     26.328,     16.569,  1.00,  10.84 ],
		[ "C5'",   '',  'C',     28.408,     27.553,     15.805,  1.00,  11.44 ],
		[ "C4'",   '',  'C',     27.288,     28.400,     16.342,  1.00,  11.92 ],
		[ "O4'",   '',  'O',     26.023,     27.699,     16.248,  1.00,  11.67 ],
		[ "C3'",   '',  'C',     27.360,     28.746,     17.837,  1.00,  12.93 ],
		[ "O3'",   '',  'O',     28.237,     29.856,     18.013,  1.00,  14.74 ],
		[ "C2'",   '',  'C',     25.902,     29.166,     18.082,  1.00,  12.74 ],
		[ "O2'",   '',  'O',     25.620,     30.427,     17.449,  1.00,  13.83 ],
		[ "C1'",   '',  'C',     25.200,     28.042,     17.336,  1.00,  12.02 ],
		[ 'N9',    '',  'N',     24.971,     26.816,     18.085,  1.00,  11.82 ],
		[ 'C8',    '',  'C',     25.635,     25.607,     18.013,  1.00,  11.72 ],
		[ 'N7',    '',  'N',     25.136,     24.723,     18.846,  1.00,  11.76 ],
		[ 'C5',    '',  'C',     24.084,     25.369,     19.483,  1.00,  11.75 ],
		[ 'C6',    '',  'C',     23.155,     24.972,     20.471,  1.00,  11.86 ],
		[ 'O6',    '',  'O',     23.084,     23.821,     21.021,  1.00,  11.93 ],
		[ 'N1',    '',  'N',     22.272,     25.971,     20.851,  1.00,  12.02 ],
		[ 'C2',    '',  'C',     22.263,     27.229,     20.320,  1.00,  12.11 ],
		[ 'N2',    '',  'N',     21.380,     28.153,     20.748,  1.00,  12.66 ],
		[ 'N3',    '',  'N',     23.113,     27.615,     19.379,  1.00,  12.00 ],
		[ 'C4',    '',  'C',     23.977,     26.653,     19.019,  1.00,  11.81 ],
	] ],
	[ 'U', 2672, [
		[ 'P',     '',  'P',     29.032,     29.996,     19.391,  1.00,  16.59 ],
		[ 'OP1',   '',  'O',     29.871,     31.220,     19.313,  1.00,  17.91 ],
		[ 'OP2',   '',  'O',     29.671,     28.681,     19.709,  1.00,  16.84 ],
		[ "O5'",   '',  'O',     27.916,     30.205,     20.517,  1.00,  17.51 ],
		[ "C5'",   '',  'C',     27.010,     31.329,     20.483,  1.00,  18.41 ],
		[ "C4'",   '',  'C',     25.904,     31.114,     21.488,  1.00,  19.00 ],
		[ "O4'",   '',  'O',     25.126,     29.927,     21.169,  1.00,  18.96 ],
		[ "C3'",   '',  'C',     26.431,     30.847,     22.898,  1.00,  19.62 ],
		[ "O3'",   '',  'O',     26.656,     32.139,     23.489,  1.00,  20.18 ],
		[ "C2'",   '',  'C',     25.262,     30.140,     23.553,  1.00,  19.43 ],
		[ "O2'",   '',  'O',     24.217,     31.040,     23.898,  1.00,  21.11 ],
		[ "C1'",   '',  'C',     24.719,     29.318,     22.380,  1.00,  19.03 ],
		[ 'N1',    '',  'N',     25.148,     27.927,     22.367,  1.00,  18.40 ],
		[ 'C2',    '',  'C',     24.390,     27.055,     23.121,  1.00,  18.09 ],
		[ 'O2',    '',  'O',     23.434,     27.468,     23.762,  1.00,  18.20 ],
		[ 'N3',    '',  'N',     24.802,     25.748,     23.129,  1.00,  17.95 ],
		[ 'C4',    '',  'C',     25.870,     25.239,     22.401,  1.00,  17.96 ],
		[ 'O4',    '',  'O',     26.102,     24.031,     22.446,  1.00,  18.26 ],
		[ 'C5',    '',  'C',     26.613,     26.208,     21.662,  1.00,  18.07 ],
		[ 'C6',    '',  'C',     26.271,     27.495,     21.710,  1.00,  18.22 ],
	] ],
	[ 'G', 2673, [
		[ 'P',     '',  'P',     27.750,     32.191,     24.647,  0.50,  20.52 ],
		[ 'OP1',   '',  'O',     28.263,     33.582,     24.710,  0.50,  20.48 ],
		[ 'OP2',   '',  'O',     28.704,     31.073,     24.544,  0.50,  20.13 ],
		[ "O5'",   '',  'O',     26.797,     31.968,     25.922,  0.50,  20.65 ],
		[ "C5'",   '',  'C',     25.594,     32.771,     25.984,  0.50,  20.91 ],
		[ "C4'",   '',  'C',     24.887,     32.643,     27.310,  0.50,  20.93 ],
		[ "O4'",   '',  'O',     23.730,     31.765,     27.155,  0.50,  20.69 ],
		[ "C3'",   '',  'C',     25.707,     32.006,     28.436,  0.50,  21.02 ],
		[ "O3'",   '',  'O',     26.449,     33.012,     29.118,  0.50,  21.66 ],
		[ "C2'",   '',  'C',     24.567,     31.512,     29.340,  0.50,  20.95 ],
		[ "O2'",   '',  'O',     23.905,     32.629,     29.922,  0.50,  21.18 ],
		[ "C1'",   '',  'C',     23.669,     30.885,     28.263,  0.50,  20.62 ],
		[ 'N9',    '',  'N',     24.159,     29.584,     27.812,  0.50,  20.22 ],
		[ 'C8',    '',  'C',     25.190,     29.319,     26.945,  0.50,  20.10 ],
		[ 'N7',    '',  'N',     25.382,     28.040,     26.747,  0.50,  19.96 ],
		[ 'C5',    '',  'C',     24.418,     27.411,     27.532,  0.50,  19.80 ],
		[ 'C6',    '',  'C',     24.110,     26.051,     27.746,  0.50,  19.58 ],
		[ 'O6',    '',  'O',     24.629,     24.988,     27.279,  0.50,  19.52 ],
		[ 'N1',    '',  'N',     23.049,     25.865,     28.623,  0.50,  19.47 ],
		[ 'C2',    '',  'C',     22.356,     26.880,     29.233,  0.50,  19.48 ],
		[ 'N2',    '',  'N',     21.369,     26.482,     30.045,  0.50,  19.36 ],
		[ 'N3',    '',  'N',     22.627,     28.165,     29.051,  0.50,  19.68 ],
		[ 'C4',    '',  'C',     23.654,     28.361,     28.193,  0.50,  19.89 ],
	] ],
);

my @wobble;
$serial = 0;
for my $r (@wobble_res) {
	my ($resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @wobble, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[2],
			altloc => $a->[1], resname => $resname, chain => 'A', resseq => $resseq,
			icode => '', x => $a->[3], y => $a->[4], z => $a->[5],
			occ => $a->[6], b => $a->[7],
		);
	}
}
push @wobble, 'END';

# --- ss.pdb -- cysteines, two of them bonded and one not ------------------
#
# Five residues of chain A of 1AHW (a Fab bound to tissue factor), lifted whole
# from /home/con/ui/pepPriML/PPB/PDB/PDBbind.v2020/1ahw.ent.pdb with their
# coordinates as deposited.  Chain A was chosen by asking the module for a chain
# holding both cases at once:
#
#   CYS 23  - CYS 88   a disulfide, SG to SG 2.05 A
#   CYS 134 - CYS 194  a disulfide, SG to SG 2.03 A
#   CYS 214            free: its SG is nowhere near another
#
# so the file exercises the rule in both directions without inventing a
# geometry.  The entry declares all four bonds in SSBOND records, which is the
# other half of the comparison: t/features.t checks the computed answer and
# t/real.t checks it against what files say about themselves.
my @ss_res = (
	[ 'CYS', 23, [
		[ 'N',    'N',     7.801,    3.335,   46.174,  1.00,  14.71 ],
		[ 'CA',   'C',     6.431,    3.744,   46.278,  1.00,  14.71 ],
		[ 'C',    'C',     5.941,    3.493,   47.682,  1.00,  14.71 ],
		[ 'O',    'O',     6.073,    2.342,   48.178,  1.00,  13.80 ],
		[ 'CB',   'C',     5.573,    2.937,   45.308,  1.00,  13.80 ],
		[ 'SG',   'S',     5.378,    3.900,   43.821,  1.00,  13.80 ],
	] ],
	[ 'CYS', 88, [
		[ 'N',    'N',     4.046,    2.898,   39.606,  1.00,   5.78 ],
		[ 'CA',   'C',     3.522,    1.876,   40.496,  1.00,   5.78 ],
		[ 'C',    'C',     2.068,    2.241,   40.462,  1.00,   5.78 ],
		[ 'O',    'O',     1.714,    3.408,   40.321,  1.00,   2.48 ],
		[ 'CB',   'C',     4.088,    1.955,   41.921,  1.00,   2.48 ],
		[ 'SG',   'S',     3.641,    3.373,   42.956,  1.00,   2.48 ],
	] ],
	[ 'CYS', 134, [
		[ 'N',    'N',    19.022,   20.078,    9.689,  1.00,  38.85 ],
		[ 'CA',   'C',    20.346,   19.673,   10.165,  1.00,  38.85 ],
		[ 'C',    'C',    19.961,   18.522,   11.113,  1.00,  38.85 ],
		[ 'O',    'O',    19.020,   18.665,   11.878,  1.00,  44.13 ],
		[ 'CB',   'C',    21.047,   20.855,   10.909,  1.00,  44.13 ],
		[ 'SG',   'S',    22.782,   20.725,   11.552,  1.00,  44.13 ],
	] ],
	[ 'CYS', 194, [
		[ 'N',    'N',    24.887,   24.953,    9.823,  1.00,  45.40 ],
		[ 'CA',   'C',    24.569,   24.862,   11.247,  1.00,  45.40 ],
		[ 'C',    'C',    25.827,   24.465,   12.010,  1.00,  45.40 ],
		[ 'O',    'O',    26.671,   23.731,   11.474,  1.00,  38.27 ],
		[ 'CB',   'C',    23.461,   23.822,   11.501,  1.00,  38.27 ],
		[ 'SG',   'S',    23.832,   22.248,   10.689,  1.00,  38.27 ],
	] ],
	[ 'CYS', 214, [
		[ 'N',    'N',    22.758,   26.326,  -10.486,  1.00,  88.86 ],
		[ 'CA',   'C',    23.222,   27.025,  -11.669,  1.00,  88.86 ],
		[ 'C',    'C',    24.024,   25.987,  -12.439,  1.00,  88.86 ],
		[ 'O',    'O',    25.290,   26.053,  -12.471,  1.00,  91.66 ],
		[ 'CB',   'C',    24.081,   28.225,  -11.227,  1.00,  91.66 ],
		[ 'SG',   'S',    23.724,   28.735,   -9.458,  1.00,  91.66 ],
		[ 'OXT',  'O',    23.323,   25.062,  -12.929,  1.00,  91.66 ],
	] ],
);
my @ss;
$serial = 0;
for my $r (@ss_res) {
	my ($resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @ss, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			altloc => '', resname => $resname, chain => 'A', resseq => $resseq, icode => '',
			x => $a->[2], y => $a->[3], z => $a->[4], occ => $a->[5], b => $a->[6],
		);
	}
}
push @ss, 'END';

# --- fold.pdb -- a stretch of protein that is actually folded ---------------
#
# Residues 3 to 62 of chain A of 1A42 (human carbonic anhydrase II, 1.05 A),
# lifted whole from /home/con/ui/pepPriML/PPB/PDB/PDBbind.v2020/1a42.ent.pdb
# with their coordinates as deposited.
#
# The other fixtures are a few residues each, chosen for one question apiece,
# and between them they contain almost no secondary structure and almost no
# backbone hydrogen bonds -- so the parts of the module that read those would go
# untested against mdtraj.  This is a contiguous run long enough to hold an
# alpha helix, a 3-10 helix and the turns and bends around them, which is what
# t/features.t compares residue by residue.  The sheet is sheet.pdb's job: this
# range has no strand in it.
#
# Sixty consecutive residues, so the phi and psi angles have real neighbours and
# the peptide-bond test has something to say yes to.
my @fold_res = (
	[ 'HIS', 4, [
		[ 'N',    'N',    10.662,   -0.401,    7.977,  1.00,  38.25 ],
		[ 'CA',   'C',    10.127,    0.268,    9.147,  1.00,  36.18 ],
		[ 'C',    'C',     9.137,   -0.769,    9.692,  1.00,  33.60 ],
		[ 'O',    'O',     9.181,   -1.906,    9.193,  1.00,  32.41 ],
		[ 'CB',   'C',     9.415,    1.580,    8.759,  1.00,  40.50 ],
		[ 'CG',   'C',     9.808,    2.795,    9.631,  1.00,  46.39 ],
		[ 'ND1',  'N',     9.962,    2.952,   10.959,  1.00,  46.24 ],
		[ 'CD2',  'C',    10.076,    4.036,    9.071,  1.00,  48.38 ],
		[ 'CE1',  'C',    10.304,    4.208,   11.202,  1.00,  48.85 ],
		[ 'NE2',  'N',    10.369,    4.845,   10.060,  1.00,  49.86 ],
	] ],
	[ 'TRP', 5, [
		[ 'N',    'N',     8.257,   -0.414,   10.635,  1.00,  27.01 ],
		[ 'CA',   'C',     7.481,   -1.387,   11.384,  1.00,  19.87 ],
		[ 'C',    'C',     6.510,   -2.204,   10.563,  1.00,  19.91 ],
		[ 'O',    'O',     6.066,   -1.770,    9.486,  1.00,  19.19 ],
		[ 'CB',   'C',     6.719,   -0.667,   12.505,  1.00,  14.02 ],
		[ 'CG',   'C',     5.438,    0.076,   12.142,  1.00,  12.29 ],
		[ 'CD1',  'C',     5.444,    1.400,   11.760,  1.00,   6.38 ],
		[ 'CD2',  'C',     4.172,   -0.466,   12.199,  1.00,   6.22 ],
		[ 'NE1',  'N',     4.172,    1.704,   11.581,  1.00,   8.90 ],
		[ 'CE2',  'C',     3.380,    0.633,   11.826,  1.00,   7.53 ],
		[ 'CE3',  'C',     3.588,   -1.693,   12.512,  1.00,   4.86 ],
		[ 'CZ2',  'C',     1.995,    0.506,   11.767,  1.00,   3.51 ],
		[ 'CZ3',  'C',     2.199,   -1.821,   12.451,  1.00,   2.00 ],
		[ 'CH2',  'C',     1.408,   -0.726,   12.081,  1.00,   4.15 ],
	] ],
	[ 'GLY', 6, [
		[ 'N',    'N',     6.158,   -3.341,   11.144,  1.00,  13.85 ],
		[ 'CA',   'C',     5.208,   -4.220,   10.536,  1.00,  12.88 ],
		[ 'C',    'C',     4.962,   -5.333,   11.521,  1.00,  14.39 ],
		[ 'O',    'O',     5.048,   -5.127,   12.727,  1.00,  14.80 ],
	] ],
	[ 'TYR', 7, [
		[ 'N',    'N',     4.655,   -6.518,   10.998,  1.00,  13.15 ],
		[ 'CA',   'C',     4.314,   -7.670,   11.805,  1.00,  14.72 ],
		[ 'C',    'C',     5.170,   -8.832,   11.402,  1.00,  14.17 ],
		[ 'O',    'O',     4.839,   -9.977,   11.668,  1.00,  18.90 ],
		[ 'CB',   'C',     2.852,   -8.046,   11.617,  1.00,  10.37 ],
		[ 'CG',   'C',     1.936,   -6.922,   12.029,  1.00,  13.25 ],
		[ 'CD1',  'C',     1.594,   -6.749,   13.379,  1.00,  11.77 ],
		[ 'CD2',  'C',     1.474,   -6.048,   11.048,  1.00,   9.56 ],
		[ 'CE1',  'C',     0.778,   -5.681,   13.754,  1.00,  13.85 ],
		[ 'CE2',  'C',     0.662,   -4.981,   11.411,  1.00,  14.02 ],
		[ 'CZ',   'C',     0.323,   -4.809,   12.759,  1.00,  15.07 ],
		[ 'OH',   'O',    -0.505,   -3.754,   13.077,  1.00,  19.57 ],
	] ],
	[ 'GLY', 8, [
		[ 'N',    'N',     6.301,   -8.588,   10.760,  1.00,  18.22 ],
		[ 'CA',   'C',     7.129,   -9.688,   10.305,  1.00,  20.53 ],
		[ 'C',    'C',     8.175,   -9.968,   11.360,  1.00,  23.45 ],
		[ 'O',    'O',     8.411,   -9.142,   12.250,  1.00,  25.40 ],
	] ],
	[ 'LYS', 9, [
		[ 'N',    'N',     8.886,  -11.088,   11.219,  1.00,  23.74 ],
		[ 'CA',   'C',     9.933,  -11.465,   12.148,  1.00,  25.06 ],
		[ 'C',    'C',    10.881,  -10.309,   12.438,  1.00,  25.45 ],
		[ 'O',    'O',    11.251,  -10.004,   13.579,  1.00,  23.26 ],
		[ 'CB',   'C',    10.716,  -12.653,   11.567,  1.00,  29.42 ],
		[ 'CG',   'C',    11.882,  -13.121,   12.465,  1.00,  34.54 ],
		[ 'CD',   'C',    12.685,  -14.290,   11.892,  1.00,  38.37 ],
		[ 'CE',   'C',    11.984,  -15.633,   12.082,  1.00,  43.35 ],
		[ 'NZ',   'N',    12.002,  -16.063,   13.475,  1.00,  42.96 ],
	] ],
	[ 'HIS', 10, [
		[ 'N',    'N',    11.187,   -9.576,   11.366,  1.00,  22.56 ],
		[ 'CA',   'C',    12.216,   -8.572,   11.501,  1.00,  22.56 ],
		[ 'C',    'C',    11.741,   -7.221,   11.979,  1.00,  20.04 ],
		[ 'O',    'O',    12.529,   -6.480,   12.563,  1.00,  20.12 ],
		[ 'CB',   'C',    12.954,   -8.470,   10.152,  1.00,  25.27 ],
		[ 'CG',   'C',    13.652,   -9.804,    9.857,  1.00,  28.90 ],
		[ 'ND1',  'N',    13.292,  -10.778,    9.010,  1.00,  33.34 ],
		[ 'CD2',  'C',    14.755,  -10.260,   10.542,  1.00,  29.87 ],
		[ 'CE1',  'C',    14.108,  -11.793,    9.170,  1.00,  32.13 ],
		[ 'NE2',  'N',    14.980,  -11.463,   10.092,  1.00,  33.23 ],
	] ],
	[ 'ASN', 11, [
		[ 'N',    'N',    10.459,   -6.922,   11.899,  1.00,  16.88 ],
		[ 'CA',   'C',     9.987,   -5.588,   12.216,  1.00,  15.73 ],
		[ 'C',    'C',     8.678,   -5.658,   12.978,  1.00,  18.45 ],
		[ 'O',    'O',     7.879,   -4.709,   12.945,  1.00,  19.79 ],
		[ 'CB',   'C',     9.790,   -4.824,   10.923,  1.00,  14.73 ],
		[ 'CG',   'C',     8.772,   -5.490,    9.992,  1.00,  16.61 ],
		[ 'OD1',  'O',     8.222,   -6.561,   10.271,  1.00,  13.34 ],
		[ 'ND2',  'N',     8.443,   -4.895,    8.853,  1.00,  14.29 ],
	] ],
	[ 'GLY', 12, [
		[ 'N',    'N',     8.440,   -6.813,   13.616,  1.00,  17.60 ],
		[ 'CA',   'C',     7.215,   -7.040,   14.359,  1.00,  16.90 ],
		[ 'C',    'C',     7.196,   -6.398,   15.736,  1.00,  17.50 ],
		[ 'O',    'O',     8.172,   -5.745,   16.140,  1.00,  15.75 ],
	] ],
	[ 'PRO', 13, [
		[ 'N',    'N',     6.141,   -6.656,   16.529,  1.00,  17.75 ],
		[ 'CA',   'C',     5.915,   -6.089,   17.867,  1.00,  17.55 ],
		[ 'C',    'C',     7.137,   -6.046,   18.796,  1.00,  15.98 ],
		[ 'O',    'O',     7.536,   -5.024,   19.357,  1.00,  14.52 ],
		[ 'CB',   'C',     4.789,   -6.940,   18.400,  1.00,  19.63 ],
		[ 'CG',   'C',     3.965,   -7.296,   17.183,  1.00,  17.16 ],
		[ 'CD',   'C',     5.070,   -7.596,   16.183,  1.00,  17.36 ],
	] ],
	[ 'GLU', 14, [
		[ 'N',    'N',     7.845,   -7.157,   18.850,  1.00,  12.59 ],
		[ 'CA',   'C',     9.054,   -7.327,   19.661,  1.00,  14.57 ],
		[ 'C',    'C',    10.158,   -6.309,   19.385,  1.00,  12.09 ],
		[ 'O',    'O',    11.141,   -6.198,   20.118,  1.00,  15.74 ],
		[ 'CB',   'C',     9.676,   -8.718,   19.446,  1.00,  19.20 ],
		[ 'CG',   'C',     8.851,   -9.870,   18.837,  1.00,  30.27 ],
		[ 'CD',   'C',     8.431,   -9.706,   17.360,  1.00,  36.96 ],
		[ 'OE1',  'O',     9.268,   -9.330,   16.531,  1.00,  40.80 ],
		[ 'OE2',  'O',     7.255,   -9.933,   17.049,  1.00,  36.61 ],
	] ],
	[ 'HIS', 15, [
		[ 'N',    'N',    10.048,   -5.570,   18.287,  1.00,  10.66 ],
		[ 'CA',   'C',    11.036,   -4.612,   17.855,  1.00,   9.85 ],
		[ 'C',    'C',    10.496,   -3.220,   17.995,  1.00,   8.80 ],
		[ 'O',    'O',    11.277,   -2.274,   18.088,  1.00,  12.25 ],
		[ 'CB',   'C',    11.397,   -4.771,   16.384,  1.00,   9.92 ],
		[ 'CG',   'C',    12.137,   -6.042,   16.030,  1.00,  14.18 ],
		[ 'ND1',  'N',    13.443,   -6.287,   16.030,  1.00,  15.65 ],
		[ 'CD2',  'C',    11.495,   -7.186,   15.628,  1.00,  15.97 ],
		[ 'CE1',  'C',    13.612,   -7.530,   15.647,  1.00,  18.19 ],
		[ 'NE2',  'N',    12.433,   -8.059,   15.409,  1.00,  17.69 ],
	] ],
	[ 'TRP', 16, [
		[ 'N',    'N',     9.192,   -3.019,   18.090,  1.00,  12.01 ],
		[ 'CA',   'C',     8.643,   -1.669,   17.993,  1.00,  13.38 ],
		[ 'C',    'C',     9.204,   -0.743,   19.068,  1.00,  15.29 ],
		[ 'O',    'O',     9.472,    0.434,   18.809,  1.00,  19.52 ],
		[ 'CB',   'C',     7.113,   -1.689,   18.107,  1.00,   7.18 ],
		[ 'CG',   'C',     6.326,   -2.385,   16.999,  1.00,  11.80 ],
		[ 'CD1',  'C',     6.891,   -2.781,   15.810,  1.00,  12.22 ],
		[ 'CD2',  'C',     4.991,   -2.715,   17.073,  1.00,   8.99 ],
		[ 'NE1',  'N',     5.924,   -3.374,   15.144,  1.00,  11.17 ],
		[ 'CE2',  'C',     4.781,   -3.361,   15.847,  1.00,   9.47 ],
		[ 'CE3',  'C',     3.947,   -2.571,   17.984,  1.00,   5.18 ],
		[ 'CZ2',  'C',     3.524,   -3.874,   15.521,  1.00,   4.07 ],
		[ 'CZ3',  'C',     2.695,   -3.083,   17.666,  1.00,   4.69 ],
		[ 'CH2',  'C',     2.484,   -3.732,   16.443,  1.00,   8.68 ],
	] ],
	[ 'HIS', 17, [
		[ 'N',    'N',     9.521,   -1.296,   20.248,  1.00,  14.80 ],
		[ 'CA',   'C',    10.020,   -0.491,   21.357,  1.00,  13.57 ],
		[ 'C',    'C',    11.293,    0.264,   20.979,  1.00,  13.18 ],
		[ 'O',    'O',    11.600,    1.269,   21.608,  1.00,  15.46 ],
		[ 'CB',   'C',    10.307,   -1.375,   22.598,  1.00,   9.49 ],
		[ 'CG',   'C',    11.572,   -2.231,   22.491,  1.00,   9.14 ],
		[ 'ND1',  'N',    12.799,   -1.928,   22.917,  1.00,   6.36 ],
		[ 'CD2',  'C',    11.640,   -3.481,   21.898,  1.00,  11.19 ],
		[ 'CE1',  'C',    13.596,   -2.935,   22.613,  1.00,   6.57 ],
		[ 'NE2',  'N',    12.892,   -3.859,   22.001,  1.00,  10.04 ],
	] ],
	[ 'LYS', 18, [
		[ 'N',    'N',    12.061,   -0.204,   19.981,  1.00,  12.69 ],
		[ 'CA',   'C',    13.297,    0.459,   19.611,  1.00,  12.08 ],
		[ 'C',    'C',    13.027,    1.802,   18.954,  1.00,  13.26 ],
		[ 'O',    'O',    13.869,    2.688,   18.988,  1.00,  15.52 ],
		[ 'CB',   'C',    14.078,   -0.439,   18.676,  1.00,  10.72 ],
		[ 'CG',   'C',    14.772,   -1.608,   19.367,  1.00,  10.61 ],
		[ 'CD',   'C',    15.545,   -2.491,   18.406,  1.00,  12.27 ],
		[ 'CE',   'C',    14.603,   -3.305,   17.519,  1.00,  12.87 ],
		[ 'NZ',   'N',    15.340,   -4.109,   16.552,  1.00,   7.96 ],
	] ],
	[ 'ASP', 19, [
		[ 'N',    'N',    11.864,    2.001,   18.350,  1.00,  14.87 ],
		[ 'CA',   'C',    11.558,    3.285,   17.742,  1.00,  17.22 ],
		[ 'C',    'C',    10.411,    3.977,   18.447,  1.00,  15.76 ],
		[ 'O',    'O',    10.266,    5.196,   18.361,  1.00,  12.15 ],
		[ 'CB',   'C',    11.183,    3.135,   16.271,  1.00,  23.23 ],
		[ 'CG',   'C',    12.386,    2.907,   15.369,  1.00,  25.80 ],
		[ 'OD1',  'O',    13.246,    3.791,   15.239,  1.00,  27.96 ],
		[ 'OD2',  'O',    12.447,    1.817,   14.807,  1.00,  32.22 ],
	] ],
	[ 'PHE', 20, [
		[ 'N',    'N',     9.558,    3.231,   19.147,  1.00,  13.15 ],
		[ 'CA',   'C',     8.472,    3.829,   19.884,  1.00,  11.47 ],
		[ 'C',    'C',     8.672,    3.273,   21.283,  1.00,  13.90 ],
		[ 'O',    'O',     8.096,    2.240,   21.663,  1.00,  12.69 ],
		[ 'CB',   'C',     7.126,    3.403,   19.286,  1.00,  13.66 ],
		[ 'CG',   'C',     7.063,    3.667,   17.790,  1.00,  12.24 ],
		[ 'CD1',  'C',     6.793,    4.955,   17.320,  1.00,  16.22 ],
		[ 'CD2',  'C',     7.331,    2.625,   16.895,  1.00,  15.45 ],
		[ 'CE1',  'C',     6.804,    5.202,   15.935,  1.00,  18.11 ],
		[ 'CE2',  'C',     7.338,    2.878,   15.518,  1.00,  19.04 ],
		[ 'CZ',   'C',     7.077,    4.165,   15.033,  1.00,  16.21 ],
	] ],
	[ 'PRO', 21, [
		[ 'N',    'N',     9.514,    3.927,   22.101,  1.00,  12.65 ],
		[ 'CA',   'C',     9.817,    3.501,   23.455,  1.00,  10.98 ],
		[ 'C',    'C',     8.570,    3.332,   24.320,  1.00,  13.87 ],
		[ 'O',    'O',     8.535,    2.486,   25.221,  1.00,  17.59 ],
		[ 'CB',   'C',    10.761,    4.568,   23.930,  1.00,  13.45 ],
		[ 'CG',   'C',    11.475,    5.022,   22.685,  1.00,  12.57 ],
		[ 'CD',   'C',    10.302,    5.098,   21.736,  1.00,   9.93 ],
	] ],
	[ 'ILE', 22, [
		[ 'N',    'N',     7.475,    4.063,   24.038,  1.00,  13.17 ],
		[ 'CA',   'C',     6.229,    3.953,   24.792,  1.00,  11.68 ],
		[ 'C',    'C',     5.631,    2.545,   24.740,  1.00,  13.35 ],
		[ 'O',    'O',     4.730,    2.222,   25.513,  1.00,  15.23 ],
		[ 'CB',   'C',     5.239,    5.022,   24.238,  1.00,  10.83 ],
		[ 'CG1',  'C',     3.986,    5.066,   25.085,  1.00,  11.88 ],
		[ 'CG2',  'C',     4.806,    4.697,   22.806,  1.00,   8.53 ],
		[ 'CD1',  'C',     4.241,    5.674,   26.448,  1.00,  16.93 ],
	] ],
	[ 'ALA', 23, [
		[ 'N',    'N',     6.137,    1.680,   23.852,  1.00,  14.54 ],
		[ 'CA',   'C',     5.714,    0.293,   23.762,  1.00,  14.78 ],
		[ 'C',    'C',     5.860,   -0.437,   25.083,  1.00,  14.86 ],
		[ 'O',    'O',     5.239,   -1.475,   25.277,  1.00,  15.22 ],
		[ 'CB',   'C',     6.545,   -0.472,   22.742,  1.00,  14.19 ],
	] ],
	[ 'LYS', 24, [
		[ 'N',    'N',     6.717,    0.092,   25.971,  1.00,  15.11 ],
		[ 'CA',   'C',     7.018,   -0.488,   27.274,  1.00,  17.68 ],
		[ 'C',    'C',     6.320,    0.277,   28.407,  1.00,  18.95 ],
		[ 'O',    'O',     6.667,    0.157,   29.580,  1.00,  21.32 ],
		[ 'CB',   'C',     8.511,   -0.417,   27.504,  1.00,  16.86 ],
		[ 'CG',   'C',     9.430,   -1.013,   26.486,  1.00,  16.77 ],
		[ 'CD',   'C',     9.456,   -2.501,   26.649,  1.00,  15.76 ],
		[ 'CE',   'C',    10.920,   -2.860,   26.767,  1.00,  20.15 ],
		[ 'NZ',   'N',    11.088,   -4.254,   26.397,  1.00,  27.00 ],
	] ],
	[ 'GLY', 25, [
		[ 'N',    'N',     5.369,    1.141,   28.089,  1.00,  22.15 ],
		[ 'CA',   'C',     4.742,    2.003,   29.070,  1.00,  18.64 ],
		[ 'C',    'C',     3.697,    1.302,   29.917,  1.00,  16.40 ],
		[ 'O',    'O',     3.393,    0.120,   29.799,  1.00,  16.03 ],
	] ],
	[ 'GLU', 26, [
		[ 'N',    'N',     3.068,    2.189,   30.672,  1.00,  17.49 ],
		[ 'CA',   'C',     2.087,    1.853,   31.680,  1.00,  20.28 ],
		[ 'C',    'C',     0.665,    1.561,   31.249,  1.00,  18.33 ],
		[ 'O',    'O',    -0.078,    1.000,   32.038,  1.00,  17.31 ],
		[ 'CB',   'C',     2.064,    2.974,   32.711,  1.00,  25.93 ],
		[ 'CG',   'C',     3.311,    3.025,   33.601,  1.00,  38.03 ],
		[ 'CD',   'C',     3.589,    1.727,   34.363,  1.00,  44.34 ],
		[ 'OE1',  'O',     2.744,    1.281,   35.150,  1.00,  50.25 ],
		[ 'OE2',  'O',     4.658,    1.152,   34.150,  1.00,  49.34 ],
	] ],
	[ 'ARG', 27, [
		[ 'N',    'N',     0.174,    1.998,   30.095,  1.00,  14.96 ],
		[ 'CA',   'C',    -1.168,    1.602,   29.716,  1.00,  12.83 ],
		[ 'C',    'C',    -1.229,    1.244,   28.232,  1.00,  12.50 ],
		[ 'O',    'O',    -1.909,    1.825,   27.394,  1.00,  10.33 ],
		[ 'CB',   'C',    -2.168,    2.727,   30.087,  1.00,  10.19 ],
		[ 'CG',   'C',    -1.782,    4.124,   29.684,  1.00,  12.21 ],
		[ 'CD',   'C',    -2.913,    5.117,   29.883,  1.00,  14.90 ],
		[ 'NE',   'N',    -3.940,    5.079,   28.852,  1.00,   9.72 ],
		[ 'CZ',   'C',    -4.669,    6.166,   28.583,  1.00,  11.81 ],
		[ 'NH1',  'N',    -4.498,    7.316,   29.225,  1.00,  11.52 ],
		[ 'NH2',  'N',    -5.625,    6.103,   27.671,  1.00,  12.77 ],
	] ],
	[ 'GLN', 28, [
		[ 'N',    'N',    -0.433,    0.233,   27.888,  1.00,  12.99 ],
		[ 'CA',   'C',    -0.358,   -0.290,   26.534,  1.00,   9.65 ],
		[ 'C',    'C',    -1.472,   -1.290,   26.313,  1.00,  10.91 ],
		[ 'O',    'O',    -1.915,   -1.978,   27.240,  1.00,  12.30 ],
		[ 'CB',   'C',     1.002,   -0.959,   26.312,  1.00,   7.47 ],
		[ 'CG',   'C',     2.125,    0.088,   26.175,  1.00,   4.90 ],
		[ 'CD',   'C',     2.000,    0.860,   24.878,  1.00,  11.03 ],
		[ 'OE1',  'O',     2.178,    0.296,   23.798,  1.00,  12.48 ],
		[ 'NE2',  'N',     1.615,    2.131,   24.878,  1.00,  11.49 ],
	] ],
	[ 'SER', 29, [
		[ 'N',    'N',    -1.953,   -1.306,   25.071,  1.00,  11.47 ],
		[ 'CA',   'C',    -2.997,   -2.193,   24.590,  1.00,   8.96 ],
		[ 'C',    'C',    -2.462,   -3.139,   23.520,  1.00,   6.80 ],
		[ 'O',    'O',    -1.450,   -2.819,   22.897,  1.00,   5.78 ],
		[ 'CB',   'C',    -4.133,   -1.356,   24.022,  1.00,   8.64 ],
		[ 'OG',   'O',    -4.770,   -0.698,   25.101,  1.00,   4.94 ],
	] ],
	[ 'PRO', 30, [
		[ 'N',    'N',    -3.076,   -4.286,   23.225,  1.00,   5.57 ],
		[ 'CA',   'C',    -4.273,   -4.820,   23.881,  1.00,   7.55 ],
		[ 'C',    'C',    -3.953,   -5.501,   25.237,  1.00,   7.66 ],
		[ 'O',    'O',    -2.782,   -5.540,   25.607,  1.00,   6.22 ],
		[ 'CB',   'C',    -4.809,   -5.731,   22.783,  1.00,   3.72 ],
		[ 'CG',   'C',    -3.544,   -6.410,   22.336,  1.00,   3.03 ],
		[ 'CD',   'C',    -2.606,   -5.219,   22.202,  1.00,   2.00 ],
	] ],
	[ 'VAL', 31, [
		[ 'N',    'N',    -4.919,   -6.046,   26.005,  1.00,   8.25 ],
		[ 'CA',   'C',    -4.700,   -6.743,   27.269,  1.00,   3.84 ],
		[ 'C',    'C',    -5.666,   -7.933,   27.243,  1.00,   4.86 ],
		[ 'O',    'O',    -6.559,   -8.055,   26.389,  1.00,   4.29 ],
		[ 'CB',   'C',    -5.035,   -5.876,   28.561,  1.00,   5.08 ],
		[ 'CG1',  'C',    -4.212,   -4.589,   28.654,  1.00,   2.00 ],
		[ 'CG2',  'C',    -6.500,   -5.516,   28.531,  1.00,   2.21 ],
	] ],
	[ 'ASP', 32, [
		[ 'N',    'N',    -5.522,   -8.816,   28.221,  1.00,   9.02 ],
		[ 'CA',   'C',    -6.410,   -9.950,   28.378,  1.00,  10.39 ],
		[ 'C',    'C',    -7.555,   -9.471,   29.248,  1.00,   9.34 ],
		[ 'O',    'O',    -7.301,   -8.825,   30.260,  1.00,  11.79 ],
		[ 'CB',   'C',    -5.653,  -11.099,   29.058,  1.00,  10.29 ],
		[ 'CG',   'C',    -6.494,  -12.327,   29.398,  1.00,  12.11 ],
		[ 'OD1',  'O',    -7.357,  -12.705,   28.614,  1.00,  13.91 ],
		[ 'OD2',  'O',    -6.283,  -12.923,   30.447,  1.00,  15.55 ],
	] ],
	[ 'ILE', 33, [
		[ 'N',    'N',    -8.810,   -9.670,   28.894,  1.00,  10.18 ],
		[ 'CA',   'C',    -9.889,   -9.355,   29.808,  1.00,  12.61 ],
		[ 'C',    'C',   -10.097,  -10.631,   30.646,  1.00,  14.49 ],
		[ 'O',    'O',   -10.582,  -11.660,   30.141,  1.00,  12.79 ],
		[ 'CB',   'C',   -11.218,   -8.988,   29.061,  1.00,  10.37 ],
		[ 'CG1',  'C',   -11.207,   -7.569,   28.471,  1.00,  13.21 ],
		[ 'CG2',  'C',   -12.344,   -8.956,   30.070,  1.00,   8.33 ],
		[ 'CD1',  'C',   -10.361,   -7.329,   27.201,  1.00,  11.78 ],
	] ],
	[ 'ASP', 34, [
		[ 'N',    'N',    -9.672,  -10.646,   31.919,  1.00,  17.43 ],
		[ 'CA',   'C',    -9.996,  -11.764,   32.806,  1.00,  18.67 ],
		[ 'C',    'C',   -11.372,  -11.480,   33.416,  1.00,  19.66 ],
		[ 'O',    'O',   -11.575,  -10.584,   34.249,  1.00,  19.01 ],
		[ 'CB',   'C',    -8.971,  -11.915,   33.930,  1.00,  23.16 ],
		[ 'CG',   'C',    -9.308,  -13.049,   34.909,  1.00,  25.79 ],
		[ 'OD1',  'O',    -9.715,  -14.160,   34.528,  1.00,  28.60 ],
		[ 'OD2',  'O',    -9.160,  -12.794,   36.087,  1.00,  30.58 ],
	] ],
	[ 'THR', 35, [
		[ 'N',    'N',   -12.333,  -12.298,   33.028,  1.00,  18.43 ],
		[ 'CA',   'C',   -13.701,  -12.046,   33.381,  1.00,  22.62 ],
		[ 'C',    'C',   -13.956,  -12.109,   34.861,  1.00,  24.44 ],
		[ 'O',    'O',   -14.749,  -11.348,   35.396,  1.00,  32.28 ],
		[ 'CB',   'C',   -14.580,  -13.044,   32.614,  1.00,  23.04 ],
		[ 'OG1',  'O',   -14.178,  -14.378,   32.953,  1.00,  21.47 ],
		[ 'CG2',  'C',   -14.485,  -12.765,   31.108,  1.00,  22.29 ],
	] ],
	[ 'HIS', 36, [
		[ 'N',    'N',   -13.239,  -12.983,   35.551,  1.00,  28.79 ],
		[ 'CA',   'C',   -13.424,  -13.164,   36.981,  1.00,  26.47 ],
		[ 'C',    'C',   -12.837,  -12.042,   37.801,  1.00,  26.90 ],
		[ 'O',    'O',   -13.249,  -11.905,   38.942,  1.00,  31.19 ],
		[ 'CB',   'C',   -12.807,  -14.483,   37.393,  1.00,  24.14 ],
		[ 'CG',   'C',   -13.589,  -15.640,   36.797,  1.00,  26.35 ],
		[ 'ND1',  'N',   -14.872,  -15.927,   37.023,  1.00,  26.71 ],
		[ 'CD2',  'C',   -13.101,  -16.545,   35.874,  1.00,  26.61 ],
		[ 'CE1',  'C',   -15.188,  -16.965,   36.275,  1.00,  28.08 ],
		[ 'NE2',  'N',   -14.119,  -17.322,   35.592,  1.00,  28.35 ],
	] ],
	[ 'THR', 37, [
		[ 'N',    'N',   -11.904,  -11.220,   37.347,  1.00,  26.10 ],
		[ 'CA',   'C',   -11.443,  -10.180,   38.231,  1.00,  25.86 ],
		[ 'C',    'C',   -11.847,   -8.806,   37.742,  1.00,  23.68 ],
		[ 'O',    'O',   -11.373,   -7.792,   38.271,  1.00,  26.34 ],
		[ 'CB',   'C',    -9.899,  -10.285,   38.393,  1.00,  27.18 ],
		[ 'OG1',  'O',    -9.278,  -10.207,   37.114,  1.00,  26.39 ],
		[ 'CG2',  'C',    -9.526,  -11.588,   39.096,  1.00,  26.41 ],
	] ],
	[ 'ALA', 38, [
		[ 'N',    'N',   -12.692,   -8.716,   36.724,  1.00,  23.18 ],
		[ 'CA',   'C',   -13.076,   -7.415,   36.203,  1.00,  20.38 ],
		[ 'C',    'C',   -14.146,   -6.896,   37.130,  1.00,  18.52 ],
		[ 'O',    'O',   -15.052,   -7.609,   37.546,  1.00,  17.34 ],
		[ 'CB',   'C',   -13.655,   -7.531,   34.806,  1.00,  21.62 ],
	] ],
	[ 'LYS', 39, [
		[ 'N',    'N',   -14.099,   -5.633,   37.455,  1.00,  18.58 ],
		[ 'CA',   'C',   -15.009,   -5.108,   38.430,  1.00,  21.35 ],
		[ 'C',    'C',   -16.302,   -4.669,   37.788,  1.00,  23.40 ],
		[ 'O',    'O',   -16.278,   -3.785,   36.928,  1.00,  22.41 ],
		[ 'CB',   'C',   -14.303,   -3.961,   39.104,  1.00,  23.23 ],
		[ 'CG',   'C',   -15.089,   -3.231,   40.152,  1.00,  29.50 ],
		[ 'CD',   'C',   -15.262,   -4.062,   41.408,  1.00,  35.46 ],
		[ 'CE',   'C',   -15.902,   -3.182,   42.477,  1.00,  37.51 ],
		[ 'NZ',   'N',   -15.032,   -2.069,   42.833,  1.00,  43.00 ],
	] ],
	[ 'TYR', 40, [
		[ 'N',    'N',   -17.445,   -5.240,   38.157,  1.00,  24.76 ],
		[ 'CA',   'C',   -18.711,   -4.713,   37.677,  1.00,  28.33 ],
		[ 'C',    'C',   -18.904,   -3.319,   38.273,  1.00,  30.75 ],
		[ 'O',    'O',   -18.877,   -3.156,   39.501,  1.00,  34.63 ],
		[ 'CB',   'C',   -19.866,   -5.648,   38.095,  1.00,  31.12 ],
		[ 'CG',   'C',   -21.229,   -4.994,   37.936,  1.00,  34.15 ],
		[ 'CD1',  'C',   -21.694,   -4.585,   36.683,  1.00,  34.89 ],
		[ 'CD2',  'C',   -21.967,   -4.708,   39.082,  1.00,  36.94 ],
		[ 'CE1',  'C',   -22.884,   -3.877,   36.577,  1.00,  35.53 ],
		[ 'CE2',  'C',   -23.159,   -3.994,   38.979,  1.00,  40.03 ],
		[ 'CZ',   'C',   -23.605,   -3.580,   37.728,  1.00,  37.87 ],
		[ 'OH',   'O',   -24.756,   -2.824,   37.661,  1.00,  42.12 ],
	] ],
	[ 'ASP', 41, [
		[ 'N',    'N',   -19.108,   -2.304,   37.441,  1.00,  31.55 ],
		[ 'CA',   'C',   -19.278,   -0.964,   37.931,  1.00,  33.21 ],
		[ 'C',    'C',   -20.718,   -0.595,   37.607,  1.00,  35.68 ],
		[ 'O',    'O',   -21.095,   -0.621,   36.434,  1.00,  39.64 ],
		[ 'CB',   'C',   -18.270,   -0.054,   37.229,  1.00,  31.82 ],
		[ 'CG',   'C',   -18.123,    1.355,   37.812,  1.00,  36.42 ],
		[ 'OD1',  'O',   -19.049,    1.858,   38.443,  1.00,  37.61 ],
		[ 'OD2',  'O',   -17.076,    1.980,   37.630,  1.00,  38.27 ],
	] ],
	[ 'PRO', 42, [
		[ 'N',    'N',   -21.589,   -0.270,   38.583,  1.00,  37.72 ],
		[ 'CA',   'C',   -22.974,    0.152,   38.351,  1.00,  37.04 ],
		[ 'C',    'C',   -23.114,    1.654,   38.115,  1.00,  34.79 ],
		[ 'O',    'O',   -24.213,    2.171,   37.982,  1.00,  37.03 ],
		[ 'CB',   'C',   -23.708,   -0.336,   39.581,  1.00,  35.91 ],
		[ 'CG',   'C',   -22.689,   -0.047,   40.648,  1.00,  37.72 ],
		[ 'CD',   'C',   -21.370,   -0.484,   40.014,  1.00,  37.06 ],
	] ],
	[ 'SER', 43, [
		[ 'N',    'N',   -22.040,    2.427,   38.152,  1.00,  33.64 ],
		[ 'CA',   'C',   -22.114,    3.839,   37.817,  1.00,  32.16 ],
		[ 'C',    'C',   -21.893,    4.037,   36.307,  1.00,  29.84 ],
		[ 'O',    'O',   -21.892,    5.160,   35.795,  1.00,  28.48 ],
		[ 'CB',   'C',   -21.047,    4.568,   38.612,  1.00,  31.61 ],
		[ 'OG',   'O',   -20.807,    3.929,   39.870,  1.00,  40.10 ],
	] ],
	[ 'LEU', 44, [
		[ 'N',    'N',   -21.665,    2.944,   35.573,  1.00,  26.70 ],
		[ 'CA',   'C',   -21.368,    3.004,   34.152,  1.00,  25.83 ],
		[ 'C',    'C',   -22.688,    3.210,   33.411,  1.00,  25.12 ],
		[ 'O',    'O',   -23.648,    2.492,   33.712,  1.00,  26.66 ],
		[ 'CB',   'C',   -20.654,    1.674,   33.775,  1.00,  20.33 ],
		[ 'CG',   'C',   -19.157,    1.641,   33.370,  1.00,  15.58 ],
		[ 'CD1',  'C',   -18.357,    2.583,   34.190,  1.00,  16.59 ],
		[ 'CD2',  'C',   -18.595,    0.242,   33.578,  1.00,  12.12 ],
	] ],
	[ 'LYS', 45, [
		[ 'N',    'N',   -22.788,    4.220,   32.534,  1.00,  23.96 ],
		[ 'CA',   'C',   -23.978,    4.436,   31.712,  1.00,  21.86 ],
		[ 'C',    'C',   -23.968,    3.508,   30.483,  1.00,  23.26 ],
		[ 'O',    'O',   -22.926,    2.942,   30.134,  1.00,  20.36 ],
		[ 'CB',   'C',   -24.040,    5.866,   31.227,  1.00,  22.96 ],
		[ 'CG',   'C',   -24.273,    6.936,   32.287,  1.00,  27.73 ],
		[ 'CD',   'C',   -22.963,    7.290,   32.987,  1.00,  32.33 ],
		[ 'CE',   'C',   -23.171,    8.268,   34.139,  1.00,  34.82 ],
		[ 'NZ',   'N',   -21.909,    8.809,   34.632,  1.00,  31.45 ],
	] ],
	[ 'PRO', 46, [
		[ 'N',    'N',   -25.073,    3.249,   29.775,  1.00,  24.49 ],
		[ 'CA',   'C',   -25.061,    2.582,   28.471,  1.00,  25.08 ],
		[ 'C',    'C',   -24.337,    3.394,   27.388,  1.00,  23.19 ],
		[ 'O',    'O',   -24.157,    4.615,   27.452,  1.00,  21.52 ],
		[ 'CB',   'C',   -26.534,    2.354,   28.129,  1.00,  24.89 ],
		[ 'CG',   'C',   -27.250,    2.396,   29.461,  1.00,  25.49 ],
		[ 'CD',   'C',   -26.454,    3.477,   30.209,  1.00,  28.39 ],
	] ],
	[ 'LEU', 47, [
		[ 'N',    'N',   -23.869,    2.669,   26.392,  1.00,  20.76 ],
		[ 'CA',   'C',   -23.270,    3.273,   25.230,  1.00,  19.28 ],
		[ 'C',    'C',   -24.389,    3.866,   24.434,  1.00,  17.04 ],
		[ 'O',    'O',   -25.485,    3.297,   24.467,  1.00,  17.44 ],
		[ 'CB',   'C',   -22.607,    2.267,   24.319,  1.00,  18.70 ],
		[ 'CG',   'C',   -21.298,    1.715,   24.758,  1.00,  18.86 ],
		[ 'CD1',  'C',   -20.855,    0.649,   23.761,  1.00,  20.33 ],
		[ 'CD2',  'C',   -20.316,    2.864,   24.916,  1.00,  18.28 ],
	] ],
	[ 'SER', 48, [
		[ 'N',    'N',   -24.080,    4.947,   23.729,  1.00,  14.18 ],
		[ 'CA',   'C',   -24.993,    5.512,   22.772,  1.00,  18.24 ],
		[ 'C',    'C',   -24.147,    5.677,   21.533,  1.00,  17.73 ],
		[ 'O',    'O',   -23.122,    6.357,   21.452,  1.00,  17.23 ],
		[ 'CB',   'C',   -25.551,    6.860,   23.214,  1.00,  17.09 ],
		[ 'OG',   'O',   -24.626,    7.579,   24.006,  1.00,  30.98 ],
	] ],
	[ 'VAL', 49, [
		[ 'N',    'N',   -24.569,    4.869,   20.586,  1.00,  20.08 ],
		[ 'CA',   'C',   -23.953,    4.797,   19.288,  1.00,  21.54 ],
		[ 'C',    'C',   -24.977,    5.470,   18.372,  1.00,  21.85 ],
		[ 'O',    'O',   -26.121,    5.020,   18.303,  1.00,  20.74 ],
		[ 'CB',   'C',   -23.741,    3.311,   18.957,  1.00,  21.94 ],
		[ 'CG1',  'C',   -23.044,    3.219,   17.635,  1.00,  22.35 ],
		[ 'CG2',  'C',   -22.872,    2.616,   19.994,  1.00,  22.90 ],
	] ],
	[ 'SER', 50, [
		[ 'N',    'N',   -24.678,    6.590,   17.720,  1.00,  23.21 ],
		[ 'CA',   'C',   -25.623,    7.175,   16.781,  1.00,  21.76 ],
		[ 'C',    'C',   -24.956,    7.062,   15.432,  1.00,  20.16 ],
		[ 'O',    'O',   -24.195,    7.929,   15.018,  1.00,  19.01 ],
		[ 'CB',   'C',   -25.869,    8.625,   17.127,  1.00,  23.34 ],
		[ 'OG',   'O',   -26.300,    8.673,   18.473,  1.00,  28.98 ],
	] ],
	[ 'TYR', 51, [
		[ 'N',    'N',   -25.142,    5.941,   14.756,  1.00,  22.43 ],
		[ 'CA',   'C',   -24.520,    5.758,   13.451,  1.00,  24.77 ],
		[ 'C',    'C',   -25.458,    5.922,   12.260,  1.00,  25.70 ],
		[ 'O',    'O',   -25.093,    5.625,   11.122,  1.00,  27.42 ],
		[ 'CB',   'C',   -23.862,    4.369,   13.420,  1.00,  21.91 ],
		[ 'CG',   'C',   -22.552,    4.201,   14.184,  1.00,  21.53 ],
		[ 'CD1',  'C',   -21.952,    5.279,   14.856,  1.00,  22.86 ],
		[ 'CD2',  'C',   -21.952,    2.938,   14.213,  1.00,  18.44 ],
		[ 'CE1',  'C',   -20.759,    5.110,   15.553,  1.00,  21.20 ],
		[ 'CE2',  'C',   -20.762,    2.757,   14.916,  1.00,  21.12 ],
		[ 'CZ',   'C',   -20.169,    3.847,   15.583,  1.00,  22.50 ],
		[ 'OH',   'O',   -18.968,    3.678,   16.281,  1.00,  23.88 ],
	] ],
	[ 'ASP', 52, [
		[ 'N',    'N',   -26.680,    6.415,   12.485,  1.00,  28.94 ],
		[ 'CA',   'C',   -27.665,    6.564,   11.413,  1.00,  30.42 ],
		[ 'C',    'C',   -27.239,    7.505,   10.291,  1.00,  29.31 ],
		[ 'O',    'O',   -27.458,    7.190,    9.126,  1.00,  28.97 ],
		[ 'CB',   'C',   -29.008,    7.047,   11.987,  1.00,  34.57 ],
		[ 'CG',   'C',   -29.032,    8.482,   12.506,  1.00,  38.93 ],
		[ 'OD1',  'O',   -28.454,    8.764,   13.559,  1.00,  45.06 ],
		[ 'OD2',  'O',   -29.632,    9.320,   11.838,  1.00,  44.23 ],
	] ],
	[ 'GLN', 53, [
		[ 'N',    'N',   -26.596,    8.626,   10.614,  1.00,  25.10 ],
		[ 'CA',   'C',   -26.190,    9.569,    9.605,  1.00,  24.77 ],
		[ 'C',    'C',   -24.707,    9.513,    9.283,  1.00,  21.20 ],
		[ 'O',    'O',   -24.114,   10.506,    8.862,  1.00,  20.23 ],
		[ 'CB',   'C',   -26.623,   10.963,   10.065,  1.00,  31.21 ],
		[ 'CG',   'C',   -26.431,   11.213,   11.551,  1.00,  44.84 ],
		[ 'CD',   'C',   -26.867,   12.577,   12.060,  1.00,  52.21 ],
		[ 'OE1',  'O',   -27.953,   13.064,   11.732,  1.00,  54.57 ],
		[ 'NE2',  'N',   -26.052,   13.222,   12.893,  1.00,  53.94 ],
	] ],
	[ 'ALA', 54, [
		[ 'N',    'N',   -24.052,    8.362,    9.423,  1.00,  19.59 ],
		[ 'CA',   'C',   -22.627,    8.262,    9.100,  1.00,  22.21 ],
		[ 'C',    'C',   -22.337,    8.307,    7.593,  1.00,  21.45 ],
		[ 'O',    'O',   -23.064,    7.743,    6.774,  1.00,  21.70 ],
		[ 'CB',   'C',   -22.031,    6.969,    9.630,  1.00,  18.96 ],
	] ],
	[ 'THR', 55, [
		[ 'N',    'N',   -21.286,    9.022,    7.192,  1.00,  21.32 ],
		[ 'CA',   'C',   -20.930,    9.143,    5.795,  1.00,  17.74 ],
		[ 'C',    'C',   -19.585,    8.501,    5.480,  1.00,  16.62 ],
		[ 'O',    'O',   -18.546,    9.098,    5.795,  1.00,  11.41 ],
		[ 'CB',   'C',   -20.952,   10.640,    5.470,  1.00,  20.84 ],
		[ 'OG1',  'O',   -22.279,   11.088,    5.752,  1.00,  24.44 ],
		[ 'CG2',  'C',   -20.575,   10.942,    4.021,  1.00,  22.48 ],
	] ],
	[ 'SER', 56, [
		[ 'N',    'N',   -19.559,    7.276,    4.932,  1.00,  14.57 ],
		[ 'CA',   'C',   -18.298,    6.680,    4.540,  1.00,  18.61 ],
		[ 'C',    'C',   -17.924,    7.280,    3.202,  1.00,  20.27 ],
		[ 'O',    'O',   -18.770,    7.703,    2.389,  1.00,  22.10 ],
		[ 'CB',   'C',   -18.410,    5.171,    4.412,  1.00,  13.25 ],
		[ 'OG',   'O',   -19.431,    4.736,    3.532,  1.00,  19.48 ],
	] ],
	[ 'LEU', 57, [
		[ 'N',    'N',   -16.618,    7.348,    3.035,  1.00,  19.49 ],
		[ 'CA',   'C',   -16.081,    7.921,    1.838,  1.00,  15.54 ],
		[ 'C',    'C',   -15.251,    6.938,    1.069,  1.00,  15.08 ],
		[ 'O',    'O',   -15.485,    6.802,   -0.126,  1.00,  16.53 ],
		[ 'CB',   'C',   -15.204,    9.096,    2.161,  1.00,  14.41 ],
		[ 'CG',   'C',   -15.857,   10.256,    2.874,  1.00,  18.29 ],
		[ 'CD1',  'C',   -14.766,   11.140,    3.422,  1.00,  18.41 ],
		[ 'CD2',  'C',   -16.831,   10.948,    1.941,  1.00,  13.90 ],
	] ],
	[ 'ARG', 58, [
		[ 'N',    'N',   -14.353,    6.189,    1.718,  1.00,  12.47 ],
		[ 'CA',   'C',   -13.280,    5.519,    1.012,  1.00,   9.99 ],
		[ 'C',    'C',   -12.722,    4.304,    1.725,  1.00,  10.83 ],
		[ 'O',    'O',   -12.715,    4.304,    2.954,  1.00,   8.62 ],
		[ 'CB',   'C',   -12.244,    6.588,    0.827,  1.00,  10.49 ],
		[ 'CG',   'C',   -10.844,    6.185,    0.503,  1.00,  14.59 ],
		[ 'CD',   'C',    -9.975,    7.134,    1.295,  1.00,  12.65 ],
		[ 'NE',   'N',    -8.953,    7.605,    0.405,  1.00,  13.99 ],
		[ 'CZ',   'C',    -7.741,    7.982,    0.768,  1.00,  12.60 ],
		[ 'NH1',  'N',    -7.289,    8.004,    2.025,  1.00,  15.79 ],
		[ 'NH2',  'N',    -6.939,    8.217,   -0.248,  1.00,  17.59 ],
	] ],
	[ 'ILE', 59, [
		[ 'N',    'N',   -12.291,    3.260,    1.021,  1.00,   8.27 ],
		[ 'CA',   'C',   -11.602,    2.165,    1.671,  1.00,   9.17 ],
		[ 'C',    'C',   -10.176,    2.234,    1.140,  1.00,  11.49 ],
		[ 'O',    'O',    -9.943,    2.657,    0.001,  1.00,  13.74 ],
		[ 'CB',   'C',   -12.279,    0.818,    1.348,  1.00,   8.19 ],
		[ 'CG1',  'C',   -11.553,   -0.254,    2.168,  1.00,   2.00 ],
		[ 'CG2',  'C',   -12.328,    0.557,   -0.154,  1.00,   2.00 ],
		[ 'CD1',  'C',   -12.372,   -1.549,    2.216,  1.00,   4.60 ],
	] ],
	[ 'LEU', 60, [
		[ 'N',    'N',    -9.197,    1.858,    1.948,  1.00,  13.54 ],
		[ 'CA',   'C',    -7.790,    2.046,    1.617,  1.00,  15.37 ],
		[ 'C',    'C',    -6.959,    0.903,    2.186,  1.00,  13.46 ],
		[ 'O',    'O',    -7.179,    0.489,    3.325,  1.00,  12.87 ],
		[ 'CB',   'C',    -7.304,    3.376,    2.210,  1.00,  15.32 ],
		[ 'CG',   'C',    -5.820,    3.694,    2.140,  1.00,  22.87 ],
		[ 'CD1',  'C',    -5.465,    4.279,    0.783,  1.00,  20.45 ],
		[ 'CD2',  'C',    -5.481,    4.663,    3.251,  1.00,  17.67 ],
	] ],
	[ 'ASN', 61, [
		[ 'N',    'N',    -6.034,    0.359,    1.412,  1.00,  11.19 ],
		[ 'CA',   'C',    -5.094,   -0.587,    1.948,  1.00,  10.07 ],
		[ 'C',    'C',    -3.908,    0.291,    2.286,  1.00,   9.63 ],
		[ 'O',    'O',    -3.312,    0.925,    1.404,  1.00,   8.87 ],
		[ 'CB',   'C',    -4.688,   -1.605,    0.921,  1.00,   7.26 ],
		[ 'CG',   'C',    -3.685,   -2.605,    1.445,  1.00,   9.46 ],
		[ 'OD1',  'O',    -2.859,   -2.341,    2.330,  1.00,  10.96 ],
		[ 'ND2',  'N',    -3.717,   -3.804,    0.900,  1.00,   6.76 ],
	] ],
	[ 'ASN', 62, [
		[ 'N',    'N',    -3.531,    0.353,    3.563,  1.00,   8.75 ],
		[ 'CA',   'C',    -2.429,    1.216,    3.976,  1.00,   8.07 ],
		[ 'C',    'C',    -1.116,    0.497,    4.270,  1.00,   8.74 ],
		[ 'O',    'O',    -0.204,    1.096,    4.836,  1.00,   6.81 ],
		[ 'CB',   'C',    -2.845,    2.015,    5.204,  1.00,   8.11 ],
		[ 'CG',   'C',    -3.112,    1.194,    6.460,  1.00,   7.99 ],
		[ 'OD1',  'O',    -2.760,    0.024,    6.607,  1.00,   5.57 ],
		[ 'ND2',  'N',    -3.784,    1.771,    7.428,  1.00,  13.33 ],
	] ],
);
my @fold;
$serial = 0;
for my $r (@fold_res) {
	my ($resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @fold, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			altloc => '', resname => $resname, chain => 'A', resseq => $resseq, icode => '',
			x => $a->[2], y => $a->[3], z => $a->[4], occ => $a->[5], b => $a->[6],
		);
	}
}
push @fold, 'END';

# --- sheet.pdb -- one contiguous run with all eight DSSP letters in it -------
#
# Residues 118 to 177 of chain A of 1H1V (gelsolin G4-G6 / actin complex,
# 23-JUL-02), lifted whole from
# /home/con/ui/pepPriML/PPB/PDB/PDBbind.v2020/1h1v.ent.pdb with their
# coordinates as deposited.  No alternate conformers and no insertion codes in
# that range, so the file is 459 ATOM records and nothing else.
#
# fold.pdb has helices, turns and bends in it and no sheet at all, which left
# the beta half of the secondary structure -- the bridges, the ladders and the
# bulges between them, which is most of the code and all of the hard part --
# with nothing to be compared against mdtraj on.  This range was chosen by
# running mdtraj's compute_dssp() over every sixty-residue window of every
# chain of a spread of PDBbind and keeping the ones whose window, extracted and
# read on its own, still had every letter.  Taken out of its structure it comes
# back
#
#   _HHHIIIIIT__S______HHHHHHHHHT_SSEEEEEE_SS_EEEEEEETTEE_GGG_B_
#
# which is H, I, T, S, coil, E, G and B: the whole dictionary, including the pi
# helix, which is the one letter a structure has to be looked for to find.  The
# two long strands are each other's ladder partner, so the sheet is inside the
# fixture rather than pointing at residues that were left behind.
my @sheet_res = (
	[ 'LYS', 118, [
		[ 'N',    'N',      20.116,   40.144,   29.735,  1.00,  22.70 ],
		[ 'CA',   'C',      21.187,   40.914,   30.321,  1.00,  23.93 ],
		[ 'C',    'C',      21.964,   40.020,   31.262,  1.00,  23.96 ],
		[ 'O',    'O',      23.188,   39.960,   31.226,  1.00,  24.10 ],
		[ 'CB',   'C',      20.636,   42.107,   31.085,  1.00,  24.55 ],
		[ 'CG',   'C',      21.686,   43.158,   31.432,  1.00,  27.62 ],
		[ 'CD',   'C',      22.257,   43.849,   30.162,  1.00,  31.45 ],
		[ 'CE',   'C',      23.169,   45.048,   30.503,  1.00,  33.57 ],
		[ 'NZ',   'N',      23.538,   45.849,   29.290,  1.00,  34.09 ],
	] ],
	[ 'MET', 119, [
		[ 'N',    'N',      21.219,   39.309,   32.093,  1.00,  24.29 ],
		[ 'CA',   'C',      21.771,   38.423,   33.100,  1.00,  24.30 ],
		[ 'C',    'C',      22.676,   37.405,   32.448,  1.00,  23.97 ],
		[ 'O',    'O',      23.796,   37.183,   32.889,  1.00,  23.62 ],
		[ 'CB',   'C',      20.625,   37.733,   33.842,  1.00,  24.51 ],
		[ 'CG',   'C',      21.020,   36.990,   35.106,  1.00,  25.61 ],
		[ 'SD',   'S',      19.583,   36.293,   35.951,  1.00,  28.72 ],
		[ 'CE',   'C',      18.283,   37.670,   35.707,  1.00,  28.06 ],
	] ],
	[ 'THR', 120, [
		[ 'N',    'N',      22.192,   36.800,   31.380,  1.00,  23.90 ],
		[ 'CA',   'C',      22.954,   35.783,   30.685,  1.00,  24.07 ],
		[ 'C',    'C',      24.157,   36.422,   29.993,  1.00,  24.06 ],
		[ 'O',    'O',      25.274,   35.903,   30.025,  1.00,  23.81 ],
		[ 'CB',   'C',      22.064,   35.113,   29.675,  1.00,  23.99 ],
		[ 'OG1',  'O',      20.712,   35.487,   29.937,  1.00,  23.82 ],
		[ 'CG2',  'C',      22.037,   33.651,   29.899,  1.00,  25.19 ],
	] ],
	[ 'GLN', 121, [
		[ 'N',    'N',      23.932,   37.567,   29.378,  1.00,  23.99 ],
		[ 'CA',   'C',      25.026,   38.263,   28.750,  1.00,  24.21 ],
		[ 'C',    'C',      26.125,   38.600,   29.760,  1.00,  23.89 ],
		[ 'O',    'O',      27.300,   38.318,   29.537,  1.00,  23.81 ],
		[ 'CB',   'C',      24.538,   39.539,   28.094,  1.00,  24.52 ],
		[ 'CG',   'C',      25.670,   40.474,   27.721,  1.00,  25.52 ],
		[ 'CD',   'C',      25.234,   41.579,   26.787,  1.00,  26.33 ],
		[ 'OE1',  'O',      24.930,   41.320,   25.632,  1.00,  27.56 ],
		[ 'NE2',  'N',      25.207,   42.810,   27.281,  1.00,  26.94 ],
	] ],
	[ 'ILE', 122, [
		[ 'N',    'N',      25.754,   39.219,   30.869,  1.00,  23.48 ],
		[ 'CA',   'C',      26.756,   39.566,   31.864,  1.00,  23.01 ],
		[ 'C',    'C',      27.553,   38.328,   32.292,  1.00,  22.88 ],
		[ 'O',    'O',      28.776,   38.350,   32.328,  1.00,  23.32 ],
		[ 'CB',   'C',      26.117,   40.235,   33.073,  1.00,  22.52 ],
		[ 'CG1',  'C',      25.613,   41.612,   32.674,  1.00,  23.14 ],
		[ 'CG2',  'C',      27.118,   40.381,   34.171,  1.00,  22.02 ],
		[ 'CD1',  'C',      25.315,   42.520,   33.833,  1.00,  23.78 ],
	] ],
	[ 'MET', 123, [
		[ 'N',    'N',      26.869,   37.235,   32.582,  1.00,  22.21 ],
		[ 'CA',   'C',      27.554,   36.070,   33.099,  1.00,  21.50 ],
		[ 'C',    'C',      28.533,   35.525,   32.105,  1.00,  21.04 ],
		[ 'O',    'O',      29.540,   34.968,   32.503,  1.00,  20.97 ],
		[ 'CB',   'C',      26.555,   34.987,   33.495,  1.00,  21.63 ],
		[ 'CG',   'C',      25.864,   35.266,   34.812,  1.00,  20.67 ],
		[ 'SD',   'S',      26.882,   34.923,   36.182,  1.00,  19.20 ],
		[ 'CE',   'C',      26.643,   36.368,   37.103,  1.00,  19.46 ],
	] ],
	[ 'PHE', 124, [
		[ 'N',    'N',      28.269,   35.698,   30.814,  1.00,  20.69 ],
		[ 'CA',   'C',      29.179,   35.156,   29.788,  1.00,  20.27 ],
		[ 'C',    'C',      30.270,   36.144,   29.358,  1.00,  20.15 ],
		[ 'O',    'O',      31.441,   35.819,   29.378,  1.00,  19.44 ],
		[ 'CB',   'C',      28.406,   34.671,   28.560,  1.00,  19.97 ],
		[ 'CG',   'C',      27.780,   33.313,   28.730,  1.00,  18.82 ],
		[ 'CD1',  'C',      28.545,   32.220,   29.061,  1.00,  18.73 ],
		[ 'CD2',  'C',      26.434,   33.135,   28.552,  1.00,  18.18 ],
		[ 'CE1',  'C',      27.976,   30.987,   29.207,  1.00,  18.38 ],
		[ 'CE2',  'C',      25.861,   31.906,   28.711,  1.00,  18.10 ],
		[ 'CZ',   'C',      26.628,   30.834,   29.035,  1.00,  18.47 ],
	] ],
	[ 'GLU', 125, [
		[ 'N',    'N',      29.876,   37.360,   28.999,  1.00,  20.63 ],
		[ 'CA',   'C',      30.823,   38.371,   28.528,  1.00,  20.73 ],
		[ 'C',    'C',      31.603,   39.032,   29.648,  1.00,  20.77 ],
		[ 'O',    'O',      32.722,   39.467,   29.421,  1.00,  20.89 ],
		[ 'CB',   'C',      30.117,   39.448,   27.709,  1.00,  20.57 ],
		[ 'CG',   'C',      29.174,   38.901,   26.660,  1.00,  21.14 ],
		[ 'CD',   'C',      28.587,   39.982,   25.772,  1.00,  22.96 ],
		[ 'OE1',  'O',      28.705,   41.186,   26.119,  1.00,  23.30 ],
		[ 'OE2',  'O',      28.000,   39.628,   24.718,  1.00,  23.77 ],
	] ],
	[ 'THR', 126, [
		[ 'N',    'N',      31.046,   39.119,   30.850,  1.00,  20.99 ],
		[ 'CA',   'C',      31.782,   39.780,   31.936,  1.00,  21.52 ],
		[ 'C',    'C',      32.511,   38.858,   32.909,  1.00,  21.53 ],
		[ 'O',    'O',      33.492,   39.261,   33.496,  1.00,  22.01 ],
		[ 'CB',   'C',      30.873,   40.734,   32.735,  1.00,  21.62 ],
		[ 'OG1',  'O',      30.285,   41.704,   31.856,  1.00,  22.18 ],
		[ 'CG2',  'C',      31.689,   41.578,   33.707,  1.00,  21.49 ],
	] ],
	[ 'PHE', 127, [
		[ 'N',    'N',      32.029,   37.644,   33.111,  1.00,  21.62 ],
		[ 'CA',   'C',      32.680,   36.735,   34.035,  1.00,  21.97 ],
		[ 'C',    'C',      33.261,   35.499,   33.303,  1.00,  22.20 ],
		[ 'O',    'O',      33.943,   34.664,   33.897,  1.00,  22.55 ],
		[ 'CB',   'C',      31.698,   36.331,   35.139,  1.00,  22.29 ],
		[ 'CG',   'C',      31.286,   37.468,   36.043,  1.00,  22.69 ],
		[ 'CD1',  'C',      30.245,   38.297,   35.706,  1.00,  24.44 ],
		[ 'CD2',  'C',      31.931,   37.692,   37.233,  1.00,  23.46 ],
		[ 'CE1',  'C',      29.873,   39.341,   36.540,  1.00,  24.98 ],
		[ 'CE2',  'C',      31.562,   38.735,   38.069,  1.00,  23.75 ],
		[ 'CZ',   'C',      30.536,   39.553,   37.717,  1.00,  24.28 ],
	] ],
	[ 'ASN', 128, [
		[ 'N',    'N',      33.011,   35.400,   32.005,  1.00,  22.05 ],
		[ 'CA',   'C',      33.520,   34.307,   31.191,  1.00,  21.95 ],
		[ 'C',    'C',      33.268,   32.950,   31.791,  1.00,  21.05 ],
		[ 'O',    'O',      34.147,   32.093,   31.788,  1.00,  21.70 ],
		[ 'CB',   'C',      35.006,   34.462,   30.904,  1.00,  22.17 ],
		[ 'CG',   'C',      35.521,   33.388,   29.953,  1.00,  24.86 ],
		[ 'OD1',  'O',      36.733,   33.188,   29.835,  1.00,  29.22 ],
		[ 'ND2',  'N',      34.598,   32.672,   29.280,  1.00,  25.62 ],
	] ],
	[ 'VAL', 129, [
		[ 'N',    'N',      32.055,   32.741,   32.275,  1.00,  19.89 ],
		[ 'CA',   'C',      31.678,   31.462,   32.865,  1.00,  18.84 ],
		[ 'C',    'C',      31.599,   30.362,   31.824,  1.00,  17.58 ],
		[ 'O',    'O',      31.323,   30.617,   30.660,  1.00,  17.59 ],
		[ 'CB',   'C',      30.303,   31.533,   33.521,  1.00,  19.08 ],
		[ 'CG1',  'C',      30.442,   31.704,   34.989,  1.00,  19.55 ],
		[ 'CG2',  'C',      29.492,   32.656,   32.948,  1.00,  19.74 ],
	] ],
	[ 'PRO', 130, [
		[ 'N',    'N',      31.794,   29.134,   32.270,  1.00,  15.88 ],
		[ 'CA',   'C',      31.754,   27.951,   31.418,  1.00,  15.21 ],
		[ 'C',    'C',      30.339,   27.659,   30.948,  1.00,  14.83 ],
		[ 'O',    'O',      30.090,   27.312,   29.792,  1.00,  14.16 ],
		[ 'CB',   'C',      32.194,   26.829,   32.339,  1.00,  14.72 ],
		[ 'CG',   'C',      32.312,   27.395,   33.645,  1.00,  15.78 ],
		[ 'CD',   'C',      32.037,   28.817,   33.669,  1.00,  15.82 ],
	] ],
	[ 'ALA', 131, [
		[ 'N',    'N',      29.409,   27.765,   31.883,  1.00,  14.56 ],
		[ 'CA',   'C',      28.017,   27.522,   31.581,  1.00,  14.30 ],
		[ 'C',    'C',      27.137,   28.178,   32.619,  1.00,  13.75 ],
		[ 'O',    'O',      27.591,   28.479,   33.715,  1.00,  13.36 ],
		[ 'CB',   'C',      27.768,   26.061,   31.539,  1.00,  14.30 ],
	] ],
	[ 'MET', 132, [
		[ 'N',    'N',      25.881,   28.424,   32.274,  1.00,  13.46 ],
		[ 'CA',   'C',      24.975,   29.000,   33.258,  1.00,  13.40 ],
		[ 'C',    'C',      23.538,   28.594,   33.055,  1.00,  12.25 ],
		[ 'O',    'O',      23.192,   28.006,   32.059,  1.00,  11.92 ],
		[ 'CB',   'C',      25.091,   30.517,   33.265,  1.00,  13.91 ],
		[ 'CG',   'C',      24.525,   31.212,   32.048,  1.00,  15.71 ],
		[ 'SD',   'S',      23.019,   32.089,   32.474,  1.00,  19.78 ],
		[ 'CE',   'C',      23.564,   33.040,   33.777,  1.00,  20.73 ],
	] ],
	[ 'TYR', 133, [
		[ 'N',    'N',      22.707,   28.930,   34.025,  1.00,  11.59 ],
		[ 'CA',   'C',      21.304,   28.568,   34.011,  1.00,  10.82 ],
		[ 'C',    'C',      20.549,   29.480,   34.946,  1.00,  10.14 ],
		[ 'O',    'O',      21.106,   29.990,   35.922,  1.00,   9.83 ],
		[ 'CB',   'C',      21.131,   27.117,   34.471,  1.00,  10.75 ],
		[ 'CG',   'C',      19.765,   26.560,   34.171,  1.00,  10.32 ],
		[ 'CD1',  'C',      18.684,   26.879,   34.978,  1.00,  10.78 ],
		[ 'CD2',  'C',      19.544,   25.731,   33.087,  1.00,   8.60 ],
		[ 'CE1',  'C',      17.432,   26.397,   34.713,  1.00,   9.48 ],
		[ 'CE2',  'C',      18.284,   25.249,   32.826,  1.00,   9.21 ],
		[ 'CZ',   'C',      17.236,   25.595,   33.652,  1.00,   8.18 ],
		[ 'OH',   'O',      15.976,   25.140,   33.457,  1.00,   8.93 ],
	] ],
	[ 'VAL', 134, [
		[ 'N',    'N',      19.276,   29.692,   34.653,  1.00,   9.39 ],
		[ 'CA',   'C',      18.445,   30.507,   35.523,  1.00,   9.00 ],
		[ 'C',    'C',      17.180,   29.788,   35.904,  1.00,   8.26 ],
		[ 'O',    'O',      16.462,   29.313,   35.051,  1.00,   8.67 ],
		[ 'CB',   'C',      18.062,   31.803,   34.858,  1.00,   9.03 ],
		[ 'CG1',  'C',      17.350,   32.688,   35.828,  1.00,   8.67 ],
		[ 'CG2',  'C',      19.313,   32.494,   34.347,  1.00,  10.19 ],
	] ],
	[ 'ALA', 135, [
		[ 'N',    'N',      16.907,   29.726,   37.193,  1.00,   7.54 ],
		[ 'CA',   'C',      15.700,   29.102,   37.686,  1.00,   7.65 ],
		[ 'C',    'C',      14.731,   30.113,   38.293,  1.00,   8.16 ],
		[ 'O',    'O',      15.136,   31.186,   38.734,  1.00,   7.68 ],
		[ 'CB',   'C',      16.062,   28.082,   38.720,  1.00,   7.74 ],
	] ],
	[ 'ILE', 136, [
		[ 'N',    'N',      13.453,   29.729,   38.350,  1.00,   8.66 ],
		[ 'CA',   'C',      12.414,   30.528,   38.984,  1.00,   8.91 ],
		[ 'C',    'C',      12.412,   30.221,   40.479,  1.00,   8.47 ],
		[ 'O',    'O',      12.147,   29.108,   40.904,  1.00,   7.29 ],
		[ 'CB',   'C',      11.022,   30.248,   38.370,  1.00,   9.58 ],
		[ 'CG1',  'C',      10.977,   30.639,   36.893,  1.00,  11.70 ],
		[ 'CG2',  'C',       9.945,   30.993,   39.112,  1.00,  10.57 ],
		[ 'CD1',  'C',      11.945,   29.814,   36.011,  1.00,  15.08 ],
	] ],
	[ 'GLN', 137, [
		[ 'N',    'N',      12.733,   31.232,   41.265,  1.00,   8.45 ],
		[ 'CA',   'C',      12.818,   31.073,   42.707,  1.00,   8.67 ],
		[ 'C',    'C',      11.747,   30.169,   43.303,  1.00,   8.12 ],
		[ 'O',    'O',      12.055,   29.112,   43.799,  1.00,   7.20 ],
		[ 'CB',   'C',      12.818,   32.450,   43.366,  1.00,   9.02 ],
		[ 'CG',   'C',      14.148,   33.173,   43.188,  1.00,  10.27 ],
		[ 'CD',   'C',      14.027,   34.675,   43.238,  1.00,  11.46 ],
		[ 'OE1',  'O',      13.218,   35.212,   44.010,  1.00,  13.22 ],
		[ 'NE2',  'N',      14.840,   35.366,   42.430,  1.00,   8.78 ],
	] ],
	[ 'ALA', 138, [
		[ 'N',    'N',      10.492,   30.570,   43.233,  1.00,   8.22 ],
		[ 'CA',   'C',       9.407,   29.811,   43.866,  1.00,   8.41 ],
		[ 'C',    'C',       9.396,   28.365,   43.473,  1.00,   8.23 ],
		[ 'O',    'O',       9.094,   27.490,   44.273,  1.00,   8.64 ],
		[ 'CB',   'C',       8.081,   30.407,   43.522,  1.00,   8.67 ],
	] ],
	[ 'VAL', 139, [
		[ 'N',    'N',       9.685,   28.105,   42.217,  1.00,   7.76 ],
		[ 'CA',   'C',       9.688,   26.747,   41.775,  1.00,   7.01 ],
		[ 'C',    'C',      10.761,   25.982,   42.556,  1.00,   6.90 ],
		[ 'O',    'O',      10.534,   24.864,   42.991,  1.00,   7.69 ],
		[ 'CB',   'C',       9.962,   26.679,   40.303,  1.00,   7.23 ],
		[ 'CG1',  'C',       9.969,   25.262,   39.842,  1.00,   6.99 ],
		[ 'CG2',  'C',       8.928,   27.468,   39.531,  1.00,   6.63 ],
	] ],
	[ 'LEU', 140, [
		[ 'N',    'N',      11.931,   26.572,   42.744,  1.00,   6.60 ],
		[ 'CA',   'C',      12.974,   25.894,   43.494,  1.00,   5.72 ],
		[ 'C',    'C',      12.524,   25.497,   44.891,  1.00,   5.58 ],
		[ 'O',    'O',      12.856,   24.418,   45.350,  1.00,   5.23 ],
		[ 'CB',   'C',      14.212,   26.774,   43.628,  1.00,   5.39 ],
		[ 'CG',   'C',      15.008,   26.925,   42.353,  1.00,   2.22 ],
		[ 'CD1',  'C',      16.222,   27.783,   42.567,  1.00,   5.49 ],
		[ 'CD2',  'C',      15.447,   25.582,   41.771,  1.00,   3.90 ],
	] ],
	[ 'SER', 141, [
		[ 'N',    'N',      11.791,   26.388,   45.550,  1.00,   5.42 ],
		[ 'CA',   'C',      11.339,   26.181,   46.905,  1.00,   5.14 ],
		[ 'C',    'C',      10.359,   25.031,   46.918,  1.00,   5.07 ],
		[ 'O',    'O',      10.267,   24.264,   47.889,  1.00,   4.19 ],
		[ 'CB',   'C',      10.638,   27.428,   47.413,  1.00,   5.46 ],
		[ 'OG',   'O',      11.549,   28.385,   47.879,  1.00,   5.35 ],
	] ],
	[ 'LEU', 142, [
		[ 'N',    'N',       9.596,   24.927,   45.838,  1.00,   4.62 ],
		[ 'CA',   'C',       8.652,   23.853,   45.735,  1.00,   4.89 ],
		[ 'C',    'C',       9.486,   22.571,   45.639,  1.00,   4.85 ],
		[ 'O',    'O',       9.360,   21.695,   46.497,  1.00,   5.24 ],
		[ 'CB',   'C',       7.694,   24.047,   44.551,  1.00,   4.87 ],
		[ 'CG',   'C',       6.473,   23.122,   44.496,  1.00,   5.39 ],
		[ 'CD1',  'C',       5.652,   23.261,   45.747,  1.00,   4.12 ],
		[ 'CD2',  'C',       5.630,   23.423,   43.296,  1.00,   4.51 ],
	] ],
	[ 'TYR', 143, [
		[ 'N',    'N',      10.369,   22.461,   44.649,  1.00,   4.92 ],
		[ 'CA',   'C',      11.205,   21.256,   44.569,  1.00,   4.87 ],
		[ 'C',    'C',      11.791,   20.894,   45.934,  1.00,   4.82 ],
		[ 'O',    'O',      11.713,   19.754,   46.399,  1.00,   3.07 ],
		[ 'CB',   'C',      12.369,   21.454,   43.621,  1.00,   5.27 ],
		[ 'CG',   'C',      11.997,   21.517,   42.180,  1.00,   6.95 ],
		[ 'CD1',  'C',      12.831,   22.102,   41.275,  1.00,   8.11 ],
		[ 'CD2',  'C',      10.826,   20.977,   41.721,  1.00,   7.43 ],
		[ 'CE1',  'C',      12.511,   22.140,   39.956,  1.00,   8.32 ],
		[ 'CE2',  'C',      10.492,   21.037,   40.427,  1.00,   7.36 ],
		[ 'CZ',   'C',      11.335,   21.617,   39.540,  1.00,   7.79 ],
		[ 'OH',   'O',      11.022,   21.682,   38.213,  1.00,   7.77 ],
	] ],
	[ 'ALA', 144, [
		[ 'N',    'N',      12.347,   21.898,   46.587,  1.00,   4.08 ],
		[ 'CA',   'C',      12.985,   21.708,   47.869,  1.00,   4.68 ],
		[ 'C',    'C',      12.156,   20.847,   48.814,  1.00,   5.54 ],
		[ 'O',    'O',      12.718,   20.062,   49.601,  1.00,   5.32 ],
		[ 'CB',   'C',      13.255,   23.037,   48.492,  1.00,   4.68 ],
	] ],
	[ 'SER', 145, [
		[ 'N',    'N',      10.830,   21.000,   48.735,  1.00,   6.25 ],
		[ 'CA',   'C',       9.872,   20.265,   49.573,  1.00,   6.77 ],
		[ 'C',    'C',       9.481,   18.919,   48.974,  1.00,   6.96 ],
		[ 'O',    'O',       8.728,   18.149,   49.582,  1.00,   7.57 ],
		[ 'CB',   'C',       8.583,   21.072,   49.738,  1.00,   7.01 ],
		[ 'OG',   'O',       7.708,   20.941,   48.616,  1.00,   6.61 ],
	] ],
	[ 'GLY', 146, [
		[ 'N',    'N',       9.962,   18.631,   47.773,  1.00,   6.82 ],
		[ 'CA',   'C',       9.615,   17.379,   47.134,  1.00,   6.78 ],
		[ 'C',    'C',       8.308,   17.403,   46.348,  1.00,   6.40 ],
		[ 'O',    'O',       7.798,   16.348,   45.941,  1.00,   6.00 ],
	] ],
	[ 'ARG', 147, [
		[ 'N',    'N',       7.776,   18.601,   46.113,  1.00,   6.09 ],
		[ 'CA',   'C',       6.558,   18.741,   45.334,  1.00,   5.74 ],
		[ 'C',    'C',       6.915,   19.320,   43.998,  1.00,   4.58 ],
		[ 'O',    'O',       7.985,   19.905,   43.839,  1.00,   3.12 ],
		[ 'CB',   'C',       5.548,   19.656,   46.013,  1.00,   5.88 ],
		[ 'CG',   'C',       5.030,   19.112,   47.322,  1.00,   7.91 ],
		[ 'CD',   'C',       4.425,   20.147,   48.244,  1.00,  10.12 ],
		[ 'NE',   'N',       4.867,   19.925,   49.621,  1.00,  12.06 ],
		[ 'CZ',   'C',       4.280,   19.102,   50.475,  1.00,  14.32 ],
		[ 'NH1',  'N',       3.224,   18.404,   50.124,  1.00,  15.63 ],
		[ 'NH2',  'N',       4.753,   18.967,   51.696,  1.00,  16.53 ],
	] ],
	[ 'THR', 148, [
		[ 'N',    'N',       6.014,   19.132,   43.042,  1.00,   3.51 ],
		[ 'CA',   'C',       6.138,   19.740,   41.726,  1.00,   3.00 ],
		[ 'C',    'C',       4.832,   20.414,   41.370,  1.00,   3.41 ],
		[ 'O',    'O',       4.647,   20.836,   40.264,  1.00,   4.02 ],
		[ 'CB',   'C',       6.440,   18.679,   40.664,  1.00,   4.01 ],
		[ 'OG1',  'O',       5.343,   17.763,   40.562,  1.00,   2.52 ],
		[ 'CG2',  'C',       7.588,   17.801,   41.073,  1.00,   3.54 ],
	] ],
	[ 'THR', 149, [
		[ 'N',    'N',       3.913,   20.431,   42.321,  1.00,   4.40 ],
		[ 'CA',   'C',       2.629,   21.087,   42.144,  1.00,   4.88 ],
		[ 'C',    'C',       2.216,   21.694,   43.428,  1.00,   5.21 ],
		[ 'O',    'O',       2.407,   21.125,   44.475,  1.00,   4.55 ],
		[ 'CB',   'C',       1.530,   20.089,   41.786,  1.00,   5.13 ],
		[ 'OG1',  'O',       1.744,   19.571,   40.471,  1.00,   5.32 ],
		[ 'CG2',  'C',       0.172,   20.790,   41.722,  1.00,   5.10 ],
	] ],
	[ 'GLY', 150, [
		[ 'N',    'N',       1.591,   22.837,   43.362,  1.00,   4.59 ],
		[ 'CA',   'C',       1.142,   23.454,   44.587,  1.00,   4.58 ],
		[ 'C',    'C',       1.363,   24.922,   44.437,  1.00,   2.22 ],
		[ 'O',    'O',       2.035,   25.331,   43.521,  1.00,   4.13 ],
	] ],
	[ 'ILE', 151, [
		[ 'N',    'N',       0.794,   25.727,   45.312,  1.00,   4.23 ],
		[ 'CA',   'C',       0.993,   27.155,   45.239,  1.00,   4.71 ],
		[ 'C',    'C',       1.952,   27.636,   46.327,  1.00,   4.66 ],
		[ 'O',    'O',       1.767,   27.354,   47.510,  1.00,   5.83 ],
		[ 'CB',   'C',      -0.338,   27.892,   45.288,  1.00,   5.01 ],
		[ 'CG1',  'C',      -0.083,   29.386,   45.162,  1.00,   4.99 ],
		[ 'CG2',  'C',      -1.130,   27.553,   46.542,  1.00,   4.44 ],
		[ 'CD1',  'C',      -1.345,   30.202,   44.994,  1.00,   6.49 ],
	] ],
	[ 'VAL', 152, [
		[ 'N',    'N',       2.979,   28.365,   45.893,  1.00,   5.22 ],
		[ 'CA',   'C',       4.027,   28.854,   46.763,  1.00,   5.25 ],
		[ 'C',    'C',       3.803,   30.263,   47.210,  1.00,   5.10 ],
		[ 'O',    'O',       3.302,   31.095,   46.457,  1.00,   6.14 ],
		[ 'CB',   'C',       5.337,   28.844,   46.041,  1.00,   5.67 ],
		[ 'CG1',  'C',       6.413,   29.394,   46.935,  1.00,   6.11 ],
		[ 'CG2',  'C',       5.664,   27.447,   45.616,  1.00,   5.52 ],
	] ],
	[ 'LEU', 153, [
		[ 'N',    'N',       4.156,   30.535,   48.457,  1.00,   4.41 ],
		[ 'CA',   'C',       4.079,   31.885,   48.994,  1.00,   2.30 ],
		[ 'C',    'C',       5.503,   32.267,   49.228,  1.00,   4.46 ],
		[ 'O',    'O',       6.180,   31.663,   50.071,  1.00,   4.99 ],
		[ 'CB',   'C',       3.301,   31.941,   50.283,  1.00,   3.40 ],
		[ 'CG',   'C',       3.354,   33.330,   50.901,  1.00,   4.01 ],
		[ 'CD1',  'C',       2.670,   34.379,   50.039,  1.00,   5.36 ],
		[ 'CD2',  'C',       2.701,   33.243,   52.263,  1.00,   6.02 ],
	] ],
	[ 'ASP', 154, [
		[ 'N',    'N',       5.990,   33.218,   48.444,  1.00,   5.44 ],
		[ 'CA',   'C',       7.362,   33.660,   48.595,  1.00,   6.21 ],
		[ 'C',    'C',       7.343,   35.104,   48.986,  1.00,   6.68 ],
		[ 'O',    'O',       7.158,   35.974,   48.157,  1.00,   7.37 ],
		[ 'CB',   'C',       8.159,   33.486,   47.327,  1.00,   6.11 ],
		[ 'CG',   'C',       9.633,   33.484,   47.592,  1.00,   8.60 ],
		[ 'OD1',  'O',      10.417,   33.327,   46.624,  1.00,  13.39 ],
		[ 'OD2',  'O',      10.108,   33.616,   48.746,  1.00,   9.95 ],
	] ],
	[ 'SER', 155, [
		[ 'N',    'N',       7.462,   35.359,   50.274,  1.00,   6.94 ],
		[ 'CA',   'C',       7.555,   36.718,   50.753,  1.00,   6.66 ],
		[ 'C',    'C',       8.932,   36.854,   51.401,  1.00,   7.00 ],
		[ 'O',    'O',       9.285,   36.093,   52.310,  1.00,   6.13 ],
		[ 'CB',   'C',       6.448,   37.020,   51.756,  1.00,   6.85 ],
		[ 'OG',   'O',       6.630,   38.288,   52.349,  1.00,   4.23 ],
	] ],
	[ 'GLY', 156, [
		[ 'N',    'N',       9.704,   37.828,   50.918,  1.00,   7.60 ],
		[ 'CA',   'C',      11.045,   38.099,   51.421,  1.00,   8.07 ],
		[ 'C',    'C',      11.255,   39.510,   51.941,  1.00,   8.56 ],
		[ 'O',    'O',      10.525,   39.985,   52.828,  1.00,   8.61 ],
	] ],
	[ 'ASP', 157, [
		[ 'N',    'N',      12.257,   40.200,   51.402,  1.00,   8.94 ],
		[ 'CA',   'C',      12.555,   41.543,   51.881,  1.00,   9.06 ],
		[ 'C',    'C',      11.963,   42.669,   51.038,  1.00,   9.04 ],
		[ 'O',    'O',      11.723,   43.769,   51.551,  1.00,   8.82 ],
		[ 'CB',   'C',      14.046,   41.733,   51.982,  1.00,   9.08 ],
		[ 'CG',   'C',      14.397,   42.981,   52.725,  1.00,  10.11 ],
		[ 'OD1',  'O',      15.085,   43.879,   52.153,  1.00,  11.06 ],
		[ 'OD2',  'O',      13.999,   43.153,   53.894,  1.00,  12.03 ],
	] ],
	[ 'GLY', 158, [
		[ 'N',    'N',      11.739,   42.398,   49.754,  1.00,   8.93 ],
		[ 'CA',   'C',      11.221,   43.402,   48.845,  1.00,   9.25 ],
		[ 'C',    'C',       9.898,   43.085,   48.158,  1.00,   9.54 ],
		[ 'O',    'O',       9.190,   44.010,   47.734,  1.00,   9.16 ],
	] ],
	[ 'VAL', 159, [
		[ 'N',    'N',       9.558,   41.797,   48.052,  1.00,   9.92 ],
		[ 'CA',   'C',       8.295,   41.375,   47.427,  1.00,   9.75 ],
		[ 'C',    'C',       7.666,   40.103,   47.981,  1.00,   9.14 ],
		[ 'O',    'O',       8.296,   39.308,   48.664,  1.00,   8.77 ],
		[ 'CB',   'C',       8.495,   41.104,   45.961,  1.00,   9.80 ],
		[ 'CG1',  'C',       8.522,   42.362,   45.236,  1.00,  11.18 ],
		[ 'CG2',  'C',       9.786,   40.381,   45.752,  1.00,  10.26 ],
	] ],
	[ 'THR', 160, [
		[ 'N',    'N',       6.401,   39.925,   47.653,  1.00,   8.58 ],
		[ 'CA',   'C',       5.683,   38.754,   48.056,  1.00,   8.33 ],
		[ 'C',    'C',       5.077,   38.242,   46.784,  1.00,   7.72 ],
		[ 'O',    'O',       4.582,   39.024,   45.992,  1.00,   7.47 ],
		[ 'CB',   'C',       4.585,   39.114,   49.047,  1.00,   8.44 ],
		[ 'OG1',  'O',       5.160,   39.559,   50.283,  1.00,   8.07 ],
		[ 'CG2',  'C',       3.788,   37.879,   49.437,  1.00,   9.18 ],
	] ],
	[ 'HIS', 161, [
		[ 'N',    'N',       5.140,   36.935,   46.572,  1.00,   7.11 ],
		[ 'CA',   'C',       4.569,   36.331,   45.378,  1.00,   6.52 ],
		[ 'C',    'C',       3.588,   35.187,   45.699,  1.00,   5.91 ],
		[ 'O',    'O',       3.772,   34.411,   46.630,  1.00,   6.09 ],
		[ 'CB',   'C',       5.682,   35.810,   44.443,  1.00,   6.27 ],
		[ 'CG',   'C',       6.277,   36.860,   43.552,  1.00,   5.32 ],
		[ 'ND1',  'N',       7.491,   37.454,   43.810,  1.00,   3.38 ],
		[ 'CD2',  'C',       5.831,   37.409,   42.397,  1.00,   4.92 ],
		[ 'CE1',  'C',       7.750,   38.347,   42.873,  1.00,   4.58 ],
		[ 'NE2',  'N',       6.761,   38.336,   41.998,  1.00,   2.82 ],
	] ],
	[ 'ASN', 162, [
		[ 'N',    'N',       2.541,   35.087,   44.913,  1.00,   5.40 ],
		[ 'CA',   'C',       1.688,   33.947,   45.015,  1.00,   4.34 ],
		[ 'C',    'C',       2.003,   33.245,   43.722,  1.00,   2.22 ],
		[ 'O',    'O',       1.708,   33.791,   42.655,  1.00,   4.56 ],
		[ 'CB',   'C',       0.226,   34.351,   45.073,  1.00,   4.59 ],
		[ 'CG',   'C',      -0.140,   34.959,   46.384,  1.00,   4.54 ],
		[ 'OD1',  'O',      -0.343,   36.164,   46.489,  1.00,   3.24 ],
		[ 'ND2',  'N',      -0.214,   34.128,   47.411,  1.00,   5.59 ],
	] ],
	[ 'VAL', 163, [
		[ 'N',    'N',       2.605,   32.045,   43.771,  1.00,   2.90 ],
		[ 'CA',   'C',       2.996,   31.360,   42.538,  1.00,   3.89 ],
		[ 'C',    'C',       2.524,   29.944,   42.456,  1.00,   4.35 ],
		[ 'O',    'O',       3.066,   29.053,   43.089,  1.00,   4.31 ],
		[ 'CB',   'C',       4.541,   31.321,   42.345,  1.00,   4.57 ],
		[ 'CG1',  'C',       4.892,   30.866,   40.943,  1.00,   4.98 ],
		[ 'CG2',  'C',       5.191,   32.666,   42.621,  1.00,   4.26 ],
	] ],
	[ 'PRO', 164, [
		[ 'N',    'N',       1.410,   29.794,   41.768,  1.00,   5.24 ],
		[ 'CA',   'C',       0.880,   28.511,   41.329,  1.00,   5.84 ],
		[ 'C',    'C',       1.832,   27.670,   40.486,  1.00,   5.56 ],
		[ 'O',    'O',       2.233,   28.088,   39.402,  1.00,   6.36 ],
		[ 'CB',   'C',      -0.315,   28.939,   40.463,  1.00,   5.47 ],
		[ 'CG',   'C',      -0.750,   30.161,   41.007,  1.00,   5.89 ],
		[ 'CD',   'C',       0.430,   30.869,   41.575,  1.00,   5.69 ],
	] ],
	[ 'ILE', 165, [
		[ 'N',    'N',       2.125,   26.468,   40.948,  1.00,   6.60 ],
		[ 'CA',   'C',       2.952,   25.571,   40.176,  1.00,   7.42 ],
		[ 'C',    'C',       2.246,   24.238,   39.947,  1.00,   7.81 ],
		[ 'O',    'O',       1.716,   23.658,   40.878,  1.00,   8.19 ],
		[ 'CB',   'C',       4.284,   25.359,   40.869,  1.00,   7.86 ],
		[ 'CG1',  'C',       4.969,   26.708,   41.096,  1.00,   8.16 ],
		[ 'CG2',  'C',       5.162,   24.433,   40.028,  1.00,   8.29 ],
		[ 'CD1',  'C',       6.199,   26.593,   41.892,  1.00,   8.32 ],
	] ],
	[ 'TYR', 166, [
		[ 'N',    'N',       2.246,   23.761,   38.698,  1.00,   8.74 ],
		[ 'CA',   'C',       1.599,   22.495,   38.336,  1.00,   9.08 ],
		[ 'C',    'C',       2.493,   21.608,   37.497,  1.00,   9.63 ],
		[ 'O',    'O',       2.804,   21.919,   36.369,  1.00,   8.75 ],
		[ 'CB',   'C',       0.295,   22.735,   37.573,  1.00,   9.00 ],
		[ 'CG',   'C',      -0.392,   21.450,   37.178,  1.00,   7.69 ],
		[ 'CD1',  'C',      -0.519,   21.088,   35.859,  1.00,   7.59 ],
		[ 'CD2',  'C',      -0.892,   20.598,   38.130,  1.00,   6.77 ],
		[ 'CE1',  'C',      -1.129,   19.921,   35.506,  1.00,   7.56 ],
		[ 'CE2',  'C',      -1.512,   19.428,   37.790,  1.00,   6.78 ],
		[ 'CZ',   'C',      -1.632,   19.098,   36.477,  1.00,   7.14 ],
		[ 'OH',   'O',      -2.255,   17.932,   36.128,  1.00,   8.93 ],
	] ],
	[ 'GLU', 167, [
		[ 'N',    'N',       2.878,   20.482,   38.071,  1.00,  10.81 ],
		[ 'CA',   'C',       3.777,   19.514,   37.435,  1.00,  11.87 ],
		[ 'C',    'C',       5.129,   20.122,   37.076,  1.00,  12.11 ],
		[ 'O',    'O',       5.696,   19.800,   36.051,  1.00,  12.29 ],
		[ 'CB',   'C',       3.117,   18.823,   36.225,  1.00,  12.15 ],
		[ 'CG',   'C',       1.791,   18.141,   36.571,  1.00,  13.68 ],
		[ 'CD',   'C',       1.495,   16.845,   35.807,  1.00,  14.91 ],
		[ 'OE1',  'O',       1.531,   16.841,   34.545,  1.00,  14.38 ],
		[ 'OE2',  'O',       1.185,   15.831,   36.492,  1.00,  15.72 ],
	] ],
	[ 'GLY', 168, [
		[ 'N',    'N',       5.644,   20.994,   37.934,  1.00,  12.77 ],
		[ 'CA',   'C',       6.961,   21.578,   37.738,  1.00,  13.38 ],
		[ 'C',    'C',       7.019,   22.872,   36.944,  1.00,  13.97 ],
		[ 'O',    'O',       8.111,   23.425,   36.733,  1.00,  14.01 ],
	] ],
	[ 'TYR', 169, [
		[ 'N',    'N',       5.865,   23.354,   36.487,  1.00,  14.30 ],
		[ 'CA',   'C',       5.829,   24.587,   35.712,  1.00,  14.80 ],
		[ 'C',    'C',       4.923,   25.666,   36.311,  1.00,  13.76 ],
		[ 'O',    'O',       3.773,   25.423,   36.618,  1.00,  13.83 ],
		[ 'CB',   'C',       5.404,   24.278,   34.291,  1.00,  15.29 ],
		[ 'CG',   'C',       6.468,   23.550,   33.478,  1.00,  19.88 ],
		[ 'CD1',  'C',       6.219,   22.303,   32.929,  1.00,  22.66 ],
		[ 'CD2',  'C',       7.709,   24.136,   33.232,  1.00,  23.83 ],
		[ 'CE1',  'C',       7.158,   21.668,   32.191,  1.00,  25.22 ],
		[ 'CE2',  'C',       8.657,   23.496,   32.488,  1.00,  25.52 ],
		[ 'CZ',   'C',       8.376,   22.260,   31.975,  1.00,  27.06 ],
		[ 'OH',   'O',       9.317,   21.586,   31.220,  1.00,  31.41 ],
	] ],
	[ 'ALA', 170, [
		[ 'N',    'N',       5.455,   26.867,   36.476,  1.00,  12.68 ],
		[ 'CA',   'C',       4.674,   27.960,   37.010,  1.00,  11.89 ],
		[ 'C',    'C',       3.588,   28.362,   36.044,  1.00,  11.06 ],
		[ 'O',    'O',       3.781,   28.299,   34.848,  1.00,  10.53 ],
		[ 'CB',   'C',       5.559,   29.137,   37.278,  1.00,  11.94 ],
	] ],
	[ 'LEU', 171, [
		[ 'N',    'N',       2.444,   28.795,   36.565,  1.00,  10.58 ],
		[ 'CA',   'C',       1.332,   29.217,   35.716,  1.00,  10.09 ],
		[ 'C',    'C',       1.252,   30.753,   35.654,  1.00,   9.81 ],
		[ 'O',    'O',       0.548,   31.385,   36.401,  1.00,   9.12 ],
		[ 'CB',   'C',       0.037,   28.589,   36.216,  1.00,  10.00 ],
		[ 'CG',   'C',       0.118,   27.083,   36.499,  1.00,   9.47 ],
		[ 'CD1',  'C',      -1.206,   26.528,   36.982,  1.00,  10.43 ],
		[ 'CD2',  'C',       0.567,   26.339,   35.283,  1.00,   9.53 ],
	] ],
	[ 'PRO', 172, [
		[ 'N',    'N',       1.953,   31.341,   34.703,  1.00,  10.07 ],
		[ 'CA',   'C',       2.110,   32.792,   34.632,  1.00,  10.17 ],
		[ 'C',    'C',       0.820,   33.583,   34.695,  1.00,  10.77 ],
		[ 'O',    'O',       0.783,   34.656,   35.278,  1.00,  10.58 ],
		[ 'CB',   'C',       2.760,   32.990,   33.274,  1.00,  10.07 ],
		[ 'CG',   'C',       3.474,   31.715,   33.023,  1.00,   9.90 ],
		[ 'CD',   'C',       2.607,   30.657,   33.577,  1.00,  10.07 ],
	] ],
	[ 'HIS', 173, [
		[ 'N',    'N',      -0.243,   33.093,   34.098,  1.00,  11.54 ],
		[ 'CA',   'C',      -1.455,   33.877,   34.159,  1.00,  12.37 ],
		[ 'C',    'C',      -1.985,   33.957,   35.575,  1.00,  12.13 ],
		[ 'O',    'O',      -2.757,   34.841,   35.869,  1.00,  12.43 ],
		[ 'CB',   'C',      -2.537,   33.318,   33.239,  1.00,  12.90 ],
		[ 'CG',   'C',      -2.949,   31.934,   33.577,  1.00,  14.80 ],
		[ 'ND1',  'N',      -2.078,   30.871,   33.517,  1.00,  17.23 ],
		[ 'CD2',  'C',      -4.138,   31.430,   33.983,  1.00,  18.52 ],
		[ 'CE1',  'C',      -2.713,   29.769,   33.879,  1.00,  19.11 ],
		[ 'NE2',  'N',      -3.966,   30.077,   34.161,  1.00,  19.29 ],
	] ],
	[ 'ALA', 174, [
		[ 'N',    'N',      -1.555,   33.056,   36.452,  1.00,  12.06 ],
		[ 'CA',   'C',      -2.079,   32.983,   37.815,  1.00,  11.75 ],
		[ 'C',    'C',      -1.183,   33.552,   38.901,  1.00,  11.77 ],
		[ 'O',    'O',      -1.609,   33.666,   40.051,  1.00,  11.85 ],
		[ 'CB',   'C',      -2.390,   31.558,   38.136,  1.00,  12.15 ],
	] ],
	[ 'ILE', 175, [
		[ 'N',    'N',       0.048,   33.903,   38.545,  1.00,  12.24 ],
		[ 'CA',   'C',       0.974,   34.550,   39.481,  1.00,  12.59 ],
		[ 'C',    'C',       0.456,   35.905,   39.983,  1.00,  12.63 ],
		[ 'O',    'O',      -0.218,   36.628,   39.259,  1.00,  12.52 ],
		[ 'CB',   'C',       2.352,   34.737,   38.813,  1.00,  12.75 ],
		[ 'CG1',  'C',       2.936,   33.400,   38.384,  1.00,  12.86 ],
		[ 'CG2',  'C',       3.313,   35.438,   39.761,  1.00,  13.73 ],
		[ 'CD1',  'C',       4.327,   33.500,   37.831,  1.00,  14.01 ],
	] ],
	[ 'MET', 176, [
		[ 'N',    'N',       0.783,   36.222,   41.225,  1.00,  13.15 ],
		[ 'CA',   'C',       0.415,   37.486,   41.842,  1.00,  13.84 ],
		[ 'C',    'C',       1.640,   38.104,   42.501,  1.00,  14.09 ],
		[ 'O',    'O',       2.371,   37.440,   43.232,  1.00,  14.06 ],
		[ 'CB',   'C',      -0.636,   37.265,   42.921,  1.00,  14.07 ],
		[ 'CG',   'C',      -1.915,   36.635,   42.423,  1.00,  14.85 ],
		[ 'SD',   'S',      -2.963,   37.870,   41.679,  1.00,  15.11 ],
		[ 'CE',   'C',      -3.592,   36.928,   40.290,  1.00,  17.32 ],
	] ],
	[ 'ARG', 177, [
		[ 'N',    'N',       1.835,   39.390,   42.270,  1.00,  14.38 ],
		[ 'CA',   'C',       2.989,   40.106,   42.779,  1.00,  14.61 ],
		[ 'C',    'C',       2.499,   41.167,   43.729,  1.00,  13.63 ],
		[ 'O',    'O',       1.641,   41.939,   43.375,  1.00,  14.18 ],
		[ 'CB',   'C',       3.703,   40.755,   41.589,  1.00,  15.28 ],
		[ 'CG',   'C',       4.936,   41.609,   41.874,  1.00,  18.72 ],
		[ 'CD',   'C',       5.714,   41.949,   40.585,  1.00,  22.79 ],
		[ 'NE',   'N',       6.753,   42.967,   40.728,  1.00,  25.97 ],
		[ 'CZ',   'C',       6.523,   44.242,   41.028,  1.00,  29.57 ],
		[ 'NH1',  'N',       5.286,   44.678,   41.254,  1.00,  30.94 ],
		[ 'NH2',  'N',       7.536,   45.093,   41.111,  1.00,  30.30 ],
	] ],
);
my @sheet;
$serial = 0;
for my $r (@sheet_res) {
	my ($resname, $resseq, $atoms) = @$r;
	for my $a (@$atoms) {
		$serial++;
		push @sheet, atom_line(
			record => 'ATOM  ', serial => $serial, name => $a->[0], element => $a->[1],
			altloc => '', resname => $resname, chain => 'A', resseq => $resseq, icode => '',
			x => $a->[2], y => $a->[3], z => $a->[4], occ => $a->[5], b => $a->[6],
		);
	}
}
push @sheet, 'END';


# --- the mmCIF twins ------------------------------------------------------
#
# The same structures, written the other way.  The coordinates are converted
# from the records above rather than typed again, because the point of the
# .cif fixtures is that reading either file gives the same answer, and a
# fixture pair that was typed twice tests the typing.
#
# What is deliberately not converted is the naming.  A real mmCIF file carries
# two sets of identifiers -- label_* assigned by the archive, auth_* as the
# depositor numbered them -- and only the auth_* ones match the PDB record.
# So the label_* columns written below are the other ones on purpose: chains
# lettered straight through including the waters, residues numbered from 1
# with no gap and no insertion code.  A reader that reached for label_asym_id
# would produce a structure with six chains in it, and t/cif.t would say so.

# cifq() -- one value, quoted the way the format needs it
sub cifq {
	my ($v) = @_;
	return '?' unless defined $v && length $v;
	return $v unless $v =~ /[\s'"]/ || $v =~ /\A[_\#\$\[\]]/ || $v =~ /\A(?:data|loop|save|stop|global)_/i;
	return "'$v'" if $v !~ /'/;
	return "\"$v\"" if $v !~ /"/;
	return "\n;$v\n;";      # a value holding both quotes has only one way left
}

my @ATOM_ITEM = qw(
	group_PDB id type_symbol label_atom_id label_alt_id label_comp_id
	label_asym_id label_entity_id label_seq_id pdbx_PDB_ins_code
	Cartn_x Cartn_y Cartn_z occupancy B_iso_or_equiv pdbx_formal_charge
	auth_seq_id auth_comp_id auth_asym_id auth_atom_id pdbx_PDB_model_num
);

# atom_site_loop() -- the ATOM/HETATM records of a PDB file as an mmCIF loop.
# Read by column, because that is where a PDB record keeps its fields, and the
# whole point is to carry every one of them across unchanged.
sub atom_site_loop {
	my ($lines, %opt) = @_;
	my (@rows, %asym, $model, $seq);
	$model = 1;
	my %seq_of;      # label_seq_id: the polymer position, counted per label asym
	for my $l (@$lines) {
		if ($l =~ /\AMODEL\s+(\d+)/) { $model = $1; next }
		next unless $l =~ /\A(ATOM  |HETATM)/;
		my %a = (
			group   => ($1 eq 'ATOM  ' ? 'ATOM' : 'HETATM'),
			serial  => _t(substr($l, 6, 5)),
			name    => _t(substr($l, 12, 4)),
			altloc  => _t(substr($l, 16, 1)),
			resname => _t(substr($l, 17, 3)),
			chain   => _t(substr($l, 21, 1)),
			resseq  => _t(substr($l, 22, 4)),
			icode   => _t(substr($l, 26, 1)),
			x       => _t(substr($l, 30, 8)),
			y       => _t(substr($l, 38, 8)),
			z       => _t(substr($l, 46, 8)),
			occ     => _t(substr($l, 54, 6)),
			b       => _t(substr($l, 60, 6)),
			element => (length($l) > 76 ? _t(substr($l, 76, 2)) : ''),
			charge  => (length($l) > 78 ? _t(substr($l, 78, 2)) : ''),
		);
		# label_asym_id: a fresh letter per chain and per kind of thing in it,
		# which is how the archive assigns them and is not the PDB chain id
		my $kind = $a{group} eq 'HETATM' ? ($a{resname} eq 'HOH' ? 'w' : "h$a{resname}") : 'p';
		# lettered from B rather than from A, so that no label_asym_id can
		# coincide with the auth_asym_id of the chain it belongs to and a
		# reader that took the wrong one cannot pass by luck
		my $ak = "$a{chain}/$kind";
		$asym{$ak} = chr(ord('B') + $asym{n}++) unless exists $asym{$ak};
		my $lasym = $asym{$ak};
		my $lseq  = '.';
		if ($kind eq 'p') {
			my $rk = "$ak/$a{resseq}$a{icode}";
			$seq_of{$lasym}{$rk} ||= ++$seq_of{$lasym}{n};
			$lseq = $seq_of{$lasym}{$rk};
		}
		# a PDB charge is "2+", an mmCIF one is 2; converted here so that the
		# reader has the conversion to undo
		my $chg = '?';
		if ($a{charge} =~ /\A(\d)([-+])\z/) { $chg = ($2 eq '-' ? "-$1" : $1) }
		# the two spellings of nothing: '.' where the item does not apply to
		# this row, '?' where it does and the file does not know it.  Both are
		# written, because both have to read back as an empty field.
		push @rows, [
			$a{group}, $a{serial},
			(length $a{element} ? $a{element} : '?'),
			$a{name},
			(length $a{altloc} ? $a{altloc} : '.'),
			$a{resname}, $lasym, ($kind eq 'p' ? 1 : 2), $lseq,
			(length $a{icode} ? $a{icode} : '?'),
			$a{x}, $a{y}, $a{z}, $a{occ}, $a{b}, $chg,
			$a{resseq}, $a{resname}, $a{chain}, $a{name}, $model,
		];
	}
	my @items = @ATOM_ITEM;
	my @keep  = 0 .. $#items;
	if ($opt{no_element}) {      # a file with no type_symbol, as bare.pdb has no element
		@keep  = grep { $items[$_] ne 'type_symbol' } @keep;
	}
	my @out = ('loop_', map { "_atom_site.$items[$_]" } @keep);
	for my $r (@rows) {
		push @out, join ' ', map { ($_ eq '.' || $_ eq '?') ? $_ : cifq($_) } @{$r}[@keep];
	}
	return @out;
}

sub _t { my $s = shift; return '' unless defined $s; $s =~ s/\A\s+//; $s =~ s/\s+\z//; return $s }

# a category with one row, written as plain tags
sub cif_pairs {
	my ($cat, @kv) = @_;
	my @out;
	while (@kv) {
		my ($k, $v) = splice @kv, 0, 2;
		push @out, sprintf('%-52s %s', "_$cat.$k", cifq($v));
	}
	return @out;
}

# a category with several rows, written as a loop_
sub cif_loop {
	my ($cat, $items, @rows) = @_;
	my @out = ('loop_', map { "_$cat.$_" } @$items);
	push @out, join ' ', map { cifq($_) } @$_ for @rows;
	return @out;
}

my @minicif = ('data_9XYZ', '#');
push @minicif,
	cif_pairs('entry', id => '9XYZ'), '#',
	# a semicolon text field, which is the only way the format has of writing
	# a value too long for a line -- and the only token that spans lines
	'_struct.entry_id   9XYZ',
	'_struct.title',
	';A SMALL TEST STRUCTURE WITH A GAP, AN INSERTION CODE, AN ALTERNATE CONFORMER AND A LIGAND',
	';', '#',
	cif_pairs('struct_keywords',
		entry_id      => '9XYZ',
		pdbx_keywords => 'HYDROLASE/PEPTIDE INHIBITOR',
		text          => 'HYDROLASE, TEST STRUCTURE, COMPLEX (HYDROLASE-PEPTIDE)'), '#',
	cif_pairs('pdbx_database_status', entry_id => '9XYZ',
		recvd_initial_deposition_date => '2020-01-01'), '#',
	cif_pairs('exptl', entry_id => '9XYZ', method => 'X-RAY DIFFRACTION'), '#',
	cif_pairs('refine',
		entry_id            => '9XYZ',
		'ls_d_res_high'     => '1.85',
		'ls_R_factor_R_work'=> '0.174',
		'ls_R_factor_R_free'=> '0.219'), '#',
	cif_pairs('diffrn', id => 1, ambient_temp => '100.0'), '#',
	cif_pairs('exptl_crystal_grow', crystal_id => 1, pH => '7.5'), '#',
	cif_loop('audit_author', [qw(name pdbx_ordinal)],
		[ 'Condon, D.E.', 1 ], [ 'Other, A.N.', 2 ]), '#',
	cif_loop('citation',
		[qw(id title journal_abbrev journal_volume page_first year
		    pdbx_database_id_PubMed pdbx_database_id_DOI)],
		[ 'primary', 'A STRUCTURE MADE UP FOR A TEST SUITE, AND WHAT IT CONTAINS',
		  'J.Invented.Res.', 10, 42, 2020, 12345678, '10.1000/INVENTED.2020.42' ]), '#',
	cif_loop('citation_author', [qw(citation_id name ordinal)],
		[ 'primary', 'Condon, D.E.', 1 ], [ 'primary', 'Other, A.N.', 2 ]), '#',
	cif_pairs('cell', entry_id => '9XYZ',
		length_a => '40.100', length_b => '50.200', length_c => '60.300',
		angle_alpha => '90.00', angle_beta => '95.50', angle_gamma => '90.00',
		'Z_PDB' => 4), '#',
	cif_pairs('symmetry', entry_id => '9XYZ', 'space_group_name_H-M' => 'P 1 21 1'), '#',
	cif_loop('entity', [qw(id type src_method pdbx_description pdbx_ec)],
		[ 1, 'polymer',     'man', 'TEST PROTEIN', '3.4.21.5' ],
		[ 2, 'polymer',     'syn', 'TEST DNA',     undef ],
		[ 3, 'non-polymer', 'syn', '2-ACETAMIDO-2-DEOXY-BETA-D-GLUCOPYRANOSE', undef ],
		[ 4, 'non-polymer', 'syn', 'ZINC ION',     undef ],
		[ 5, 'water',       'nat', 'water',        undef ]), '#',
	cif_loop('entity_poly', [qw(entity_id type pdbx_seq_one_letter_code_can pdbx_strand_id)],
		[ 1, 'polypeptide(L)',       'MAGLKCMHHSC', 'A' ],
		[ 2, 'polydeoxyribonucleotide', 'ACGT',      'B' ]), '#',
	cif_loop('entity_poly_seq', [qw(entity_id num mon_id hetero)],
		(map { [ 1, $_->[0], $_->[1], 'n' ] }
		 map { [ $_ + 1, (qw(MET ALA GLY LEU LYS CYS MSE HIS HIS SER CYS))[$_] ] } 0 .. 10),
		(map { [ 2, $_->[0], $_->[1], 'n' ] }
		 map { [ $_ + 1, (qw(DA DC DG DT))[$_] ] } 0 .. 3)), '#',
	cif_pairs('entity_src_gen',
		entity_id                        => 1,
		pdbx_gene_src_scientific_name    => 'HOMO SAPIENS',
		pdbx_gene_src_ncbi_taxonomy_id   => 9606,
		pdbx_host_org_scientific_name    => 'ESCHERICHIA COLI'), '#',
	cif_loop('chem_comp', [qw(id name formula type)],
		[ 'MSE', 'SELENOMETHIONINE', 'C5 H11 N O2 Se', 'L-peptide linking' ],
		[ 'NAG', '2-ACETAMIDO-2-DEOXY-BETA-D-GLUCOPYRANOSE', 'C8 H15 N O6', 'D-saccharide' ],
		[ 'ZN',  'ZINC ION',  'ZN 2+', 'non-polymer' ],
		[ 'HOH', 'WATER',     'H2 O',  'water' ]), '#',
	cif_loop('pdbx_nonpoly_scheme',
		[qw(asym_id entity_id mon_id pdb_strand_id pdb_seq_num pdb_ins_code)],
		[ 'C', 3, 'NAG', 'A', 201, '.' ],
		[ 'D', 4, 'ZN',  'A', 202, '.' ],
		[ 'E', 5, 'HOH', 'A', 301, '.' ],
		[ 'E', 5, 'HOH', 'A', 302, '.' ]), '#',
	cif_loop('pdbx_struct_mod_residue',
		[qw(id label_comp_id auth_comp_id auth_asym_id auth_seq_id parent_comp_id details)],
		[ 1, 'MSE', 'MSE', 'A', 7, 'MET', 'SELENOMETHIONINE' ]), '#',
	cif_loop('struct_conf',
		[qw(conf_type_id id beg_auth_comp_id beg_auth_asym_id beg_auth_seq_id
		    end_auth_comp_id end_auth_asym_id end_auth_seq_id
		    pdbx_PDB_helix_class pdbx_PDB_helix_length)],
		[ 'HELX_P', 'AA1', 'MET', 'A', 1, 'GLY', 'A', 3, 1, 3 ]), '#',
	cif_loop('struct_sheet_range',
		[qw(sheet_id id beg_auth_comp_id beg_auth_asym_id beg_auth_seq_id
		    end_auth_comp_id end_auth_asym_id end_auth_seq_id)],
		[ 'AA1', 1, 'CYS', 'A', 6, 'HIS', 'A', 8 ]), '#',
	cif_loop('struct_conn',
		[qw(id conn_type_id ptnr1_label_atom_id ptnr1_auth_comp_id ptnr1_auth_asym_id
		    ptnr1_auth_seq_id ptnr2_label_atom_id ptnr2_auth_comp_id ptnr2_auth_asym_id
		    ptnr2_auth_seq_id pdbx_dist_value)],
		[ 'disulf1', 'disulf', 'SG', 'CYS', 'A', 6,  'SG', 'CYS', 'A', 10, '2.03' ],
		[ 'covale1', 'covale', 'ZN', 'ZN',  'A', 202, 'SG', 'CYS', 'A', 6,  '2.31' ]), '#',
	cif_loop('struct_mon_prot_cis',
		[qw(pdbx_id auth_comp_id auth_asym_id auth_seq_id pdbx_auth_comp_id_2
		    pdbx_auth_asym_id_2 pdbx_auth_seq_id_2 pdbx_omega_angle)],
		[ 1, 'GLY', 'A', 3, 'CYS', 'A', 6, '-0.42' ]), '#',
	cif_loop('struct_ref', [qw(id db_name db_code pdbx_db_accession entity_id)],
		[ 1, 'UNP', 'TEST_HUMAN', 'P12345', 1 ]), '#',
	cif_loop('struct_ref_seq',
		[qw(align_id ref_id pdbx_strand_id pdbx_auth_seq_align_beg
		    pdbx_auth_seq_align_end pdbx_db_accession db_align_beg db_align_end)],
		[ 1, 1, 'A', 1, 11, 'P12345', 1, 11 ]), '#';
push @minicif, atom_site_loop(\@mini), '#';

my @nmrcif = ('data_9NMR', '#');
push @nmrcif,
	cif_pairs('entry', id => '9NMR'), '#',
	'_struct.title    "A THREE MODEL ENSEMBLE"', '#',
	cif_pairs('exptl', entry_id => '9NMR', method => 'SOLUTION NMR'), '#',
	cif_pairs('pdbx_nmr_ensemble', entry_id => '9NMR',
		conformers_submitted_total_number => 3), '#',
	cif_loop('entity', [qw(id type pdbx_description)], [ 1, 'polymer', 'TEST PEPTIDE' ]), '#',
	cif_loop('entity_poly', [qw(entity_id pdbx_strand_id)], [ 1, 'A' ]), '#',
	cif_loop('entity_poly_seq', [qw(entity_id num mon_id)],
		[ 1, 1, 'GLY' ], [ 1, 2, 'SER' ], [ 1, 3, 'TRP' ]), '#';
push @nmrcif, atom_site_loop(\@nmr), '#';

my @enscif = ('data_9ENS', '#');
push @enscif,
	cif_pairs('entry', id => '9ENS'), '#',
	'_struct.title    "FOUR MODELS OF A BOUND PEPTIDE"', '#',
	cif_pairs('exptl', entry_id => '9ENS', method => 'SOLUTION NMR'), '#',
	cif_pairs('pdbx_nmr_ensemble', entry_id => '9ENS',
		conformers_submitted_total_number => 4), '#',
	cif_loop('entity', [qw(id type pdbx_description)],
		[ 1, 'polymer', 'YAP65 WW DOMAIN LIGAND PEPTIDE' ]), '#',
	cif_loop('entity_poly', [qw(entity_id pdbx_strand_id)], [ 1, 'B' ]), '#',
	cif_loop('entity_poly_seq', [qw(entity_id num mon_id)],
		map { [ 1, $_->[0], $_->[1] ] }
		[ 1, 'ACE' ], [ 2, 'PRO' ], [ 3, 'LEU' ], [ 4, 'PRO' ], [ 5, 'PRO' ], [ 6, 'TYR' ]), '#';
push @enscif, atom_site_loop(\@ensemble), '#';

# bare.cif -- coordinates and nothing else, and no type_symbol, so the element
# has to come out of the atom name here exactly as it does from a PDB record
# with no element columns
my @barecif = ('data_bare', '#', atom_site_loop(\@bare, no_element => 1), '#');

# The two feature fixtures, the other way round.  Both are plain ATOM records
# with nothing else in them, so the conversion is the whole file.
my @stackcif = ('data_9ARO', '#', atom_site_loop(\@stack), '#');
my @basescif = ('data_9NUC', '#', atom_site_loop(\@bases), '#');
my @rnacif    = ('data_9RNA', '#', atom_site_loop(\@rna), '#');
my @aformcif  = ('data_9AFM', '#', atom_site_loop(\@aform), '#');
my @duplexcif = ('data_9DUP', '#', atom_site_loop(\@duplex), '#');
my @wobblecif = ('data_9WOB', '#', atom_site_loop(\@wobble), '#');
my @sscif    = ('data_9SSB', '#', atom_site_loop(\@ss), '#');
my @foldcif  = ('data_9FLD', '#', atom_site_loop(\@fold), '#');
my @sheetcif = ('data_9SHT', '#', atom_site_loop(\@sheet), '#');

# quirks.cif -- everything about the way the format is written down that a
# reader has to get right, in one file: comments in every position, both kinds
# of quote, a quote inside a value (O5', which is an atom name and not a
# string that someone forgot to close), a semicolon text field, '.' and '?' for
# the two kinds of nothing, a quoted '.' that is a full stop and not a null, a
# formal charge in the mmCIF spelling, a category written as plain tags where
# it is usually a loop, and columns in an order no writer uses.
my @quirks = (
'# a comment before anything at all',
'data_QRK    # and one after the block name',
'#',
'_entry.id   QRK',
'_struct.title     "A file that leans on the syntax"',
"_struct_keywords.text    'one, two, three'",
'_exptl.method',
';SOLUTION NMR',
';',
'#',
'loop_',
'_atom_site.auth_atom_id',          # the columns in a deliberately odd order
'_atom_site.pdbx_formal_charge',
'_atom_site.auth_comp_id',
'_atom_site.group_PDB',
'_atom_site.auth_asym_id',
'_atom_site.Cartn_x',
'_atom_site.Cartn_y',
'_atom_site.Cartn_z',
'_atom_site.auth_seq_id',
'_atom_site.type_symbol',
'_atom_site.id',
'_atom_site.label_alt_id',
'_atom_site.occupancy',
'_atom_site.B_iso_or_equiv',
'_atom_site.pdbx_PDB_ins_code',
"P     ?   G  ATOM   B  1.000 2.000 3.000 1 P  1 . 1.00 10.00 ?",
"OP1   -1  G  ATOM   B  2.000 3.000 4.000 1 O  2 . 1.00 11.00 ?",
"\"O5'\" 0   G  ATOM   B  3.000 4.000 5.000 1 O  3 . 1.00 12.00 ?",
"\"C1'\" 3   G  ATOM   B  4.000 5.000 6.000 1 C  4 . 1.00 13.00 ?",
'# the ion is a HETATM, is charged, and has an insertion code',
"ZN    2   ZN HETATM B  9.000 9.000 9.000 40 ZN 5 . 1.00 14.00 A",
'#',
'# a category that is usually a loop, written as plain tags because it has',
'# one row -- which the format allows and a reader has to accept',
"_chem_comp.id        ZN",
"_chem_comp.name      'ZINC ION'",
"_chem_comp.formula   'ZN 2+'",
'#',
'loop_',
'_citation.id',
'_citation.title',
'_citation.year',
"primary  'A paper with a full stop.  And two sentences.'  2021",
'#',
'_cell.length_a    .',                  # not applicable
'_cell.length_b    ?',                  # unknown
"_pdbx_database_status.recvd_initial_deposition_date  '.'",  # quoted: a value
'#',
);

for my $f ([ 'mini.pdb', \@mini ], [ 'nmr.pdb', \@nmr ], [ 'bare.pdb', \@bare ],
           [ 'mini.cif', \@minicif ], [ 'nmr.cif', \@nmrcif ], [ 'bare.cif', \@barecif ],
           [ 'stack.pdb', \@stack ], [ 'stack.cif', \@stackcif ],
           [ 'bases.pdb', \@bases ], [ 'bases.cif', \@basescif ],
           [ 'rna.pdb', \@rna ], [ 'rna.cif', \@rnacif ],
           [ 'aform.pdb', \@aform ], [ 'aform.cif', \@aformcif ],
           [ 'duplex.pdb', \@duplex ], [ 'duplex.cif', \@duplexcif ],
           [ 'wobble.pdb', \@wobble ], [ 'wobble.cif', \@wobblecif ],
           [ 'ss.pdb', \@ss ], [ 'ss.cif', \@sscif ],
           [ 'fold.pdb', \@fold ], [ 'fold.cif', \@foldcif ],
           [ 'sheet.pdb', \@sheet ], [ 'sheet.cif', \@sheetcif ],
           [ 'ensemble.pdb', \@ensemble ], [ 'ensemble.cif', \@enscif ],
           [ 'quirks.cif', \@quirks ]) {
	open my $fh, '>', $f->[0];
	print {$fh} "$_\n" for @{ $f->[1] };
	close $fh;
	print "wrote $f->[0] (" . scalar(@{ $f->[1] }) . " lines)\n";
}

# an empty file is a legitimate thing to be handed, and must not die
open my $e, '>', 'empty.pdb';
close $e;
print "wrote empty.pdb\n";
open my $ec, '>', 'empty.cif';
close $ec;
print "wrote empty.cif\n";
