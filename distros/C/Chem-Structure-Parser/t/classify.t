#!/usr/bin/env perl
# Two residues that are not what their names say they are.
#
# Both of these came out of running the module over the 10,116 entries of
# PDBbind v2020 and asking where the sequence it read disagreed with the
# SEQRES the file declared.  Both are cases where the same three letters mean
# two different things, and only the atoms or their place in the chain say
# which.
#
# Where a chain's polymer ends is gemmi's rule: have_peptide_bond() and
# have_nucleotide_bond() in gemmi 0.7.0's polyheur.hpp, C to N within
# 1.341 * 1.5 A and O3' to P within 1.6 * 1.5 A.  The free residues it is
# tested with are 1hsl's HIS 239, numbered one past its chain as though it
# continued it, and 3lms's GLY 501, which falls inside a chain numbered 4, 567,
# 1501, 1889; both sit after the chain's TER record, which is gemmi's reason
# for calling them non-polymer when it reads the PDB file.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Chem::Structure::Parser;
use Test::More;

# a residue's worth of ATOM/HETATM records, in the right columns
sub atoms {
	my ($record, $chain, $resname, $resseq, @names) = @_;
	my $out = '';
	my $serial = 0;
	for my $n (@names) {
		$serial++;
		my $name = length($n) == 4 ? $n : sprintf(' %-3s', $n);
		my ($el) = $n =~ /([A-Z])/;
		$out .= sprintf("%-6s%5d %-4s %3s %1s%4d    %8.3f%8.3f%8.3f%6.2f%6.2f          %2s\n",
			$record, $serial, $name, $resname, $chain, $resseq,
			$serial, $serial + 1, $serial + 2, 1, 20, $el);
	}
	return $out;
}

# A run of residues laid end to end along x, each one bonded to the next the
# way a real chain is: the C of one 1.33 A from the N of the next, and the O3'
# of a nucleotide 1.6 A from the next one's P.  Each entry is
# [record, resname, resseq, kind], kind being 'aa' or 'nt'; $gap puts that
# many angstrom of empty space before the residue it is given with, which is
# how a residue that is not bonded to the one before it is written.
sub bonded {
	my ($chain, @res) = @_;
	my ($out, $serial, $at) = ('', 0, 0);
	for my $r (@res) {
		my ($record, $resname, $resseq, $kind, $gap) = @$r;
		$at += $gap || 0;
		my @a = $kind eq 'nt'
		      ? ([ 'P', 0, 0 ], [ "C1'", 2.2, 1.5 ], [ "O3'", 4.4, 0 ])
		      : ([ 'N', 0, 0 ], [ 'CA', 1.46, 0 ], [ 'C', 2.47, 0 ], [ 'O', 2.47, 1.23 ]);
		for my $x (@a) {
			$serial++;
			my ($el) = $x->[0] =~ /([A-Z])/;
			$out .= sprintf("%-6s%5d %-4s %3s %1s%4d    %8.3f%8.3f%8.3f%6.2f%6.2f          %2s\n",
				$record, $serial, ' ' . $x->[0], $resname, $chain, $resseq,
				$at + $x->[1], $x->[2], 0, 1, 20, $el);
		}
		$at += $kind eq 'nt' ? 6.0 : 3.8;
	}
	return $out;
}

#--------
# ADE, CYT, GUA, THY and URI are the nucleotides of a nucleic acid chain in a
# file written before 2007, and free bases bound in a site in one written
# since.  The sugar tells them apart.
#--------
{
	# a free guanine: the base and nothing else, as in 1czc
	my $free = structure_info_string(
		atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'ALA', 2, qw(N CA C O)) .
		atoms('HETATM', 'A', 'GUA', 501, qw(N1 C2 N2 N3 C4 C5 C6 O6 N7 C8 N9))
	);
	is($free->{chains}{A}{residues}{501}{type}, 'ligand',
		'a GUA with no sugar is a free base, and a ligand');
	is($free->{chains}{A}{residues}{501}{one}, '',
		'so it has no single-letter code');
	is($free->{chains}{A}{sequence}, 'MA',
		'and it stays out of the protein sequence it was bound to');

	# the same name with a sugar on it: a real nucleotide, as in a pre-v3 file
	my $nuc = structure_info_string(
		atoms('ATOM  ', 'B', 'ADE', 1, qw(P OP1 C1* N9 C4)) .
		atoms('ATOM  ', 'B', 'GUA', 2, qw(P OP1 C1* N9 C4)) .
		atoms('ATOM  ', 'B', 'CYT', 3, qw(P OP1 C1* N1 C2))
	);
	is($nuc->{chains}{B}{residues}{2}{type}, 'nucleotide',
		'a GUA with a sugar is a nucleotide');
	is($nuc->{chains}{B}{sequence}, 'AGC', 'and reads as part of the sequence');
	is($nuc->{chains}{B}{type}, 'rna', 'in a chain that is nucleic acid');

	# the modern spelling is never ambiguous and is not put through the test
	my $dna = structure_info_string(
		atoms('ATOM  ', 'C', 'DA', 1, qw(N9 C4)) .
		atoms('ATOM  ', 'C', 'DG', 2, qw(N9 C4))
	);
	is($dna->{chains}{C}{sequence}, 'AG',
		'DA and DG are nucleotides whether or not the sugar was modelled');
}

#--------
# A HETATM residue with an amino acid's name is a modified residue when it is
# part of the polymer, and a free amino acid bound in a site when it comes
# after the polymer's end without being bonded to it.
#--------
{
	# MSE at position 3 of a chain that runs 1..5: a modified residue
	my $mod = structure_info_string(
		atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'ALA', 2, qw(N CA C O)) .
		atoms('HETATM', 'A', 'MSE', 3, qw(N CA C O SE)) .
		atoms('ATOM  ', 'A', 'GLY', 4, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'SER', 5, qw(N CA C O))
	);
	is($mod->{chains}{A}{residues}{3}{type}, 'amino_acid',
		'a HETATM amino acid inside the polymer is a modified residue');
	is($mod->{chains}{A}{residues}{3}{modified}, 1, 'and is flagged as modified');
	ok(!$mod->{chains}{A}{residues}{3}{free}, 'and not as free');
	is($mod->{chains}{A}{sequence}, 'MAMGS', 'and it counts in the sequence');

	# a glycine at 501 after a chain that runs 1..4: a free amino acid
	my $free = structure_info_string(
		atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'ALA', 2, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'GLY', 3, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'SER', 4, qw(N CA C O)) .
		atoms('HETATM', 'A', 'GLY', 501, qw(N CA C O))
	);
	is($free->{chains}{A}{residues}{501}{type}, 'ligand',
		'a HETATM amino acid after the polymer is a free amino acid');
	is($free->{chains}{A}{residues}{501}{free}, 1, 'and is flagged free');
	is($free->{chains}{A}{sequence}, 'MAGS',
		'and does not lengthen the chain it was bound to');
	ok(exists structure_ligands($free)->{GLY_A_501}, 'it turns up among the ligands instead');

	# 3lms: the free glycine is numbered inside the polymer's numbering,
	# because the chain runs 4, 567, 1501 -- the number says nothing
	my $lms = structure_info_string(bonded('A',
		[ 'ATOM  ', 'ALA', 4,    'aa' ],
		[ 'ATOM  ', 'GLN', 567,  'aa' ],
		[ 'ATOM  ', 'VAL', 1501, 'aa' ],
		[ 'HETATM', 'GLY', 501,  'aa', 20 ],
	));
	is($lms->{chains}{A}{residues}{501}{free}, 1,
		'a free amino acid numbered inside the chain\'s numbering is still free');
	is($lms->{chains}{A}{sequence}, 'AQV', 'and stays out of the sequence');

	# 1hsl: a free histidine numbered one past the end, as though it
	# continued the chain, with ions between it and the chain
	my $hsl = structure_info_string(bonded('A',
		[ 'ATOM  ', 'GLY', 237, 'aa' ],
		[ 'ATOM  ', 'GLY', 238, 'aa' ],
		[ 'HETATM', 'HIS', 239, 'aa', 15 ],
	));
	is($hsl->{chains}{A}{residues}{239}{free}, 1,
		'a free amino acid numbered one past the chain is free when it is not bonded to it');
	is($hsl->{chains}{A}{sequence}, 'GG', 'and the chain is no longer than its polymer');

	# capping the terminus, bonded to the last ATOM residue, still counts
	# as part of the chain, and so does one bonded to that cap in turn
	my $cap = structure_info_string(bonded('A',
		[ 'ATOM  ', 'MET', 1, 'aa' ],
		[ 'ATOM  ', 'ALA', 2, 'aa' ],
		[ 'HETATM', 'MSE', 3, 'aa' ],
		[ 'HETATM', 'MSE', 4, 'aa' ],
		[ 'HETATM', 'GLY', 9, 'aa', 12 ],
	));
	is($cap->{chains}{A}{sequence}, 'MAMM',
		'modified residues bonded on after the last ATOM residue are still in the chain');
	is($cap->{chains}{A}{residues}{9}{free}, 1,
		'and the first residue after them that is not bonded ends it');

	# the same, read with atoms => 0, which finds the bond in the columns
	# rather than in the atom hashes
	my $cols = structure_info_string(bonded('A',
		[ 'ATOM  ', 'MET', 1, 'aa' ],
		[ 'HETATM', 'MSE', 2, 'aa' ],
		[ 'HETATM', 'GLY', 9, 'aa', 12 ],
	), atoms => 0);
	is($cols->{chains}{A}{sequence}, 'MM', 'atoms => 0 finds the same bond');
	is($cols->{chains}{A}{residues}{9}{free}, 1, 'and the same free residue');

	# a nucleotide is bonded O3' to P, not C to N
	my $nt = structure_info_string(bonded('B',
		[ 'ATOM  ', 'DA',  1, 'nt' ],
		[ 'ATOM  ', 'DG',  2, 'nt' ],
		[ 'HETATM', '7MG', 3, 'nt' ],
		[ 'HETATM', '7MG', 4, 'nt', 20 ],
	));
	is($nt->{chains}{B}{residues}{3}{type}, 'nucleotide',
		'a modified nucleotide bonded O3\' to P is part of the strand');
	is($nt->{chains}{B}{residues}{4}{free}, 1,
		'and one that is not bonded to it is free');

	# a peptide written entirely as HETATM has no ATOM polymer to end, and
	# reads as the peptide it is
	my $pep = structure_info_string(
		atoms('HETATM', 'P', 'ALA', 1, qw(N CA C O)) .
		atoms('HETATM', 'P', 'GLY', 2, qw(N CA C O)) .
		atoms('HETATM', 'P', 'TRP', 3, qw(N CA C O))
	);
	is($pep->{chains}{P}{sequence}, 'AGW',
		'a peptide written entirely as HETATM is still a peptide');
	is($pep->{chains}{P}{type}, 'protein', 'and its chain is a protein');
}

#--------
# ions and ligands
#--------
{
	my $i = structure_info_string(
		atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O)) .
		"HETATM   99 ZN    ZN A 201       1.000   1.000   1.000  1.00 20.00          ZN\n" .
		atoms('HETATM', 'A', 'HOH', 301, qw(O)) .
		atoms('HETATM', 'A', 'NAG', 401, qw(C1 C2 C3 O5 N2))
	);
	is($i->{chains}{A}{residues}{201}{type}, 'ion',   'a lone zinc is an ion');
	is($i->{chains}{A}{residues}{301}{type}, 'water', 'HOH is water');
	is($i->{chains}{A}{residues}{401}{type}, 'ligand','a sugar is a ligand');
	is_deeply([ sort keys %{ structure_ligands($i) } ], [ 'NAG_A_401', 'ZN_A_201' ],
		'the ion and the ligand are both bound heterogens; the water is not');
}

#--------
# what a chain of nothing but heterogens is called
#--------
{
	my $w = structure_info_string(
		atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O)) .
		atoms('HETATM', 'W', 'HOH', 1, qw(O)) .
		atoms('HETATM', 'W', 'HOH', 2, qw(O))
	);
	is($w->{chains}{W}{type}, 'water',
		'a chain of nothing but water is a water chain, not a heterogen one');
	is($w->{chains}{W}{n_water}, 2, 'with its waters counted');
	is($w->{chains}{A}{type}, 'protein', 'and the polymer beside it is unaffected');

	my $h = structure_info_string(
		atoms('HETATM', 'L', 'NAG', 1, qw(C1 C2 C3 O5 N2)) .
		atoms('HETATM', 'L', 'HOH', 2, qw(O))
	);
	is($h->{chains}{L}{type}, 'hetero',
		'a chain holding a ligand as well as water is a heterogen chain');
	is($h->{chains}{L}{n_ligand}, 1, 'and the ligand is counted as one');

	# the shape a caller walking chains wants out of the way: one residue, no
	# sequence.  is_single_ion() asks the shape and not the chemistry, so a
	# chain of one sugar answers as a chain of one zinc does.
	my $one = structure_info_string(
		atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'ALA', 2, qw(N CA C O)) .
		"HETATM   99 ZN    ZN Z 201       1.000   1.000   1.000  1.00 20.00          ZN\n"
	);
	ok(is_single_ion($one, 'Z'), 'a chain that is one zinc is a single ion');
	ok(!is_single_ion($one, 'A'), 'and a chain of two residues is not');
}

#--------
# the classification does not depend on the atom hashes
#
# atoms => 0 stops the parse at the residue level, and the two questions that
# read a residue's atoms -- is this GUA a nucleotide or a free base, and is
# this single-atom residue an ion -- then have to read the parse's own columns
# instead.  They are two roads to one answer and they must arrive at the same
# place, or a structure read for its sequences would classify differently from
# the same structure read whole.
#--------
{
	my $text = atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O))
	         . atoms('HETATM', 'A', 'GUA', 501, qw(N1 C2 N2 N3 C4 C5 C6 O6 N7 C8 N9))
	         . atoms('ATOM  ', 'B', 'ADE', 1, qw(P OP1 C1* N9 C4))
	         . atoms('ATOM  ', 'B', 'GUA', 2, qw(P OP1 C1* N9 C4))
	         . "HETATM   99 ZN    ZN C 201       1.000   1.000   1.000  1.00 20.00          ZN\n";
	my $with = structure_info_string($text);
	my $bare = structure_info_string($text, atoms => 0);
	for my $cid (qw(A B C)) {
		is_deeply([ map { $bare->{chains}{$cid}{residues}{$_}{type} }
		            @{ $bare->{chains}{$cid}{residue_order} } ],
		          [ map { $with->{chains}{$cid}{residues}{$_}{type} }
		            @{ $with->{chains}{$cid}{residue_order} } ],
			"chain $cid: every residue types the same with atoms => 0");
		is($bare->{chains}{$cid}{sequence}, $with->{chains}{$cid}{sequence},
			"chain $cid: and the sequence is the same");
		is($bare->{chains}{$cid}{type}, $with->{chains}{$cid}{type},
			"chain $cid: and so is what the chain is");
	}
}

done_testing();
