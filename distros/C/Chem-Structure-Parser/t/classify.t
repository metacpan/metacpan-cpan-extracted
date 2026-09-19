#!/usr/bin/env perl
# Two residues that are not what their names say they are.
#
# Both of these came out of running the module over the 10,116 entries of
# PDBbind v2020 and asking where the sequence it read disagreed with the
# SEQRES the file declared.  Both are cases where the same three letters mean
# two different things, and only the atoms or the numbering say which.
require 5.010;
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
# numbered among the polymer, and a free amino acid bound in a site when it is
# numbered out with the ligands.
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
		'a HETATM amino acid numbered among the polymer is a modified residue');
	is($mod->{chains}{A}{residues}{3}{modified}, 1, 'and is flagged as modified');
	ok(!$mod->{chains}{A}{residues}{3}{free}, 'and not as free');
	is($mod->{chains}{A}{sequence}, 'MAMGS', 'and it counts in the sequence');

	# a glycine at 501 of a chain that runs 1..5: a free amino acid, as in 3lms
	my $free = structure_info_string(
		atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'ALA', 2, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'GLY', 3, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'SER', 4, qw(N CA C O)) .
		atoms('HETATM', 'A', 'GLY', 501, qw(N CA C O))
	);
	is($free->{chains}{A}{residues}{501}{type}, 'ligand',
		'a HETATM amino acid numbered out with the ligands is a free amino acid');
	is($free->{chains}{A}{residues}{501}{free}, 1, 'and is flagged free');
	is($free->{chains}{A}{sequence}, 'MAGS',
		'and does not lengthen the chain it was bound to');
	ok(exists structure_ligands($free)->{GLY_A_501}, 'it turns up among the ligands instead');

	# capping the terminus, one past the end, still counts as part of the chain
	my $cap = structure_info_string(
		atoms('ATOM  ', 'A', 'MET', 1, qw(N CA C O)) .
		atoms('ATOM  ', 'A', 'ALA', 2, qw(N CA C O)) .
		atoms('HETATM', 'A', 'MSE', 3, qw(N CA C O SE))
	);
	is($cap->{chains}{A}{sequence}, 'MAM',
		'a modified residue one past the last ATOM residue is still in the chain');

	# a peptide written entirely as HETATM has no polymer range to be outside
	# of, and reads as the peptide it is
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
