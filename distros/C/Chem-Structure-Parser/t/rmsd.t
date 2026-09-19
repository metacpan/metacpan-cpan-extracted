#!/usr/bin/env perl
# structure_rmsd(): how far apart two copies of a molecule are.
#
# The numbers here are somebody else's.  Every RMSD this file asserts was
# computed by gemmi 0.7.5's C<gemmi.superpose_positions> over the same atoms,
# and the values are written out to seventeen figures below so that the
# comparison runs on a machine with no Python on it; t/data/ensemble.pdb is
# the fixture they were taken over, and t/data/generate.pl says where its
# coordinates came from (chain B of 1K9R, models 1 to 4, as deposited).
#
# Two more readers were used while this was written, and what they said is
# recorded here because it decided how the module computes its answer:
#
#  - Biopython 1.85's C<Bio.SVDSuperimposer> agrees with gemmi and with this
#    module to every figure printed.
#
#  - Biopython 1.85's C<Bio.PDB.qcprot.QCPSuperimposer> does not: over the 20
#    models of 2LL7 it reports 3.5022 A where all three of the others report
#    3.6090 A, about 3% low, and measuring with the rotation it returns itself
#    gives 3.60899.  Its Newton-Raphson stops on C<(mxEigenV - oldg) <
#    evalprec * mxEigenV>, without the absolute value qcprot.c has, and the
#    iterate approaches from above -- so the difference is negative, the test
#    is true on the first pass, and the eigenvalue it reads the RMSD off is one
#    Newton step from its starting guess.  This module iterates to the width of
#    an NV and does not read the RMSD off the eigenvalue at all, so neither
#    half of that applies here.  Nothing below asserts QCPSuperimposer's
#    numbers; they are written down so the next person to compare against it
#    knows what they are looking at.
#
#  - gemmi does read its RMSD off the eigenvalue, and models 24 and 25 of
#    1JM4 (PDBbind v2020) have byte-identical coordinates: gemmi answers
#    8.6e-07 A for them and this module answers 0.  That is the cancellation
#    qcp_rotation()'s comment argues about, seen in the wild, and it is why the
#    agreement below is asserted as a relative difference rather than as an
#    absolute one.
#
# Agreement measured: over every pair of models of the 40 NMR entries in the
# first 2,000 files of PDBbind v2020, 5,598 superpositions, the largest
# relative difference from gemmi is 5.65e-12 and the median 1.43e-14.  Over
# the fixture below it is 1.82e-13, the same on a double, a long double and a
# __float128 perl -- the same because what is left is gemmi's own double
# arithmetic, not this module's.  The tolerance is 1e-11, fifty times the
# worst seen.  Never widen it to make a failure go away.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

my $data = dirname(abs_path(__FILE__)) . '/data';

# see the header: 1.82e-13 observed over these, on all three NV widths
my $TOL = 1e-11;

# The working precision of this perl's NV, found rather than assumed: 2.2e-16
# on a double build, 1.1e-19 on a long double one, 1.9e-34 on a __float128
# one.  Used where two ways of computing the same answer differ only in the
# order the terms were added up, which is a difference of a few ulp and is a
# different size on each of the three.
my $EPS = do { my $e = 1; $e /= 2 while 1 + $e / 2 != 1; $e };

sub near {
	my ($got, $want, $name) = @_;
	if (!defined $got) { fail("$name (got undef, wanted $want)"); return }
	my $rel = $want == 0 ? abs($got) : abs($got - $want) / abs($want);
	ok($rel <= $TOL, $name) or diag("got $got, wanted $want, relative $rel");
}

#--------
# gemmi's answer for the fixture, by selection.
#
# Six pairs out of four models, in the order 1-2, 1-3, 1-4, 2-3, 2-4, 3-4, and
# the number of atoms each selection leaves to pair.  gemmi's own matrix is not
# quite symmetric -- 1-3 and 3-1 differ in its sixteenth figure, for the same
# reason the 1JM4 case above differs -- so the upper triangle is what is
# written down and both triangles are compared against it.
#--------
my %GEMMI = (
	all      => [ 89, qw(2.2003227714234876 2.0862526023190084 2.5447822514953127
	                     1.3283734020604274 1.8237111392713048 1.5072300524368913) ],
	heavy    => [ 45, qw(1.6848186088726795 1.7714835639565547 2.1912439101417296
	                     0.95458788141468998 1.3759956427468498 1.2602380178222323) ],
	backbone => [ 20, qw(1.070958810374385 1.3827882170005479 1.4152149505286853
	                     0.84153898441287978 0.72023288160588683 0.60941712036421314) ],
	ca       => [  5, qw(0.77985411679922234 0.94903176442328829 0.82704916472846257
	                     0.34114241200093498 0.4105494308886099 0.25623148111717642) ],
);
my @PAIR = ([0,1], [0,2], [0,3], [1,2], [1,3], [2,3]);

for my $fmt (qw(pdb cif)) {
	for my $sel (sort keys %GEMMI) {
		my ($n, @want) = @{ $GEMMI{$sel} };
		my $r = structure_rmsd("$data/ensemble.$fmt", model => 'all', select => $sel);
		is(scalar @{ $r->{labels} }, 4, "$fmt/$sel: four models make four structures");
		is($r->{n_atoms}[0], $n, "$fmt/$sel: and $n atoms to pair");
		is($r->{n}[0][1], $n, "$fmt/$sel: which is how many paired");
		for my $p (0 .. $#PAIR) {
			my ($i, $j) = @{ $PAIR[$p] };
			near($r->{rmsd}[$i][$j], $want[$p],
				"$fmt/$sel: models @{[$i+1]} and @{[$j+1]} are $want[$p] A apart, as gemmi has it");
			is($r->{rmsd}[$j][$i], $r->{rmsd}[$i][$j],
				"$fmt/$sel: and the matrix is symmetric at @{[$i+1]},@{[$j+1]}");
		}
		is($r->{rmsd}[$_][$_], 0, "$fmt/$sel: a model against itself is 0") for 0 .. 3;
	}
}

#--------
# the two formats are one structure
#--------
{
	my $p = structure_rmsd("$data/ensemble.pdb", model => 'all');
	my $c = structure_rmsd("$data/ensemble.cif", model => 'all');
	is_deeply($p->{rmsd}, $c->{rmsd},
		'the same ensemble read as PDB and as mmCIF gives the same matrix, to the bit');
	is(structure_rmsd("$data/ensemble.pdb", "$data/ensemble.cif"), 0,
		'and one read against the other is exactly zero');
}

#--------
# every way of naming what to compare
#--------
{
	my $a = structure_info("$data/ensemble.pdb", model => 1, features => 0);
	my $b = structure_info("$data/ensemble.pdb", model => 2, features => 0);
	my $want = $GEMMI{all}[1];

	near(structure_rmsd($a, $b), $want, 'two structures already read');
	near(structure_rmsd($a, "$data/ensemble.pdb", model => 2), $want,
		'a structure and a file name');
	near(structure_rmsd("$data/ensemble.pdb", $b, model => 1), $want,
		'a file name and a structure');
	near(structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", model => 1), 0,
		'two file names, and the same file twice is zero');

	# one file that holds the ensemble, which is the NMR case
	my $one = structure_rmsd("$data/ensemble.pdb", model => 'all');
	near($one->{rmsd}[0][1], $want, 'one file read with every model');
	my $info = structure_info("$data/ensemble.pdb", model => 'all', features => 0);
	my $two = structure_rmsd($info);
	is_deeply($two->{rmsd}, $one->{rmsd},
		'and the same structure handed over already read says the same');
	like($one->{labels}[2], qr/ensemble\.pdb model 3\z/,
		'a model of an ensemble is labelled by its file and its number');

	# more than two, from more than one place
	my $three = structure_rmsd($a, $b, "$data/ensemble.pdb", model => 3);
	is(scalar @{ $three->{labels} }, 3, 'three structures from three arguments');
	near($three->{rmsd}[0][1], $want, 'and every pair of them is measured');
	near($three->{rmsd}[0][2], $GEMMI{all}[2], 'including the second pair');
	near($three->{rmsd}[1][2], $GEMMI{all}[4], 'and the third');
}

#--------
# what comes back: a number for two, a matrix for more, the whole hash on
# request
#--------
{
	my $r = structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb",
	                       model => 1, detail => 1);
	ok(!ref $r->{rmsd}, 'detail => 1 over two structures gives one number, not a matrix');
	is($r->{n}, 89, 'and the count of what paired');
	is_deeply($r->{n_atoms}, [ 89, 89 ], 'and what each had to pair');
	is($r->{fit}, 1, 'and says the fit was done');
	is($r->{select}, 'all', 'and which atoms took part');
	is($r->{match}, 'key', 'and how they were matched');

	my $m = structure_rmsd("$data/ensemble.pdb", model => 'all', detail => 1);
	is(ref $m->{rmsd}, 'ARRAY', 'more than two structures give the matrix whether asked or not');
	ok(!exists $m->{rotation}, 'and no single transform, because there is no single pair');
}

#--------
# the transform.
#
# It is returned as b = rot . a + tran, so the test is to apply it: the
# deviation measured in Perl from the transformed coordinates has to be the
# number the module returned.  A rotation matrix also has to be one -- its
# rows orthonormal and its determinant +1, not -1, because a reflection would
# superpose a molecule on its mirror image and give a smaller RMSD than any
# real move can.
#--------
{
	my $d = structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb",
	                       detail => 1, model => 1);
	# the same file twice: the move is the identity and the deviation is zero
	is($d->{rmsd}, 0, 'a structure against a second reading of itself is exactly zero');

	my $a = structure_info("$data/ensemble.pdb", model => 1, features => 0);
	my $b = structure_info("$data/ensemble.pdb", model => 2, features => 0);
	my $r = structure_rmsd($a, $b, detail => 1);
	my $rot = $r->{rotation};
	my $tran = $r->{translation};
	is(scalar @$rot, 3, 'the rotation is three rows');
	is(scalar @{ $rot->[0] }, 3, 'of three');
	is(scalar @$tran, 3, 'and the translation is a vector');

	# orthonormal rows, and det +1.  The tolerance is the same 1e-11: the
	# entries are built out of a normalised quaternion, so what is left is
	# rounding in the nine products.
	for my $i (0 .. 2) {
		for my $j (0 .. 2) {
			my $dot = 0;
			$dot += $rot->[$i][$_] * $rot->[$j][$_] for 0 .. 2;
			my $want = $i == $j ? 1 : 0;
			ok(abs($dot - $want) < $TOL, "rotation rows $i and $j are orthonormal")
				or diag("dot $dot, wanted $want");
		}
	}
	my $det = $rot->[0][0] * ($rot->[1][1] * $rot->[2][2] - $rot->[1][2] * $rot->[2][1])
	        - $rot->[0][1] * ($rot->[1][0] * $rot->[2][2] - $rot->[1][2] * $rot->[2][0])
	        + $rot->[0][2] * ($rot->[1][0] * $rot->[2][1] - $rot->[1][1] * $rot->[2][0]);
	ok(abs($det - 1) < $TOL, 'and its determinant is +1: a rotation, never a reflection')
		or diag("determinant $det");

	# apply it, in Perl, and measure
	my ($sum, $n) = (0, 0);
	for my $cid (@{ $a->{chain_order} }) {
		for my $rk (@{ $a->{chains}{$cid}{residue_order} }) {
			my $ra = $a->{chains}{$cid}{residues}{$rk};
			my $rb = $b->{chains}{$cid}{residues}{$rk};
			for my $an (@{ $ra->{atom_order} }) {
				my $pa = $ra->{atoms}{$an};
				my $pb = $rb->{atoms}{$an} or next;
				my @p = ($pa->{x}, $pa->{y}, $pa->{z});
				for my $k (0 .. 2) {
					my $v = $tran->[$k];
					$v += $rot->[$k][$_] * $p[$_] for 0 .. 2;
					my $q = ($pb->{x}, $pb->{y}, $pb->{z})[$k];
					$sum += ($v - $q) ** 2;
				}
				$n++;
			}
		}
	}
	is($n, $r->{n}, 'the transform applies to every atom that paired');
	near(sqrt($sum / $n), $r->{rmsd},
		'and applying it reproduces the RMSD that came back');
}

#--------
# a rotation the test chose, recovered.
#
# Everything above compares against another implementation.  This one has an
# answer of its own: turn a structure by a known angle about z, and the fit
# has to undo it exactly -- zero deviation, and the rotation that comes back
# is the one that was applied.
#--------
{
	my $a = structure_info("$data/ensemble.pdb", model => 1, features => 0);
	my $b = structure_info("$data/ensemble.pdb", model => 1, features => 0);
	my $th = atan2(1, 1);                 # a quarter of pi, as exactly as an NV has it
	my ($c, $s) = (cos($th), sin($th));
	for my $cid (@{ $b->{chain_order} }) {
		for my $rk (@{ $b->{chains}{$cid}{residue_order} }) {
			my $res = $b->{chains}{$cid}{residues}{$rk};
			for my $an (@{ $res->{atom_order} }) {
				my $at = $res->{atoms}{$an};
				my ($x, $y) = ($at->{x}, $at->{y});
				$at->{x} = $c * $x - $s * $y;
				$at->{y} = $s * $x + $c * $y;
				$at->{z} += 10;           # and a translation, which the fit also undoes
			}
		}
	}
	my $r = structure_rmsd($a, $b, detail => 1);
	# Observed 4e-15 A on a double perl: the coordinates went through a cosine
	# and a sine in Perl and came back through nine products in C, and that is
	# what a few roundings of a ~20 A coordinate are worth.  1e-9 is the same
	# bound t/structure.t puts on a coordinate comparison.
	cmp_ok($r->{rmsd}, '<', 1e-9, 'a structure turned by a known angle fits back onto itself');
	my @want = ([ $c, -$s, 0 ], [ $s, $c, 0 ], [ 0, 0, 1 ]);
	for my $i (0 .. 2) {
		for my $j (0 .. 2) {
			ok(abs($r->{rotation}[$i][$j] - $want[$i][$j]) < 1e-9,
				"and the rotation that comes back is the one applied, at $i,$j")
				or diag("got $r->{rotation}[$i][$j], wanted $want[$i][$j]");
		}
	}
	ok(abs($r->{translation}[2] - 10) < 1e-8, 'and so is the translation');
}

#--------
# fit => 0: where they lie, not where they could lie
#--------
{
	# nmr.pdb's three models are one tripeptide moved a whole angstrom along x
	# per model, which is a rigid move and nothing else: the fit takes it out
	# exactly and without the fit it is the move itself.
	my $r = structure_rmsd("$data/nmr.pdb", model => 'all', fit => 0);
	is($r->{rmsd}[0][1], 1, 'without a fit, a model moved 1 A along x is 1 A away');
	is($r->{rmsd}[0][2], 2, 'and the next one 2 A');
	my $f = structure_rmsd("$data/nmr.pdb", model => 'all');
	is($f->{rmsd}[0][1], 0, 'and with the fit it is zero: a rigid move is all it was');
	is($f->{rmsd}[0][2], 0, 'for that one too');

	my $d = structure_rmsd("$data/nmr.pdb", "$data/nmr.pdb",
	                       model => 1, fit => 0, detail => 1);
	is($d->{fit}, 0, 'and the answer says the fit was not done');
	is_deeply($d->{rotation}, [ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ],
		'so the rotation it reports is the identity');
	is_deeply($d->{translation}, [ 0, 0, 0 ], 'and the translation is nothing');
}

#--------
# which atoms: the selections, and the option that does the same at read time
#--------
{
	# hydrogens => 0 throws them away as the file is read; select => 'heavy'
	# leaves them out of the pairing.  Different halves of the module, and they
	# have to agree.
	my $sel = structure_rmsd("$data/ensemble.pdb", model => 'all', select => 'heavy');
	my $opt = structure_rmsd("$data/ensemble.pdb", model => 'all', hydrogens => 0);
	is_deeply($opt->{rmsd}, $sel->{rmsd},
		"reading without hydrogens and selecting the heavy atoms are the same answer");
	is($opt->{n_atoms}[0], $sel->{n_atoms}[0], 'over the same number of atoms');

	# the selections nest: every backbone atom is heavy, every CA is backbone
	my %n = map { $_ => structure_rmsd("$data/ensemble.pdb", model => 'all',
	                                   select => $_)->{n_atoms}[0] } qw(all heavy backbone ca);
	cmp_ok($n{ca}, '<', $n{backbone}, 'fewer CA than backbone atoms');
	cmp_ok($n{backbone}, '<', $n{heavy}, 'fewer backbone atoms than heavy ones');
	cmp_ok($n{heavy}, '<', $n{all}, 'and fewer heavy atoms than atoms');
	is($n{ca}, 5, 'the ACE cap is not an amino acid, so it has no CA to select');
}

#--------
# match => 'order': the nth atom of each, for structures that do not share names
#--------
{
	my $key = structure_rmsd("$data/ensemble.pdb", model => 'all');
	my $ord = structure_rmsd("$data/ensemble.pdb", model => 'all', match => 'order');
	# The same atoms paired the same way, so the same answer -- but not to the
	# last bit: matching by key adds the deviations up in sorted order and
	# matching by position adds them up in the order the file wrote them, and a
	# sum of several hundred squares depends on the order it was taken in.
	# Measured over this fixture: 3 ulp, which is 6.7e-16 on a double perl,
	# 1.0e-19 on a long double one and 2.9e-34 on a __float128 one.  64 ulp is
	# twenty times that.
	for my $i (0 .. 3) {
		for my $j (0 .. 3) {
			next if $i == $j;
			my $d = abs($ord->{rmsd}[$i][$j] - $key->{rmsd}[$i][$j]) / $key->{rmsd}[$i][$j];
			ok($d <= 64 * $EPS,
				"an ensemble writes its atoms in the same order in every model, "
				. "so the two ways of pairing agree at @{[$i+1]},@{[$j+1]}")
				or diag("relative difference $d");
		}
	}

	# two structures with different numbers of atoms have no nth atom to pair
	my $r = structure_rmsd("$data/ensemble.pdb", "$data/mini.pdb",
	                       match => 'order', detail => 1);
	is($r->{n}, 0, 'two different structures pair nothing by position');
	is($r->{rmsd}, undef, 'and there is no RMSD to have');
}

#--------
# when there is no answer
#--------
{
	is(structure_rmsd("$data/ensemble.pdb", "$data/mini.pdb"), undef,
		'two structures with no atom in common have no RMSD');
	my $d = structure_rmsd("$data/ensemble.pdb", "$data/mini.pdb", detail => 1);
	is($d->{n}, 0, 'and the detail says so: nothing paired');

	# min_atoms is where "too few to mean anything" is drawn
	my $few = structure_rmsd("$data/ensemble.pdb", model => 'all',
	                         select => 'ca', min_atoms => 6);
	is($few->{rmsd}[0][1], undef, 'five CA is under a min_atoms of six');
	is($few->{n}[0][1], 5, 'though the count still says how many there were');
	my $ok = structure_rmsd("$data/ensemble.pdb", model => 'all',
	                        select => 'ca', min_atoms => 5);
	ok(defined $ok->{rmsd}[0][1], 'and five is enough at a min_atoms of five');
}

#--------
# chains: reading only some, and calling them by another name
#--------
{
	# mini.pdb has chains A and B; the ensemble has only B
	my $all = structure_rmsd("$data/mini.pdb", "$data/mini.cif", detail => 1);
	my $one = structure_rmsd("$data/mini.pdb", "$data/mini.cif",
	                         chains => ['A'], detail => 1);
	cmp_ok($one->{n}, '<', $all->{n}, 'chains => [A] pairs fewer atoms than the whole file');
	is($all->{rmsd}, 0, 'a file against its own mmCIF twin is zero');
	is($one->{rmsd}, 0, 'and so is one chain of it');

	# the same chain under two names.  Reading mini.pdb's chain A beside its
	# chain B pairs nothing, because a chain id is part of an atom's identity;
	# chain_map says which is which.
	my $a = structure_info("$data/mini.pdb", chains => ['A'], features => 0);
	my $b = structure_info("$data/mini.pdb", chains => ['B'], features => 0);
	my $bare = structure_rmsd($a, $b, detail => 1);
	is($bare->{n}, 0, 'two different chains pair nothing while they keep their names');
	my $mapped = structure_rmsd($a, $b, chain_map => { B => 'A' }, detail => 1);
	# they are a peptide and a DNA strand, so nothing pairs on residue and atom
	# name either; what the map has to do is stop the chain id being the reason
	is($mapped->{n}, 0, 'and renaming one onto the other does not invent a pairing');

	# a map that renames a chain onto itself is the same answer as no map
	my $self = structure_rmsd("$data/ensemble.pdb", "$data/ensemble.cif",
	                          chain_map => { B => 'B' }, detail => 1);
	is($self->{n}, 89, 'a chain_map that renames nothing pairs everything');
}

#--------
# nucleotides, and the two ways a prime is written
#--------
{
	# rna.pdb is an RNA strand, so the nucleic half of the backbone and CA
	# selections has something to pick.  What they should pick is countable
	# from the file itself, which is what they are checked against.
	my @BB = ("P", "O5'", "C5'", "C4'", "C3'", "O3'");
	my $info = structure_info("$data/rna.pdb", features => 0);
	my %n;
	for my $cid (@{ $info->{chain_order} }) {
		for my $rk (@{ $info->{chains}{$cid}{residue_order} }) {
			my $r = $info->{chains}{$cid}{residues}{$rk};
			next unless $r->{type} eq 'nucleotide';
			for my $an (@{ $r->{atom_order} }) {
				$n{ca}++       if $an eq 'P';
				$n{backbone}++ if grep { $an eq $_ } @BB;
			}
		}
	}
	is($n{ca}, 6, 'the RNA fixture has six nucleotides, so six phosphorus atoms');
	for my $sel (qw(ca backbone)) {
		my $r = structure_rmsd("$data/rna.pdb", "$data/rna.cif",
		                       select => $sel, detail => 1);
		is($r->{n_atoms}[0], $n{$sel},
			"select => '$sel' picks the $n{$sel} nucleic atoms the file has");
		is($r->{rmsd}, 0, "and the strand read both ways is zero from itself under '$sel'");
	}

	# An entry old enough to write O5* for O5' is the one the selection has to
	# read both spellings for.  Made from the fixture rather than typed, so
	# that the atom name stays in columns 13 to 16 -- which is the whole
	# difficulty with a PDB record.
	open my $fh, '<', "$data/rna.pdb"
		or die "Can't open '$data/rna.pdb' with mode '<': '$!'";
	my @lines = <$fh>;
	close $fh or die "Can't close '$data/rna.pdb': '$!'";
	for my $l (@lines) {
		next unless $l =~ /\A(?:ATOM  |HETATM)/;
		my $name = substr($l, 12, 4);
		$name =~ tr/'/*/;
		substr($l, 12, 4) = $name;
	}
	my $star = structure_info_string(join('', @lines), features => 0);
	my $first = $star->{chains}{A}{residues}{ $star->{chains}{A}{residue_order}[0] };
	is($first->{atom_order}[0], 'P',
		'the star-primed copy still starts its first nucleotide at P');
	ok((grep { /\*/ } @{ $first->{atom_order} }),
		'and its other backbone atoms are spelled with a star');
	for my $sel (qw(ca backbone)) {
		my $r = structure_rmsd($star, $star, select => $sel, detail => 1);
		is($r->{n_atoms}[0], $n{$sel},
			"select => '$sel' picks the same atoms when the primes are written as stars");
	}
	# paired by name the two spellings share only P; by position they are the
	# same atoms in the same order, and the coordinates never moved
	my $byname = structure_rmsd($info, $star, select => 'backbone', detail => 1);
	is($byname->{n}, 6, 'by name, O5* and O5\' are two different atoms and only P pairs');
	my $byorder = structure_rmsd($info, $star, select => 'backbone',
	                             match => 'order', detail => 1);
	is($byorder->{n}, $n{backbone}, 'by position, every backbone atom pairs');
	is($byorder->{rmsd}, 0, 'and nothing moved, so they are zero apart');
}

#--------
# structures this module's own reader cannot produce.
#
# A residue's atoms are filed by name, so the reader cannot give one two atoms
# of the same name, or an atom with no name at all.  Something that assembled a
# structure elsewhere can, and the answer has to be defined for it: an
# ambiguous name is passed over rather than paired arbitrarily, and a nameless
# atom has no identity to pair on.
#--------
{
	my $mk = sub {
		my ($order, @xyz) = @_;
		my (%atoms, %seen);
		my $i = 0;
		for my $name (@$order) {
			$i++;
			next if $seen{$name}++;
			$atoms{$name} = {
				(length $name ? (name => $name) : ()),
				element => 'C',
				x => $xyz[0] + $i, y => $xyz[1] + 2 * $i, z => $xyz[2] + 3 * $i,
			};
		}
		return {
			chain_order => ['A'],
			chains => { A => {
				id => 'A', n_atoms => scalar @$order,
				residue_order => [ 1 ],
				residues => { 1 => {
					key => 1, resname => 'ALA', standard => 1, one => 'A',
					atom_order => $order, atoms => \%atoms,
				} },
			} },
		};
	};

	# 'CA' twice in the atom_order and once in the atoms hash is two rows with
	# one key: neither is paired, and N and C are
	my $dup = $mk->([ qw(N CA CA C) ], 0, 0, 0);
	my $ok  = $mk->([ qw(N CA C) ], 0, 0, 0);
	my $r = structure_rmsd($dup, $ok, min_atoms => 1, detail => 1);
	is($r->{n_atoms}[0], 4, 'the duplicated name is two atoms to pair with');
	is($r->{n}, 2, 'but an ambiguous name pairs with nothing: only N and C do');

	# an atom hash with no name in it
	my $noname = $mk->([ '', 'N', 'C' ], 0, 0, 0);
	my $s = structure_rmsd($noname, $ok, min_atoms => 1, detail => 1);
	is($s->{n_atoms}[0], 2, 'an atom with no name is not an atom the pairing can see');
	is($s->{n}, 2, 'and the two that have one still pair');

	# one atom each: there is no rotation to find, and the fit is the
	# translation that puts the one on the other
	my $one = $mk->([ 'CA' ], 0, 0, 0);
	my $two = $mk->([ 'CA' ], 5, 7, 9);
	my $d = structure_rmsd($one, $two, min_atoms => 1, detail => 1);
	is($d->{n}, 1, 'one atom pairs with one atom');
	is($d->{rmsd}, 0, 'and one point always fits exactly onto another');
	is_deeply($d->{rotation}, [ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ],
		'with the identity for a rotation, because there is none to find');
	is_deeply($d->{translation}, [ 5, 7, 9 ], 'and the move between them for a translation');
	is(structure_rmsd($one, $two), undef,
		'and at the default min_atoms of three there is no answer at all');
}

#--------
# _rmsd() reached directly, which is where the XS has to check for itself
#--------
{
	my $a = structure_info("$data/nmr.pdb", model => 1, features => 0);
	my $b = structure_info("$data/nmr.pdb", model => 2, features => 0);
	throws_ok { Chem::Structure::Parser::_rmsd([ $a, 'not a structure' ], {}) }
		qr/structure 2 is not a hash reference/,
		'the XS names which of the structures it could not read';
	throws_ok { Chem::Structure::Parser::_rmsd([ $a, $b ], { select => 'sidechain' }) }
		qr/select must be 'all', 'heavy', 'backbone' or 'ca'/,
		'and checks the selection itself rather than trusting Perl to have done it';
	throws_ok { Chem::Structure::Parser::_rmsd([ $a, $b ], { match => 'sequence' }) }
		qr/match must be 'key' or 'order'/, 'and the matching rule';
	throws_ok { Chem::Structure::Parser::_rmsd([ $a, $b ], { min_atoms => 0 }) }
		qr/min_atoms must be at least 1/, 'and min_atoms';
	throws_ok { Chem::Structure::Parser::_rmsd([ $a ], {}) }
		qr/nothing to compare/, 'and that there are two of them';
	throws_ok { Chem::Structure::Parser::_rmsd({}, {}) }
		qr/must be an array reference/, 'and that it was handed a list at all';
	throws_ok { Chem::Structure::Parser::_rmsd([ $a, $b ], 'not a hashref') }
		qr/options must be a hash reference/, 'and a hash of options';
}

#--------
# the argument list, and what is wrong with it
#--------
{
	throws_ok { structure_rmsd() } qr/nothing to compare/,
		'no arguments at all';
	throws_ok { structure_rmsd(fit => 0) } qr/nothing to compare/,
		'options and no structures';
	throws_ok { structure_rmsd("$data/ensemble.pdb") }
		qr/only one structure to compare/,
		'one structure is not two';
	throws_ok { structure_rmsd("$data/ensemble.pdb") } qr/model => 'all'/,
		'and the message says how an ensemble is compared with itself';
	throws_ok { structure_rmsd(structure_info("$data/mini.pdb", features => 0)) }
		qr/only one structure to compare/,
		'one structure already read is not two either';

	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/no.such.file.pdb") }
		qr/is not a file that exists/,
		'a file name that does not exist is not quietly read as an option';
	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", 'fit') }
		qr/is not a file that exists/,
		'and neither is an option with no value after it';

	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", fitt => 0) }
		qr/unknown option 'fitt'/, 'a misspelled option is a mistake, not a default';
	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", select => 'sidechain') }
		qr/select must be/, 'a selection that does not exist';
	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", match => 'sequence') }
		qr/match must be/, 'a matching rule that does not exist';
	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", min_atoms => 0) }
		qr/min_atoms must be/, 'a min_atoms of nothing';
	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", min_atoms => 'three') }
		qr/min_atoms must be/, 'or of a word';
	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", chain_map => ['B','A']) }
		qr/chain_map must be a hash reference/, 'a chain_map that is not a map';
	throws_ok { structure_rmsd("$data/mini.pdb", "$data/mini.pdb",
	                           chain_map => { A => 'X', B => 'X' }) }
		qr/two chains cannot become one chain/, 'a chain_map that collapses two chains';
	throws_ok { structure_rmsd("$data/ensemble.pdb", "$data/ensemble.pdb", chains => 'B') }
		qr/chains must be an array reference/, 'a chains list that is not a list';

	throws_ok { structure_rmsd([], {}) }
		qr/expected the hash reference from structure_info/,
		'a reference that is not a structure';
	throws_ok {
		structure_rmsd(structure_info("$data/mini.pdb", atoms => 0),
		               structure_info("$data/mini.pdb", atoms => 0))
	} qr/no atom hashes to work from/,
		'a structure read with atoms => 0 has nothing to measure';
}

#--------
# an empty structure, which is a file with no atoms in it
#--------
{
	my $e = structure_rmsd("$data/empty.pdb", "$data/empty.pdb", detail => 1);
	is($e->{n}, 0, 'two empty files pair nothing');
	is($e->{rmsd}, undef, 'and have no RMSD between them');
	is(structure_rmsd("$data/empty.pdb", "$data/ensemble.pdb", model => 1), undef,
		'and an empty file against a real one has none either');
}

done_testing();
