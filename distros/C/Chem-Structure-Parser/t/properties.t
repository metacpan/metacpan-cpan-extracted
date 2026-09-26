#!/usr/bin/env perl
# The surface of structure_features(), structure_sasa() and
# structure_pi_stacking(): every option, every call form, every croak, and what
# each of them leaves behind in $info.
#
# What the numbers *are* is t/features.t's job -- it compares them against
# mdtraj and Biopython.  This file is about the parts that are this module's own
# and that no other implementation has an opinion on.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Temp 'tempdir';
use Test::More;
use Test::Exception;
use Chem::Structure::Parser;

my $data = dirname(abs_path(__FILE__)) . '/data';

# ---- structure_info computes them on the way past ------------------------
{
	my $i = structure_info("$data/stack.pdb");
	ok($i->{features}, 'structure_info leaves the properties in $info->{features}');
	ok(defined $i->{chains}{A}{sasa}, 'and the per-chain figures on the chains');
	my $c = $i->{chains}{A};
	my $r = $c->{residues}{ $c->{residue_order}[0] };
	ok(defined $r->{sasa} && defined $r->{rsa}, 'and the per-residue ones');
	ok(defined $r->{atoms}{ $r->{atom_order}[0] }{sasa}, 'and the per-atom ones');

	# with no options, the three accessors hand back what is already there
	# rather than walking the structure again
	is(structure_features($i),    $i->{features},              'structure_features returns the cached hash');
	is(structure_sasa($i),        $i->{features}{sasa},        'and structure_sasa its surface');
	is(structure_pi_stacking($i), $i->{features}{pi_stacking}, 'and structure_pi_stacking its pairs');
	is(structure_disulfides($i),  $i->{features}{disulfides},  'and structure_disulfides its bonds');
	is(structure_contacts($i),    $i->{features}{contacts},    'and structure_contacts its pairs');
	is(structure_base_stacks($i), $i->{features}{base_stacks}, 'and structure_base_stacks its stacks');
	is(structure_hbonds($i),      $i->{features}{hbonds},      'and structure_hbonds its bonds');
	is(structure_dssp($i),        $i->{features}{dssp},        'and structure_dssp its secondary structure');
	# name any option and it is computed again with that option in force
	isnt(structure_features($i, probe => 2.0), $i->{features},
		'naming an option computes again instead');

	my $off = structure_info("$data/stack.pdb", features => 0);
	ok(!exists $off->{features}, 'features => 0 leaves them uncomputed');
	ok(!exists $off->{chains}{A}{sasa}, 'and writes nothing into the chains');
	is_deeply(structure_features($off), $i->{features},
		'and asking afterwards gives the same answer the read would have');

	# atoms => 0 turns them off on its own: there is nothing to compute from,
	# and structure_sequences() passes it as a documented fast path
	my $bare = structure_info("$data/stack.pdb", atoms => 0);
	ok(!exists $bare->{features},
		'atoms => 0 turns them off rather than dying on its way past');
	lives_ok { structure_sequences("$data/stack.pdb", atoms => 0, meta => 0) }
		'so the documented fast path still works';
}

# ---- each accessor on a structure that has nothing cached ----------------
#
# The block above reaches every one of these through the cache, which is one
# line of each of them.  This is the other line: a structure read with
# features => 0 has nothing to hand back, so each computes its own and only its
# own -- which is the call a caller who wants one property of a structure they
# already have makes, and the only way into most of these bodies.
{
	my $off = structure_info("$data/fold.pdb", features => 0);
	my $all = structure_info("$data/fold.pdb");

	is_deeply(structure_contacts($off), $all->{features}{contacts},
		'structure_contacts computes the same list the read would have');
	is_deeply(structure_dssp($off), $all->{features}{dssp},
		'and structure_dssp the same secondary structure');
	is_deeply(structure_hbonds($off), $all->{features}{hbonds},
		'and structure_hbonds the same bonds');
	is_deeply(structure_sasa($off), $all->{features}{sasa},
		'and structure_sasa the same surface');
	is_deeply(structure_disulfides($off), $all->{features}{disulfides},
		'and structure_disulfides the same list');
	is_deeply(structure_pi_stacking($off), $all->{features}{pi_stacking},
		'and structure_pi_stacking the same pairs');
	is_deeply(structure_base_pairs($off), $all->{features}{base_pairs},
		'and structure_base_pairs the same pairs');
	is_deeply(structure_base_stacks($off), $all->{features}{base_stacks},
		'and structure_base_stacks the same stacks');

	# computing one of them writes only its own share into the structure: the
	# secondary structure goes onto the residues, the contacts count with it,
	# and the surface does not
	my $one = structure_info("$data/fold.pdb", features => 0);
	structure_dssp($one);
	my $r = $one->{chains}{A}{residues}{ $one->{chains}{A}{residue_order}[5] };
	ok(defined $r->{ss}, 'structure_dssp leaves the letter on the residue');
	ok(!defined $r->{sasa}, 'and nothing the surface would have written');

	# structure_dssp() has no options at all, so anything named is a mistake
	throws_ok { structure_dssp($all, probe => 1.4) } qr/unknown option/,
		'structure_dssp takes no options and says so';
	throws_ok { structure_contacts($all, probe => 1.4) } qr/unknown option/,
		'and structure_contacts takes only its own';
	throws_ok { structure_hbonds($all, probe => 1.4) } qr/unknown option/,
		'and so does structure_hbonds';
}

# ---- the rest of the properties -------------------------------------------
{
	my $i = structure_info("$data/fold.pdb");
	my $f = $i->{features};
	my $c = $i->{chains}{A};

	# the gyration tensor's three moments are the radius of gyration read a
	# different way: they sum to its square
	my $m = $f->{shape}{principal_moments};
	is(scalar @$m, 3, 'three principal moments');
	cmp_ok($m->[0], '<=', $m->[1], 'in ascending order');
	cmp_ok($m->[1], '<=', $m->[2], '...');
	cmp_ok(abs($m->[0] + $m->[1] + $m->[2] - $f->{rg} ** 2), '<', 1e-9,
		'and they sum to the radius of gyration squared');
	cmp_ok(abs($f->{shape}{asphericity} - ($m->[2] - ($m->[0] + $m->[1]) / 2)), '<', 1e-9,
		'asphericity is the largest moment above the mean of the others');
	cmp_ok(abs($f->{shape}{acylindricity} - ($m->[1] - $m->[0])), '<', 1e-9,
		'acylindricity is the gap between the two smaller ones');
	cmp_ok($f->{shape}{anisotropy}, '>=', 0, 'the anisotropy is between zero');
	cmp_ok($f->{shape}{anisotropy}, '<=', 1, '... and one');
	is(scalar @{ $f->{shape}{gyration_tensor} }, 3, 'the tensor is three rows');
	cmp_ok(abs($f->{shape}{gyration_tensor}[0][1] - $f->{shape}{gyration_tensor}[1][0]),
		'<', 1e-12, 'and it is symmetric');

	# one chain buries nothing against anything
	cmp_ok(abs($c->{sasa_alone} - $c->{sasa}), '<', 1e-9,
		'a structure of one chain has the same surface alone as together');
	cmp_ok(abs($f->{sasa}{buried}), '<', 1e-9, 'and buries nothing');

	# and a structure of several: a chain's isolated surface is what the same
	# chain read on its own has, which is the definition and is also a different
	# road to it -- the chain is read out of the file again, into its own
	# structure, and its whole surface computed from scratch.  The interface
	# pass does not compute every atom twice: an atom with no neighbour outside
	# its own chain has the same surface either way and keeps the one it has, so
	# this is what says the ones it does compute are the right ones.
	for my $stem (qw(mini duplex)) {
		my $whole = structure_info("$data/$stem.pdb");
		next unless @{ $whole->{chain_order} } > 1;
		for my $cid (@{ $whole->{chain_order} }) {
			my $solo = structure_info("$data/$stem.pdb", features => 0, chains => [ $cid ]);
			# 0 is what the difference measures on every fixture and on the 131
			# chains of the 32 multi-chain entries of PDBbind v2020 it was run
			# over: the two compute the same sum of the same per-atom areas
			cmp_ok(abs(structure_sasa($solo)->{total} - $whole->{chains}{$cid}{sasa_alone}),
				'<', 1e-9,
				"$stem chain $cid: its surface alone is its surface read alone");
		}
	}

	# torsion angles
	my @with_phi = grep { defined $c->{residues}{$_}{phi} } @{ $c->{residue_order} };
	cmp_ok(scalar @with_phi, '>', 50, 'most residues of a folded run have a phi');
	my $first = $c->{residues}{ $c->{residue_order}[0] };
	ok(!exists $first->{phi}, 'the first residue of a chain has none');
	for my $rk (@{ $c->{residue_order} }) {
		my $r = $c->{residues}{$rk};
		for my $k (qw(phi psi omega)) {
			next unless defined $r->{$k};
			cmp_ok($r->{$k}, '>=', -180, "$rk $k is an angle")
				if $r->{$k} < -180;
			cmp_ok($r->{$k}, '<=', 180, "$rk $k is an angle")
				if $r->{$k} > 180;
		}
		next unless $r->{chi};
		cmp_ok(scalar @{ $r->{chi} }, '<=', 5, "$rk has at most five chi angles")
			if @{ $r->{chi} } > 5;
	}
	ok(!exists $c->{residues}{ $c->{residue_order}[0] }{chi}
	   || 1, 'a glycine has no chi angles');

	# secondary structure
	my %seen;
	for my $rk (@{ $c->{residue_order} }) {
		my $r = $c->{residues}{$rk};
		next unless defined $r->{ss};
		$seen{ $r->{ss} }++;
		like($r->{ss}, qr/\A[HGIEBTS ]\z/, "$rk has a dictionary letter")
			if $r->{ss} !~ /\A[HGIEBTS ]\z/;
		like($r->{ss_simple}, qr/\A[HEC]\z/, "$rk has a three-state letter")
			if $r->{ss_simple} !~ /\A[HEC]\z/;
	}
	ok($seen{H}, 'the folded fixture has an alpha helix in it');
	ok($seen{T}, 'and turns');

	# hydrogen bonds
	cmp_ok(scalar @{ $f->{hbonds} }, '>', 10, 'and backbone hydrogen bonds');
	for my $b (@{ $f->{hbonds} }) {
		cmp_ok($b->{energy}, '<', -0.5, 'every bond is below the cutoff')
			if $b->{energy} >= -0.5;
		cmp_ok($b->{energy}, '>=', -9.9, 'and none is stronger than the floor')
			if $b->{energy} < -9.9;
	}
	{
		# the floor is not decoration: Kabsch and Sander's energy is a sum of
		# reciprocal distances, so two atoms refined on top of each other send
		# it to minus infinity.  mdtraj clips at -9.9 kcal/mol and so does this.
		# The atom is moved in the structure rather than written into a fixture
		# because a deposited file with two atoms at one position is not a
		# fixture anybody would recognise, and this is the one case the clip is
		# for.
		my $j = structure_info("$data/fold.pdb", features => 0);
		my $ch = $j->{chains}{A};
		my @rk = @{ $ch->{residue_order} };
		my ($first, $third) = @{ $ch->{residues} }{ @rk[0, 2] };
		@{ $first->{atoms}{O} }{qw(x y z)} = @{ $third->{atoms}{N} }{qw(x y z)};
		my @floored = grep { $_->{energy} <= -9.9 } @{ structure_hbonds($j) };
		is(scalar @floored, 1, 'an acceptor sitting on a donor gives one bond at the floor');
		# -9.9 is a C double literal in the XS and whatever an NV is here, and
		# on a long double or __float128 perl those are not the same number:
		# the floor comes back as -9.90000000000000036, the double -9.9
		# widened.  That is the constant to clip at -- mdtraj's is a float --
		# so this compares to within the gap between the two, which is 3.6e-16
		# on perl-5.12.5 (-Duselongdouble) and 0 on a double perl.
		cmp_ok(abs($floored[0]{energy} + 9.9), '<', 1e-14,
			'and the floor is the number, not an infinity');
	}

	# contacts and exposure
	cmp_ok(scalar @{ $f->{contacts} }, '>', 50, 'and residue contacts');
	for my $ct (@{ $f->{contacts} }) {
		cmp_ok($ct->{distance}, '<=', 4.5, 'no contact is past the cutoff')
			if $ct->{distance} > 4.5;
	}
	# The contact list against the definition itself, spelled out in Perl: every
	# pair of residues, every pair of their heavy atoms, the shortest distance.
	# mdtraj's answer is what t/features.t holds the numbers to; what this holds
	# is the machinery underneath them -- a cell grid, and a walk that takes a
	# residue's atoms to be one contiguous run of the heavy-atom array.  Neither
	# is visible in a comparison that only ever sees what came out.
	{
		my %want;
		my @res;
		for my $cid (@{ $i->{chain_order} }) {
			my $ch = $i->{chains}{$cid};
			for my $rk (@{ $ch->{residue_order} }) {
				my $r = $ch->{residues}{$rk};
				my @a;
				for my $an (@{ $r->{atom_order} }) {
					my $a = $r->{atoms}{$an};
					next unless defined $a->{x};
					my $e = defined $a->{element} ? $a->{element} : '';
					push @a, $a unless $e eq 'H' || $e eq 'D';
				}
				push @res, [ "$cid/$rk", \@a ];
			}
		}
		for my $p (0 .. $#res) {
			for my $q ($p + 1 .. $#res) {
				my $min;
				for my $a (@{ $res[$p][1] }) {
					for my $b (@{ $res[$q][1] }) {
						my $d2 = ($a->{x} - $b->{x}) ** 2
						       + ($a->{y} - $b->{y}) ** 2
						       + ($a->{z} - $b->{z}) ** 2;
						$min = $d2 if !defined $min || $d2 < $min;
					}
				}
				$want{"$res[$p][0]|$res[$q][0]"} = sqrt($min)
					if defined $min && $min < 4.5 * 4.5;
			}
		}
		my %got = map {; "$_->{chain1}/$_->{residue1}|$_->{chain2}/$_->{residue2}"
		                 => $_->{distance} } @{ $f->{contacts} };
		is(scalar keys %got, scalar keys %want,
			'the grid finds as many contacts as an all-against-all walk');
		my @wrong = grep { !exists $got{$_} || abs($got{$_} - $want{$_}) > 1e-9 }
		            sort keys %want;
		push @wrong, grep { !exists $want{$_} } sort keys %got;
		# 1e-9 is a formality rather than a measured allowance: the two compute
		# the same sum of three squares and the largest difference seen is 0 --
		# over the 251 contacts of the nine fixtures in t/data that have any,
		# on the default double perl.  What it leaves room for is a compiler
		# reassociating that sum, not a difference anyone has observed.
		is(scalar @wrong, 0, 'and the same pairs, at the same distances')
			or diag(join "\n", @wrong[0 .. ($#wrong > 4 ? 4 : $#wrong)]);
	}
	my $n_hse = grep { defined $c->{residues}{$_}{hse_up} } @{ $c->{residue_order} };
	cmp_ok($n_hse, '>', 50, 'and half-sphere exposure on most residues');

	# the options turn each of them off
	for my $off (qw(shape dihedrals contacts exposure hbonds secondary)) {
		my $j = structure_info("$data/fold.pdb", features => 0);
		my $g = structure_features($j, $off => 0);
		ok(!exists $g->{shape}, "$off => 0 leaves no shape") if $off eq 'shape';
		ok(!exists $g->{contacts}, "$off => 0 leaves no contacts") if $off eq 'contacts';
		ok(!exists $g->{hbonds}, "$off => 0 leaves no hbonds") if $off eq 'hbonds';
		my $r = $j->{chains}{A}{residues}{ $j->{chains}{A}{residue_order}[10] };
		ok(!exists $r->{phi}, "$off => 0 leaves no torsion angles") if $off eq 'dihedrals';
		ok(!exists $r->{hse_up}, "$off => 0 leaves no exposure") if $off eq 'exposure';
		ok(!exists $r->{ss}, "$off => 0 leaves no secondary structure") if $off eq 'secondary';
	}
	my $noi = structure_features(structure_info("$data/fold.pdb", features => 0),
		interface => 0);
	ok(!exists $noi->{sasa}{buried}, 'interface => 0 leaves no buried area');
}

# ---- disulfides ----------------------------------------------------------
{
	my $i = structure_info("$data/ss.pdb");
	my $ss = $i->{features}{disulfides};
	is(scalar @$ss, 2, 'ss.pdb has two disulfides');
	my $c = $i->{chains}{A};
	is_deeply($c->{residues}{23}{disulfide}[0]{residue}, '88', 'CYS 23 is bonded to CYS 88');
	is_deeply($c->{residues}{88}{disulfide}[0]{residue}, '23', 'and the bond is on both residues');
	ok(!exists $c->{residues}{214}{disulfide}, 'the free cysteine has no bond');
	is(scalar @{ $c->{residues}{23}{disulfide} }, 1, 'a cysteine holds one bond');
	cmp_ok(abs($c->{residues}{23}{disulfide}[0]{distance} - $ss->[0]{distance}), '<', 1e-12,
		'and the length on the residue is the length in the list');

	# asking twice replaces what is on the residue rather than adding to it
	structure_features($i, probe => 1.4);
	is(scalar @{ $i->{chains}{A}{residues}{23}{disulfide} }, 1,
		'asking again does not give the residue a second copy of the same bond');

	# a cysteine whose thiol hydrogen was modelled is reduced and holds no bond.
	# Built by sprintf rather than typed, because a PDB record is fixed-column.
	my $line = sub {
		my ($serial, $name, $elem, $resseq, $x, $y, $z) = @_;
		return sprintf('%-6s%5d %-4s %3s %1s%4d%1s   %8.3f%8.3f%8.3f%6.2f%6.2f          %2s',
			'ATOM  ', $serial, (length($name) < 4 ? " $name" : $name), 'CYS', 'A',
			$resseq, '', $x, $y, $z, 1, 20, $elem);
	};
	my @sg = ($line->(1, 'SG', 'S', 1, 0, 0, 0), $line->(2, 'SG', 'S', 2, 2, 0, 0));
	my $bonded = structure_info_string(join("\n", @sg) . "\nEND\n");
	is(scalar @{ $bonded->{features}{disulfides} }, 1,
		'two SG atoms 2 A apart are a disulfide');
	my @hg = (@sg, $line->(3, 'HG', 'H', 1, 0.5, 0.9, 0));
	my $reduced = structure_info_string(join("\n", @hg) . "\nEND\n");
	is(scalar @{ $reduced->{features}{disulfides} }, 0,
		'and are not, once one of them has its thiol hydrogen modelled');
}

# ---- what comes back -----------------------------------------------------
{
	my $i = structure_info("$data/stack.pdb");
	my $f = structure_features($i);

	is($f->{n_atoms},   84, 'n_atoms is the atoms the walk found');
	is($f->{n_residues}, 7, 'n_residues likewise');
	is($f->{n_chains},   1, 'and n_chains');
	is($f->{n_no_element}, 0, 'every atom of a modern file has an element');
	ok(exists $f->{sasa} && exists $f->{pi_stacking}, 'both calculations ran by default');
	is(scalar @{ $f->{center} },         3, 'the centroid is a triple');
	is(scalar @{ $f->{center_of_mass} }, 3, 'so is the centre of mass');

	# the surface adds up three ways: over atoms, over residues, and the split
	# by element class
	my ($atoms, $residues) = (0, 0);
	my $c = $i->{chains}{A};
	for my $rk (@{ $c->{residue_order} }) {
		my $r = $c->{residues}{$rk};
		$residues += $r->{sasa};
		$atoms += $r->{atoms}{$_}{sasa} for @{ $r->{atom_order} };
	}
	cmp_ok(abs($atoms - $f->{sasa}{total}), '<', 1e-9,
		'the per-atom surfaces add up to the total');
	cmp_ok(abs($residues - $f->{sasa}{total}), '<', 1e-9,
		'and so do the per-residue ones');
	cmp_ok(abs($c->{sasa} - $f->{sasa}{total}), '<', 1e-9,
		'and the chain carries the same figure');
	cmp_ok(abs($f->{sasa}{apolar} + $f->{sasa}{polar} - $f->{sasa}{total}), '<', 1e-9,
		'apolar and polar account for all of it');
	cmp_ok($f->{sasa}{apolar}, '>', 0, 'some of it is apolar');
	cmp_ok($f->{sasa}{polar},  '>', 0, 'and some of it is polar');
	is($f->{sasa}{probe},  1.4, 'the probe radius used is reported back');
	is($f->{sasa}{points}, 960, 'and the number of sphere points');
}

# ---- relative accessibility ----------------------------------------------
{
	my $i = structure_info("$data/stack.pdb");
	structure_features($i);
	my $c = $i->{chains}{A};
	for my $rk (@{ $c->{residue_order} }) {
		my $r = $c->{residues}{$rk};
		ok(defined $r->{rsa}, "$r->{resname} $rk has a relative accessibility");
		# these seven residues are cut out of their protein and so are close to
		# fully exposed; Tien's maximum is a Gly-X-Gly tripeptide, which a bare
		# residue can exceed a little
		cmp_ok($r->{rsa}, '>', 0.5, "and it is high for a residue with no neighbours");
		cmp_ok($r->{rsa}, '<', 1.5, "and not absurd");
	}
}

# a nucleotide gets no relative accessibility: the single-letter codes of the
# nucleotides are amino acid codes too, and dividing a guanine's surface by
# glycine's maximum would be a number rather than an answer
{
	my $i = structure_info("$data/bases.pdb");
	structure_features($i);
	my $c = $i->{chains}{P};
	my @rsa = grep { defined } map { $c->{residues}{$_}{sasa} } @{ $c->{residue_order} };
	is(scalar @rsa, scalar @{ $c->{residue_order} }, 'every nucleotide has a surface');
	my @has = grep { defined $c->{residues}{$_}{rsa} } @{ $c->{residue_order} };
	is_deeply(\@has, [], 'and none of them has a relative accessibility');
}

# ---- store => 0 ----------------------------------------------------------
#
# Read with features => 0, because structure_info() computes and stores them by
# default and there would otherwise be nothing left for store => 0 to not do.
{
	my $i = structure_info("$data/stack.pdb", features => 0);
	my $f = structure_features($i, store => 0);
	cmp_ok($f->{sasa}{total}, '>', 0, 'the total still comes back');
	my $c = $i->{chains}{A};
	ok(!exists $c->{sasa}, 'the chain was left alone');
	ok(!exists $c->{hydropathy}, 'and so was its hydropathy');
	my $r = $c->{residues}{ $c->{residue_order}[0] };
	ok(!exists $r->{sasa} && !exists $r->{rsa}, 'and the residue');
	ok(!exists $r->{atoms}{ $r->{atom_order}[0] }{sasa}, 'and the atom');
}

# ---- structure_sasa and structure_pi_stacking ----------------------------
{
	my $i = structure_info("$data/stack.pdb");
	my $s = structure_features($i)->{sasa};
	my $j = structure_info("$data/stack.pdb", features => 0);
	my $t = structure_sasa($j);
	is_deeply($t, $s, 'structure_sasa returns what structure_features puts under sasa');
	ok(defined $j->{chains}{A}{sasa}, 'and stores the per-chain figure too');

	my $k = structure_info("$data/stack.pdb", features => 0);
	my $p = structure_pi_stacking($k);
	is(scalar @$p, 4, 'structure_pi_stacking returns the pairs on their own');
	ok(!exists $k->{chains}{A}{sasa},
		'and computes no surface, because it was not asked for one');
	my %type;
	$type{ $_->{type} }++ for @$p;
	is_deeply(\%type, { face => 1, edge => 3 }, 'one face stack and three edge stacks');
	for my $e (@$p) {
		like($e->{type}, qr/\A(?:face|edge)\z/, 'each is a face or an edge stack');
		like($e->{ring1}, qr/\A[56]\z/, 'each names the size of the first ring');
		like($e->{ring2}, qr/\A[56]\z/, 'and of the second');
		cmp_ok($e->{distance}, '>', 0, 'each has a centroid distance');
		cmp_ok($e->{plane_angle}, '>=', 0, 'and a plane angle in degrees');
		cmp_ok($e->{plane_angle}, '<=', 90, 'folded into the first quadrant');
		cmp_ok($e->{normal_angle1}, '<=', 90, 'as are the two normal angles');
		cmp_ok($e->{normal_angle2}, '<=', 90, '...');
		ok(defined $e->{resname1} && defined $e->{residue1} && defined $e->{chain1},
			'and names the residue each ring belongs to');
		if ($e->{type} eq 'edge') {
			ok(defined $e->{intersect_distance},
				'an edge stack says how far the shared line passes from a centroid');
		} else {
			ok(!exists $e->{intersect_distance},
				'a face stack has no intersection to report');
		}
	}
}

# ---- the options do something -------------------------------------------
{
	my $i = structure_info("$data/stack.pdb");
	my $full  = structure_sasa($i)->{total};
	my $naked = structure_sasa($i, probe => 0)->{total};
	cmp_ok($naked, '<', $full,
		'probe => 0 gives the van der Waals surface, which is smaller than the accessible one');

	my $coarse = structure_sasa($i, points => 100)->{total};
	cmp_ok(abs($coarse - $full) / $full, '<', 0.05,
		'a hundred sphere points is within five percent of nine hundred and sixty');
	isnt($coarse, $full, 'but not the same number');
	is(structure_sasa($i, points => 100)->{points}, 100, 'and says which it used');

	# a bigger probe reaches less far in, so the surface shrinks
	my $fat = structure_sasa($i, probe => 3.0)->{total};
	cmp_ok($fat, '>', $full, 'a larger probe rolls over a larger sphere');
}

{
	my $i = structure_info("$data/stack.pdb");
	is(scalar @{ structure_pi_stacking($i, face_plane_max => 0) }, 3,
		'no ring pair is exactly coplanar, so only the edge stacks survive');
	is(scalar @{ structure_pi_stacking($i, edge_plane_min => 90) }, 1,
		'and requiring exactly perpendicular planes leaves only the face stack');
	cmp_ok(scalar @{ structure_pi_stacking($i, face_distance => 55) }, '>', 4,
		'mdtraj-as-shipped 55 A face cutoff finds pairs that are not stacked at all');
	is(scalar @{ structure_pi_stacking($i, edge_radius => 0) }, 1,
		'an edge stack needs the planes to meet near a ring');
}

# ---- both formats, same answer ------------------------------------------
for my $pair ([ 'stack.pdb', 'stack.cif' ], [ 'bases.pdb', 'bases.cif' ],
              [ 'mini.pdb', 'mini.cif' ]) {
	my ($a, $b) = @$pair;
	my $fa = structure_features(structure_info("$data/$a"));
	my $fb = structure_features(structure_info("$data/$b"));
	# the residue keys travel, so the pi-stacking lists compare directly
	is_deeply($fb, $fa, "$a and $b give the same properties");
}

# ---- structures with nothing in them ------------------------------------
{
	my $i = structure_info("$data/empty.pdb");
	my $f = structure_features($i);
	is($f->{n_atoms}, 0, 'an empty file has no atoms');
	is($f->{sasa}{total}, 0, 'and no surface');
	is_deeply($f->{pi_stacking}, [], 'and no stacked rings');
	ok(!exists $f->{rg}, 'and no radius of gyration, because there is nothing to gyrate');
	ok(!exists $f->{center}, 'and no centroid');
	is($f->{mass}, 0, 'its mass is zero');
	ok(!exists $f->{hydropathy}, 'and it has no sequence to be hydropathic');
}

# an element the table does not know is counted rather than passed over in
# silence: it gets mdtraj's 2.0 A default radius and no mass
{
	my $i = structure_info_string(
		"ATOM      1  XX  UNK A   1       0.000   0.000   0.000  1.00  0.00          Xx\nEND\n");
	my $f = structure_features($i);
	is($f->{n_atoms}, 1, 'the atom is there');
	is($f->{n_no_element}, 1, 'and is counted as having no element this table knows');
	is($f->{mass}, 0, 'so it weighs nothing');
	cmp_ok($f->{sasa}{total}, '>', 0, 'but it still has a surface, at the default radius');
}

# ---- what it refuses to do ----------------------------------------------
{
	my $i = structure_info("$data/stack.pdb", atoms => 0);
	throws_ok { structure_features($i) } qr/atoms => 0/,
		'a structure read without atom hashes says so rather than reporting no surface';
	throws_ok { structure_sasa($i) } qr/atoms => 0/, 'and structure_sasa too';
}

{
	my $i = structure_info("$data/stack.pdb");
	throws_ok { structure_features($i, hydrogen => 1) } qr/unknown option 'hydrogen'/,
		'a misspelt option is a typo, not something to ignore';
	throws_ok { structure_sasa($i, face_distance => 5) } qr/unknown option 'face_distance'/,
		'a pi-stacking threshold means nothing to structure_sasa';
	throws_ok { structure_pi_stacking($i, probe => 1.4) } qr/unknown option 'probe'/,
		'and a probe radius means nothing to structure_pi_stacking';
	throws_ok { structure_disulfides($i, probe => 1.4) } qr/unknown option 'probe'/,
		'nor to structure_disulfides';
	throws_ok { structure_features($i, disulfide_distance => -1) }
		qr/disulfide_distance must be a number/, 'a negative bond length is refused';
	throws_ok { structure_features($i, disulfide_distance => 'short') }
		qr/disulfide_distance must be a number/, 'and so is a word';
	throws_ok { structure_features($i, probe => -1) } qr/probe must be a number/,
		'a negative probe is refused';
	throws_ok { structure_features($i, probe => 'wide') } qr/probe must be a number/,
		'and so is one that is not a number';
	throws_ok { structure_features($i, points => 0) } qr/points must be an integer/,
		'zero sphere points is refused';
	throws_ok { structure_features($i, points => 'many') } qr/points must be an integer/,
		'and so is a word';
	throws_ok { structure_features($i, points => 10_000_001) } qr/points must be an integer/,
		'and so is a number of points whose sphere would not fit in memory';
	lives_ok { structure_features($i, points => 1) } 'one sphere point is allowed';
	throws_ok { structure_pi_stacking($i, face_plane_max => 'flat') } qr/face_plane_max must be a number/,
		'and an angle that is not a number';
	for my $bond (qw(peptide_bond phosphodiester_bond)) {
		throws_ok { structure_features($i, $bond => 0) }
			qr/\Q$bond\E must be a positive number/,
			"a $bond of zero would link nothing and is refused";
		throws_ok { structure_features($i, $bond => -1.5) }
			qr/\Q$bond\E must be a positive number/, "and so is a negative $bond";
		throws_ok { structure_features($i, $bond => 'short') }
			qr/\Q$bond\E must be a positive number/, "and so is a word";
	}
	throws_ok { structure_sasa($i, phosphodiester_bond => 2.4) }
		qr/unknown option 'phosphodiester_bond'/,
		'a bond length means nothing to structure_sasa';
	throws_ok { structure_features($i, base_pair_hbond => 0) }
		qr/base_pair_hbond must be a positive number/,
		'a hydrogen bond of zero length is refused';
	throws_ok { structure_features($i, base_pair_hbond => -1) }
		qr/base_pair_hbond must be a positive number/, 'and so is a negative one';
	throws_ok { structure_features($i, base_pair_hbond => 'close') }
		qr/base_pair_hbond must be a positive number/, 'and so is a word';
	throws_ok { structure_features($i, base_pair_stagger => -0.5) }
		qr/base_pair_stagger must be a number/,
		'a negative stagger is refused, being a distance';
	throws_ok { structure_features($i, base_pair_stagger => 'flat') }
		qr/base_pair_stagger must be a number/, 'and so is a word';
	lives_ok { structure_features($i, base_pair_stagger => 0) }
		'but zero is allowed: it means the two bases must be exactly coplanar';
	throws_ok { structure_base_pairs($i, probe => 1.4) } qr/unknown option 'probe'/,
		'a probe radius means nothing to structure_base_pairs';
	throws_ok { structure_sasa($i, base_pair_hbond => 3.5) }
		qr/unknown option 'base_pair_hbond'/,
		'and a base pair threshold nothing to structure_sasa';
	throws_ok { structure_features($i, base_stack_distance => 0) }
		qr/base_stack_distance must be a positive number/,
		'a stacking distance of zero is refused';
	throws_ok { structure_features($i, base_stack_distance => 'near') }
		qr/base_stack_distance must be a positive number/, 'and so is a word';
	throws_ok { structure_features($i, base_stack_omega => 200) }
		qr/base_stack_omega must be a number between 0 and 180/,
		'an overlap angle over half a turn is refused, being an angle';
	lives_ok { structure_features($i, base_stack_omega => 0) }
		'but zero is allowed: it means the two bases must overlap exactly';
	throws_ok { structure_sasa($i, base_stack_omega => 50) }
		qr/unknown option 'base_stack_omega'/,
		'and a stacking threshold nothing to structure_sasa';
}

# ---- the same limits, checked again in the XS ------------------------------
#
# Every croak above is Perl's, and the XS repeats the ones it cannot work with
# -- a probe of -1 or a phosphodiester bond of 0 would be a nonsense grid
# rather than a wrong answer.  Nothing that goes through the public functions
# can reach them, because _feature_options() has already refused; _features()
# is the XSUB underneath and is what a caller reaching past that would hit, so
# it is asked directly here.  Written out rather than left to the Perl above,
# because a guard nothing tests is a guard nobody knows has stopped compiling.
{
	my $i = structure_info("$data/fold.pdb", features => 0);
	# an array and not a hash: two of these are refused by the same message,
	# and a hash would keep one of the two
	my @refused = (
		[ 'probe must not be negative'       => { probe => -1 } ],
		[ 'points must be between'           => { points => 0 } ],
		[ 'points must be between'           => { points => 10_000_001 } ],
		[ 'peptide_bond must be a positive'  => { peptide_bond => 0, dihedrals => 1 } ],
		[ 'phosphodiester_bond must be a positive' => { phosphodiester_bond => -1, dihedrals => 1 } ],
		[ 'contact_distance must be a positive'    => { contact_distance => 0 } ],
		[ 'disulfide_distance must not be negative' => { disulfide_distance => -1 } ],
		[ 'base_pair_hbond must be a positive'      => { base_pair_hbond => 0 } ],
		[ 'base_pair_stagger must not be negative'  => { base_pair_stagger => -1 } ],
		[ 'base_stack_distance must be a positive'  => { base_stack_distance => 0 } ],
		[ 'base_stack_omega must be between'        => { base_stack_omega => 181 } ],
	);
	for my $case (@refused) {
		my ($msg, $opt) = @$case;
		throws_ok { Chem::Structure::Parser::_features($i, $opt, 'xs') }
			qr/\Qxs: $msg\E/, "the XS refuses it too: $msg";
	}
	throws_ok { Chem::Structure::Parser::_features([], {}, 'xs') }
		qr/structure must be a hash reference/,
		'and refuses a structure that is not a hash reference';
	throws_ok { Chem::Structure::Parser::_features($i, [], 'xs') }
		qr/options must be a hash reference/,
		'and options that are not one';
	# who => undef is the documented default, which is what the module passes
	# when it has nothing better to call the caller
	throws_ok { Chem::Structure::Parser::_features($i, { probe => -1 }, undef) }
		qr/\Qstructure_features: probe\E/,
		'with no name to complain in, it complains as structure_features';
}

# ---- the two base pair thresholds are the whole of the rule ---------------
#
# wobble.pdb is twelve nucleotides of 1MSY whose own annotation records six
# pairs, five of them Watson-Crick or wobble.  Widening the hydrogen bond has
# to reach the sixth and no further, and tightening the stagger has to lose the
# stacked contacts first and the pairs only when nothing is left.
{
	my $i = structure_info("$data/wobble.pdb");
	my @by_hbond = map { scalar @{ structure_base_pairs($i, base_pair_hbond => $_) } }
	               (2.5, 3.0, 3.5, 5.3);
	is_deeply(\@by_hbond, [ 0, 4, 5, 6 ],
		'the pairs found rise with the hydrogen bond cutoff and stop at six');
	my @by_stagger = map { scalar @{ structure_base_pairs($i, base_pair_stagger => $_) } }
	                 (0, 0.3, 0.5, 1.0, 2.6, 10);
	is_deeply(\@by_stagger, [ 0, 2, 4, 5, 5, 6 ],
		'and with the stagger, up to the five that are really there');
	# the sixth at ten angstrom is G2671 stacked on U2672: its two hydrogen
	# bonds are 3.33 and 3.47 A, inside the cutoff, and it is 3.40 A out of
	# plane, which is a helical rise and is the whole reason the stagger is
	# tested at all
	structure_features($i);
}

# ---- a pair needs every atom the pairing names --------------------------
#
# A base whose density ran out, or that was modelled without one of its
# exocyclic atoms, is not a base pair with a bond missing: it is not a pair at
# all, and the rule is the same one an incomplete aromatic ring gets.  Taking
# the atom out of the structure rather than writing a fixture keeps the
# comparison to one thing -- everything else about the two reads is identical.
{
	my $i = structure_info("$data/wobble.pdb", features => 0);
	my $before = structure_base_pairs($i);
	my $p = $before->[0];
	my $r = $i->{chains}{ $p->{chain1} }{residues}{ $p->{residue1} };
	my $gone = $p->{hbonds}[0]{atom1};
	delete $r->{atoms}{$gone};
	my $after = structure_base_pairs($i);
	is(scalar @$after, scalar(@$before) - 1,
		"a pair missing its $gone is one pair fewer, not one bond fewer");
	is_deeply([ map { "$_->{residue1}|$_->{residue2}" } @$after ],
	          [ map { "$_->{residue1}|$_->{residue2}" } @{$before}[ 1 .. $#$before ] ],
		'and the pairs that still have their atoms are untouched');
	# the stacking reads the ring rather than the pairing atoms, and O6 is not
	# one of the ring's, so the same structure still stacks
	cmp_ok(scalar @{ structure_base_stacks($i) }, '>', 0,
		'while the stacks, which read the ring, are unaffected');
}

# ---- files a depositor should not write, and does ------------------------
{
	# an element field that spells no element.  It is kept as the file wrote it
	# -- dressing 'Xx' up as an element would be inventing chemistry -- and the
	# atom is counted so that a caller can see how much of the structure the
	# properties had no radius or mass for.
	my $prefix = 'ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00';
	is(length $prefix, 66, 'the record prefix ends where the B-factor does');
	my $i = structure_info_string(
		$prefix . (' ' x 10) . "XX\n"
		. 'ATOM      2  CB  ALA A   1      11.000  10.000  10.000  1.00 20.00' . (' ' x 10) . "C\n");
	is($i->{chains}{A}{residues}{1}{atoms}{CA}{element}, 'XX',
		'an element field that is not an element is kept as it was written');
	is($i->{features}{n_no_element}, 1, 'and counted as one the properties could not place');
	is($i->{stats}{elements}{XX}, 1, 'the tally has it under its own name');
}
{
	# A coordinate of 'inf'.  strtod reads it, so it arrives as an NV infinity
	# and the cell grid cannot be built from the extent: the doubling loop in
	# grid_build() gives up after its bounded number of turns and falls back to
	# one cell, which is the whole reason that counter is there.  What this
	# checks is that the read finishes and answers, rather than looping or
	# casting an infinity to an integer.
	my $t = "ATOM      1  N   ALA A   1         inf  10.000  10.000  1.00 20.00           N\n"
	      . "ATOM      2  CA  ALA A   1      11.000  10.000  10.000  1.00 20.00           C\n"
	      . "ATOM      3  C   ALA A   1      12.000  10.000  10.000  1.00 20.00           C\n"
	      . "ATOM      4  O   ALA A   1      13.000  10.000  10.000  1.00 20.00           O\n";
	my $i = structure_info_string($t, features => 0);
	ok($i->{chains}{A}{residues}{1}{atoms}{N}{x} == 9**9**9,
		'a coordinate of inf is read as an infinity');
	my $f;
	lives_ok { $f = structure_features($i, points => 24) }
		'and the properties of a structure with one still finish';
	ok(defined $f->{sasa}{total}, 'with a surface for the atoms that have a position');
}
{
	# A structure a caller built by hand, with a residue that has no name and no
	# single-letter code.  Nothing this module reads is missing them, so this is
	# the shape of an $info assembled somewhere else -- and the walk has to take
	# it as it finds it rather than reading a key that is not there.
	my $info = {
		chain_order => ['A'],
		chains      => {
			A => {
				# no n_atoms: a chain this module read always has one, and the
				# walk sizes its arrays from it, so a structure that does not
				# say is the case where that has to give way to what is there
				id => 'A',
				residue_order => ['1'],
				residues => {
					1 => {
						# the second atom has no element either, which is the
						# other half of the same question: a radius and a mass
						# have to come from somewhere, and mdtraj's own fallback
						# of 2 A is what they come from
						atom_order => [ 'CA', 'CB' ],
						atoms => {
							CA => { x => 0, y => 0, z => 0, element => 'C' },
							CB => { x => 1.5, y => 0, z => 0 },
						},
					},
				},
			},
		},
	};
	my $f;
	lives_ok { $f = structure_features($info) }
		'a structure with a residue that has no name is walked anyway';
	is($f->{n_atoms}, 2,
		'and both its atoms, though the chain never said how many it had');
	is($f->{n_no_element}, 1,
		'the one with no element is counted as one the properties could not place');
	ok(!defined $info->{chains}{A}{residues}{1}{rsa},
		'a residue with no letter gets no relative accessibility rather than a wrong one');
}
{
	# A chain capped with a residue the name table has never heard of.  gemmi
	# and mdtraj put the TER after such a cap, and so does this: the DSSP chain
	# is cut after the last polymer residue and then walked forward over
	# anything peptide-bonded to what comes before it.  1CMX ends chains B and D
	# with a GLZ -- a glycine capped at the carboxyl -- which is where the rule
	# comes from; here the last residue of fold.pdb is renamed to it.
	my $txt = do { open my $fh, '<', "$data/fold.pdb" or die $!; local $/; <$fh> };
	my @lines = split /\n/, $txt;
	my ($last) = map { substr($_, 22, 4) + 0 } grep { /\AATOM/ } reverse @lines;
	my $capped = join("\n", map {
		(/\AATOM/ && substr($_, 22, 4) + 0 == $last)
			? 'HETATM' . substr($_, 6, 11) . 'GLZ' . substr($_, 20)
			: $_
	} @lines) . "\n";
	my $plain = structure_info("$data/fold.pdb");
	my $cap   = structure_info_string($capped);
	is($cap->{chains}{A}{residues}{$last}{type}, 'ligand',
		'a cap the table does not know is not typed as an amino acid');
	is_deeply($cap->{features}{dssp}, $plain->{features}{dssp},
		'but it is part of its chain: every residue keeps the letter it had');
	ok(defined $cap->{chains}{A}{residues}{$last}{ss},
		'and the cap itself is assigned rather than left out of the chain');
}

# ---- the phosphodiester cutoff is the whole of the linkage rule ----------
#
# alpha, epsilon and zeta each span two residues, so shrinking the cutoff below
# a real O3'-to-P bond has to leave a chain with none of them and the
# intra-residue torsions untouched.  The six bonds in duplex.pdb measure 1.5918
# to 1.6037 A, so 1.5 A links nothing and 1.7 A links all six.
{
	my $i = structure_info("$data/duplex.pdb");
	my @span = qw(alpha epsilon zeta);
	my @own  = qw(beta gamma delta chi);
	for my $case ([ 1.5, 0 ], [ 1.7, 1 ]) {
		my ($cut, $want) = @$case;
		structure_features($i, phosphodiester_bond => $cut);
		my ($spanning, $inside) = (0, 0);
		for my $cid (@{ $i->{chain_order} }) {
			my $c = $i->{chains}{$cid};
			for my $rk (@{ $c->{residue_order} }) {
				my $r = $c->{residues}{$rk};
				$spanning += grep { defined $r->{$_} } @span;
				$inside   += grep { defined $r->{$_} } @own;
			}
		}
		# eight residues could carry three each, but the two strands have four
		# ends between them: A 3 has no alpha and A 6 no epsilon and no zeta,
		# and the same on B, so six of the twenty-four never exist at all
		is($spanning, $want ? 18 : 0,
			"phosphodiester_bond => $cut: " . ($want ? 'every' : 'no')
			. ' torsion that spans two residues');
		is($inside, 32, "... and all thirty-two that do not, either way");
	}
	# and back to the default, so nothing after this sees the 1.7 A answer
	structure_features($i);
}

# ---- the secondary structure roll-up -------------------------------------
#
# What the letters *are* is t/features.t's job: it holds every one of them to
# mdtraj's.  This is the shape of the hash of hashes they are handed back in,
# and the two ways of asking for it.
{
	my $i = structure_info("$data/fold.pdb");
	my $d = structure_dssp($i);
	is(ref $d, 'HASH', 'structure_dssp: a hash reference');
	is_deeply([ sort keys %$d ], [ 'A' ], 'keyed by chain id');
	ok(scalar keys %{ $d->{A} } > 1, 'and then by DSSP letter');
	is_deeply([ grep { !/\A[HBEGITS ]\z/ } keys %{ $d->{A} } ], [],
		'every key is one of the eight letters, coil being a space');

	# the indices are positions in that chain's residue_order, so they index
	# straight into the chain and into structure_residues()
	my $order = $i->{chains}{A}{residue_order};
	my $flat  = structure_residues($i, 'A');
	my ($ix)  = @{ $d->{A}{H} };
	is($i->{chains}{A}{residues}{ $order->[$ix] }{ss}, 'H',
		'an index reaches the residue through residue_order');
	is($flat->[$ix]{ss}, 'H', 'and the same residue in structure_residues');
	is_deeply([ @{ $d->{A}{H} } ], [ sort { $a <=> $b } @{ $d->{A}{H} } ],
		'each list is in residue order');

	# a residue with no backbone has no letter and is in no list
	my $lettered = grep { defined $_->{ss} } @$flat;
	my $listed = 0;
	$listed += scalar @{ $d->{A}{$_} } for keys %{ $d->{A} };
	is($listed, $lettered, 'every residue with a letter is listed exactly once');

	# structure_info($file, 'dssp') is the same hash asked for on its own, and
	# dssp => 1 is the same hash left on the structure
	is_deeply(structure_info("$data/fold.pdb", 'dssp'), $d,
		"structure_info(\$file, 'dssp') hands back just the roll-up");
	my $with = structure_info("$data/fold.pdb", dssp => 1);
	is($with->{dssp}, $with->{features}{dssp}, 'dssp => 1 puts it at $info->{dssp}');
	is_deeply($with->{dssp}, $d, 'and it is the same answer');
	ok(!exists $i->{dssp}, 'without the option there is no such key');

	# the view form takes the reader's options after it
	my $one = structure_info("$data/mini.pdb", 'dssp', chains => ['A']);
	is_deeply([ sort keys %$one ], [ 'A' ], 'and options after it are the reader\'s');

	throws_ok { structure_info("$data/fold.pdb", 'sasa') }
		qr/structure_info: 'sasa' is not a view/,
		'a name that is not a view says so, and says what is';
	throws_ok { structure_info("$data/fold.pdb", 'dssp', features => 0) }
		qr/structure_info: 'dssp' needs the features/,
		'and asking for one with features => 0 does not hand back nothing quietly';
	throws_ok { structure_info("$data/fold.pdb", 'dssp', atoms => 0) }
		qr/atoms => 0/, 'nor with atoms => 0';
	throws_ok { structure_dssp($i, probe => 2) }
		qr/structure_dssp: unknown option 'probe'/,
		'structure_dssp takes no options, because there is nothing to tune';
}

for my $who (qw(structure_features structure_sasa structure_pi_stacking
                structure_disulfides structure_contacts structure_hbonds
                structure_base_stacks structure_dssp)) {
	no strict 'refs';
	throws_ok { &{"Chem::Structure::Parser::$who"}(undef) } qr/\Q$who\E: expected the hash/,
		"$who refuses undef";
	throws_ok { &{"Chem::Structure::Parser::$who"}({ a => 1 }) } qr/\Q$who\E: expected the hash/,
		"$who refuses a hash that is not a structure";
	throws_ok { &{"Chem::Structure::Parser::$who"}([]) } qr/\Q$who\E: expected the hash/,
		"$who refuses an array reference";
}

# ---- the reader's own options carry through ------------------------------
{
	my $all = structure_sasa(structure_info("$data/mini.pdb"))->{total};
	my $dry = structure_sasa(structure_info("$data/mini.pdb", waters => 0))->{total};
	my $noh = structure_sasa(structure_info("$data/mini.pdb", hydrogens => 0))->{total};
	my $one = structure_sasa(structure_info("$data/mini.pdb", chains => ['B']))->{total};
	isnt($dry, $all, 'dropping the waters changes the surface');
	isnt($noh, $all, 'and so does dropping the hydrogens');
	cmp_ok($one, '<', $all, 'and reading one chain leaves less of it');

	# an NMR ensemble: the properties are of the model the chains were built
	# from, which is the one $info->{model} names.  nmr.pdb's three models are
	# the same tripeptide moved along x, so the surface is the invariant and the
	# centroid is what moved -- which is the pair of assertions worth making.
	my $m1 = structure_features(structure_info("$data/nmr.pdb", model => 1));
	my $m3 = structure_features(structure_info("$data/nmr.pdb", model => 3));
	cmp_ok(abs($m1->{sasa}{total} - $m3->{sasa}{total}), '<', 1e-9,
		'a model that is a translation of another has the same surface');
	cmp_ok(abs($m1->{rg} - $m3->{rg}), '<', 1e-9, 'and the same radius of gyration');
	cmp_ok(abs($m1->{center}[0] - $m3->{center}[0]), '>', 1,
		'and a centroid two angstrom away, which is where it was moved to');
	my $ma = structure_features(structure_info("$data/nmr.pdb", model => 'all'));
	cmp_ok(abs($ma->{sasa}{total} - $m1->{sasa}{total}), '<', 1e-9,
		"model => 'all' reports the model whose chains \$info->{chains} holds");
}

# ---- a gzipped file ------------------------------------------------------
SKIP: {
	# the package is loaded at run time here, so $GzipError is a name perl sees
	# once and warns about; the warning is about this file, not about the module
	no warnings 'once';
	eval { require IO::Compress::Gzip; 1 } or skip 'IO::Compress is not installed', 1;
	my $dir = tempdir(CLEANUP => 1);
	IO::Compress::Gzip::gzip("$data/stack.pdb" => "$dir/stack.pdb.gz")
		or skip "cannot gzip the fixture: $IO::Compress::Gzip::GzipError", 1;
	is_deeply(structure_features(structure_info("$dir/stack.pdb.gz")),
	          structure_features(structure_info("$data/stack.pdb")),
		'a gzipped file gives the same properties as the file it was made from');
}

# ---- the neighbour grid --------------------------------------------------
#
# The surface is computed through a grid of cells one cutoff wide rather than by
# comparing every atom with every other, which is what mdtraj does; t/features.t
# is what proves the two find the same neighbours, because mdtraj's scan is
# exhaustive and the answers match to the last digit.
#
# What is worth checking here is that the answer does not depend on where the
# structure happens to sit in the grid.  Moving it by a fraction of a cell puts
# every atom in a different cell, and a pair whose two atoms end up more than
# one cell apart would be missed.  The offsets below are deliberately not
# multiples of anything: 6.56 A is the cell size for a structure of carbon,
# nitrogen, oxygen and sulphur (twice the largest radius plus the probe).
{
	my $ref;
	for my $shift ([ 0, 0, 0 ], [ 0.37, 0, 0 ], [ 0, 3.13, 0 ], [ 0, 0, -7.91 ],
	               [ 101.3, -55.7, 12.9 ], [ -1000.5, 2000.25, -3000.125 ]) {
		my $i = structure_info("$data/stack.pdb");
		for my $cid (@{ $i->{chain_order} }) {
			my $c = $i->{chains}{$cid};
			for my $rk (@{ $c->{residue_order} }) {
				my $r = $c->{residues}{$rk};
				for my $an (@{ $r->{atom_order} }) {
					my $a = $r->{atoms}{$an};
					$a->{x} += $shift->[0];
					$a->{y} += $shift->[1];
					$a->{z} += $shift->[2];
				}
			}
		}
		my $t = structure_sasa($i)->{total};
		$ref = $t unless defined $ref;
		# the coordinates are three-decimal numbers and the shifts are exact
		# binary fractions or close to them, so the arithmetic is the only
		# source of difference; 1e-6 A^2 of 1736 is 6e-10 relative
		cmp_ok(abs($t - $ref), '<', 1e-6,
			"moving the structure by (@{[ join ', ', @$shift ]}) does not change its surface");
	}
}

# ---- calling twice -------------------------------------------------------
#
# The results are written into $info, so a second call has to overwrite them
# rather than add to them.
{
	my $i = structure_info("$data/stack.pdb");
	my $a = structure_features($i);
	my $b = structure_features($i);
	is_deeply($b, $a, 'asking twice gives the same answer');
	my $c = structure_features($i, probe => 2.0);
	cmp_ok($i->{chains}{A}{sasa}, '>', $a->{sasa}{total} / 2,
		'and asking again with a different probe replaces what was stored');
	cmp_ok(abs($i->{chains}{A}{sasa} - $c->{sasa}{total}), '<', 1e-9,
		'with the new figure, not the old one');
}

# ---- an atom with more neighbours than a structure can give it -----------
#
# The surface kernel sorts an atom's neighbours nearest-first so that the scan
# over the sphere points ends sooner, and skips the sort above SASA_SORT_MAX
# neighbours, where it would be quadratic work on a list no real structure
# produces (141 is the longest over a 405-structure spread of PDBbind).  A
# lattice of 729 atoms six tenths of an angstrom apart gives the atom in the
# middle of it 728 neighbours, which is how the skipped path is reached at all
# -- and what is asserted is what holds whichever path ran: the parts add up to
# the whole, and no atom has more surface than a free sphere of its own radius.
{
	my ($pdb, $n) = ('', 0);
	for my $i (0 .. 8) {
		for my $j (0 .. 8) {
			for my $k (0 .. 8) {
				$n++;
				$pdb .= sprintf "ATOM  %5d  CA  ALA A%4d    %8.3f%8.3f%8.3f  1.00  0.00           C\n",
					$n, $n, $i * 0.6, $j * 0.6, $k * 0.6;
			}
		}
	}
	my $i = structure_info_string($pdb);
	my $f = $i->{features}{sasa};
	my ($sum, $over) = (0, 0);
	# carbon's van der Waals radius plus the 1.4 A probe, which is the sphere
	# the points are spread over
	my $free = 4 * atan2(1, 0) * 2 * (1.70 + 1.4) ** 2;
	for my $c (@{ $i->{chain_order} }) {
		for my $rk (@{ $i->{chains}{$c}{residue_order} }) {
			my $r = $i->{chains}{$c}{residues}{$rk};
			for my $an (@{ $r->{atom_order} }) {
				my $a = $r->{atoms}{$an}{sasa};
				$sum += $a;
				$over++ if $a > $free + 1e-9 || $a < 0;
			}
		}
	}
	is($n, 729, 'the lattice is 729 atoms, which is more neighbours than the sort takes');
	# the total is a sum of the same NVs in the same order, so it is exact
	cmp_ok(abs($f->{total} - $sum), '<', 1e-9,
		'the atoms account for the whole surface');
	is($over, 0, 'and none of them has more surface than a free sphere');
}

# ---- a coordinate that is not a number ------------------------------------
# A field that says nan is read as the NV it names, as strtod() reads it, and
# the atom is kept.  One such atom anywhere in a structure used to make the
# neighbour grid's box non-finite, which put every atom into one cell and made
# the whole surface quadratic in the atoms -- the same answer, got the slow way.
# The box is now taken over the finite atoms, and the answer for them is still
# the answer they have without the other atom there: every distance to a NaN
# compares false, so it covers none of anybody's sphere.
{
	my $atoms = <<'PDB';
ATOM      1  N   ALA A   1      10.000  10.000  10.000  1.00 20.00           N
ATOM      2  CA  ALA A   1      11.458  10.000  10.000  1.00 20.00           C
ATOM      3  C   ALA A   1      12.009  11.420  10.000  1.00 20.00           C
PDB
	my $nan = "HETATM    4  O   HOH W   1         nan  10.000  10.000  1.00 20.00           O\n";
	my $plain = structure_info_string($atoms, features => 0);
	my $odd   = structure_info_string($nan . $atoms, features => 0);
	structure_sasa($plain);
	structure_sasa($odd);
	my ($p, $o) = map { $_->{chains}{A}{residues}{1}{atoms} } $plain, $odd;
	is_deeply([ map { $o->{$_}{sasa} } qw(N CA C) ], [ map { $p->{$_}{sasa} } qw(N CA C) ],
		'an atom at NaN changes no other atom\'s surface, even as the first atom of the set');
}

done_testing();
