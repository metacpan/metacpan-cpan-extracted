#!/usr/bin/env perl
# Base stacking: d0, omega, Xi and the score.
#
# The definition is section 2.4 of
#
#   Condon, D E; Kennedy, S D; Mort, B C; Kierzek, R; Yildirim, I; Turner, D H
#   (2015) "Stacking in RNA: NMR of Four Tetramers Benchmark Molecular
#   Dynamics", J Chem Theory Comput 11(6):2729-2742, doi:10.1021/ct501025q
#
# and the implementation the paper's numbers were produced with is the author's
# own PDB_stacker (https://github.com/hhg7/PDB_stacker, pdb_stacking.pl).
# Neither is this module, which is the point: the reference case below is a
# published answer to a published question about a real entry, not this
# module's answer to its own.
#
# **The reference case.**  Figure 4 of the paper illustrates the three variables
# on residues 13 (C) and 14 (G) of chain B of PDB entry 157D, and its caption
# reports d0 = 4.5 A, omega = 40.7 degrees and Xi = 17.3 degrees.  Those six
# residues are t/data/aform.pdb, exactly as deposited, and that pair is what the
# first block below checks.  It is the one worked example either the paper or
# the script gives, and it is the whole of the cross-validation: it pins the
# geometry, the atom lists the centres of mass are taken over (guanine's leaves
# N2 out, and including it would give 4.77 and 43.56), and the reading of
# equation 10 that Xi is computed by (the equation as printed gives 9.5).
# Parser.xs's header comment for base_stacks() argues all three.
#
# Everything else here is this module's own surface -- the options, the call
# forms, what is written onto a residue, and the edges of the two ramps -- which
# is t/properties.t's job for every other feature and is done here because the
# fixture is here.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::More;
use Test::Exception;

my $data = dirname(abs_path(__FILE__)) . '/data';

# one pair out of a list, by the two residue keys
sub pair {
	my ($list, $r1, $r2) = @_;
	my @hit = grep { $_->{residue1} eq $r1 && $_->{residue2} eq $r2 } @$list;
	return $hit[0];
}

#--------------------------------------------------------------------
# the published case
#--------------------------------------------------------------------
for my $fmt (qw(pdb cif)) {
	my $info = structure_info("$data/aform.$fmt");
	my $st   = structure_base_stacks($info);
	my $p    = pair($st, 13, 14);

	ok($p, "aform.$fmt: the Figure 4 pair is found");
	is($p->{type}, 'C-G', "aform.$fmt: named 5' base first, which is the C");

	# The caption's three numbers, to the one decimal place it prints them to.
	# 5e-2 is the half-ulp of a number written to one decimal, so this is
	# "rounds to what the caption says" and not a tolerance with slack in it:
	# the module answers 4.5286, 40.7402 and 17.3071 on all three NV widths,
	# which is 0.029, 0.040 and 0.007 from the printed values.
	cmp_ok(abs($p->{distance} - 4.5),  '<', 5e-2, "aform.$fmt: d0 is the caption's 4.5 A");
	cmp_ok(abs($p->{omega}    - 40.7), '<', 5e-2, "aform.$fmt: omega is the caption's 40.7 deg");
	cmp_ok(abs($p->{xi}       - 17.3), '<', 5e-2, "aform.$fmt: Xi is the caption's 17.3 deg");
}

#--------------------------------------------------------------------
# the score, at both ends of both ramps
#--------------------------------------------------------------------
{
	my $info = structure_info("$data/aform.pdb");
	my $st   = structure_base_stacks($info);

	is(scalar @$st, 5, 'five stacks along six nucleotides: each pair with its neighbour');

	# G14-C15 is inside both knees -- 3.94 A and 23.3 degrees -- so it takes
	# both whole points and scores the full 100%.  It is the only pair in the
	# fixture that does, which is what makes it worth naming.
	my $best = pair($st, 14, 15);
	cmp_ok($best->{distance}, '<', 4.0,  'G14-C15 is inside the distance knee');
	cmp_ok($best->{omega},    '<', 25.0, 'and inside the overlap knee');
	is($best->{score}, 100, 'so it scores 100%, which is both points');
	is($best->{stacked}, 1, 'and counts as stacked');

	# and the pair the paper draws is on both ramps rather than at the top of
	# either, so its score is the sum of two fractions
	my $fig4 = pair($st, 13, 14);
	my $d = 1.0 / ($fig4->{distance} - 4.0 + 1.0) ** 3;
	my $w = (50.0 - $fig4->{omega}) / (50.0 - 25.0);
	cmp_ok(abs($fig4->{score} - 100 * ($d + $w) / 2), '<', 1e-9,
		'the Figure 4 pair scores the two ramps added, halved and percented');
	is($fig4->{stacked}, 0, 'and at 32.5% is not stacked, the paper wanting over 50%');

	# every pair is between -100 and 100, which is what the paper says the
	# score's range is
	for my $s (@$st) {
		cmp_ok($s->{score}, '<=', 100, "$s->{type} $s->{residue1}-$s->{residue2}: at most 100%");
		cmp_ok($s->{score}, '>=', -100, "$s->{type} $s->{residue1}-$s->{residue2}: at least -100%");
	}
}

#--------------------------------------------------------------------
# what goes onto the residues
#--------------------------------------------------------------------
{
	my $info = structure_info("$data/aform.pdb");
	my $g14  = $info->{chains}{B}{residues}{14};
	my $l    = $g14->{base_stack};

	is(scalar @$l, 2, 'G14 is in two stacks, one on each side of it');
	is_deeply([ sort map { $_->{residue} } @$l ], [ 13, 15 ],
		'and they name the residues either side');

	# omega is measured from the 5' base against the 3' base's centre of mass,
	# so it is not the same number read the other way round and the entry says
	# which end this residue is
	my ($to13) = grep { $_->{residue} eq '13' } @$l;
	my ($to15) = grep { $_->{residue} eq '15' } @$l;
	is($to13->{side}, "3'", 'G14 is the 3\' base of the pair with C13');
	is($to15->{side}, "5'", 'and the 5\' base of the pair with C15');
	is($to13->{type}, 'G-C', 'the type reads from this residue outwards');

	# asking again replaces what the first call wrote rather than adding to it
	structure_base_stacks($info) for 1 .. 3;
	is(scalar @{ $info->{chains}{B}{residues}{14}{base_stack} }, 2,
		'asking three more times leaves two, not eight');

	# store => 0 computes the list and writes nothing
	my $fresh = structure_info("$data/aform.pdb", features => 0);
	my $out = structure_base_stacks($fresh, store => 0);
	is(scalar @$out, 5, 'store => 0 still returns every stack');
	ok(!exists $fresh->{chains}{B}{residues}{14}{base_stack},
		'and leaves nothing on the residue');
}

#--------------------------------------------------------------------
# the two cutoffs
#--------------------------------------------------------------------
{
	my $info = structure_info("$data/aform.pdb", features => 0);

	# a distance cutoff under every pair's d0 finds nothing at all: the
	# fixture's closest pair is 3.91 A apart
	is(scalar @{ structure_base_stacks($info, base_stack_distance => 3.5) }, 0,
		'a distance cutoff below every pair finds none of them');

	# and one over the widest separation in a six-nucleotide stretch finds the
	# pairs that are not neighbours as well
	my $wide = structure_base_stacks($info, base_stack_distance => 9);
	cmp_ok(scalar @$wide, '>', 5, 'a wider cutoff finds pairs that are not neighbours');

	# omega past its cutoff is criterion II: not stacked, no Xi, score 0.  The
	# Figure 4 pair's omega is 40.74, so a cutoff of 30 puts it outside.
	my $tight = structure_base_stacks($info, base_stack_omega => 30);
	my $f = pair($tight, 13, 14);
	ok($f, 'a pair past the omega cutoff is still reported');
	ok(defined $f->{distance} && defined $f->{omega}, 'with its distance and its omega');
	ok(!exists $f->{xi}, 'but no Xi, which criterion II does not compute');
	is($f->{score}, 0, 'and a score of 0');
	is($f->{stacked}, 0, 'and is not stacked');

	# the default is what the paper says it is
	is_deeply(structure_base_stacks($info),
	          structure_base_stacks($info, base_stack_distance => 5, base_stack_omega => 50),
		'the defaults are the paper\'s 5.0 A and 50 degrees');
}

#--------------------------------------------------------------------
# which residues have a base at all
#--------------------------------------------------------------------
{
	# a protein has no bases, and says so with an empty list rather than by
	# leaving the key out
	my $prot = structure_info("$data/fold.pdb");
	is_deeply($prot->{features}{base_stacks}, [],
		'a protein has no base stacks, and says so');

	# DNA reaches the same table through the same single-letter codes, so
	# bases.pdb -- seven deoxynucleotides, all four DNA bases -- is measured too
	my $dna = structure_info("$data/bases.pdb");
	cmp_ok(scalar @{ $dna->{features}{base_stacks} }, '>', 0,
		'DNA stacks are found: DA, DC, DG and DT reach the same four entries');
	my %seen = map { $_->{type} => 1 } @{ $dna->{features}{base_stacks} };
	ok((grep { /T/ } keys %seen), 'including thymine, which PDB_stacker has no entry for');

	# every reported pair carries the six fields that name it and the three
	# variables, in both formats and for every fixture with a base in it
	for my $stem (qw(aform bases rna duplex wobble)) {
		for my $s (@{ structure_info("$data/$stem.pdb")->{features}{base_stacks} }) {
			my $who = "$stem $s->{residue1}-$s->{residue2}";
			ok(defined $s->{$_}, "$who: has $_")
				for qw(type chain1 residue1 resname1 chain2 residue2 resname2
				       distance omega score stacked);
			cmp_ok($s->{distance}, '<=', 5.0, "$who: is inside the distance cutoff");
			cmp_ok($s->{omega}, '>=', 0, "$who: omega is an angle");
			cmp_ok($s->{omega}, '<=', 180, "$who: and no more than 180 degrees");
			# Xi is folded into 0..90 by construction, and is there exactly when
			# omega is inside its cutoff
			if ($s->{omega} <= 50) {
				ok(defined $s->{xi}, "$who: has a Xi");
				cmp_ok($s->{xi}, '>=', 0,  "$who: Xi is at least 0");
				cmp_ok($s->{xi}, '<=', 90, "$who: and at most 90");
			} else {
				ok(!exists $s->{xi}, "$who: omega past the cutoff, so no Xi");
			}
		}
	}
}

#--------------------------------------------------------------------
# the call forms and the arguments that are refused
#--------------------------------------------------------------------
{
	my $info = structure_info("$data/aform.pdb");

	# structure_info computes it on the way past, and asking again with no
	# options is the lookup rather than the walk
	is_deeply(structure_base_stacks($info), $info->{features}{base_stacks},
		'with no options it is the answer structure_info already had');
	is_deeply(structure_features($info)->{base_stacks}, $info->{features}{base_stacks},
		'and structure_features has the same list under the same key');

	# base_stacks => 0 does not compute them
	ok(!exists structure_features($info, base_stacks => 0)->{base_stacks},
		'base_stacks => 0 leaves the key out rather than computing an empty list');

	throws_ok { structure_base_stacks($info, base_stack_distance => 0) }
		qr/base_stack_distance must be a positive number/,
		'a distance cutoff of zero is refused';
	throws_ok { structure_base_stacks($info, base_stack_distance => -1) }
		qr/base_stack_distance must be a positive number/,
		'and so is a negative one';
	throws_ok { structure_base_stacks($info, base_stack_omega => 181) }
		qr/base_stack_omega must be a number between 0 and 180/,
		'an overlap angle over 180 degrees is refused';
	throws_ok { structure_base_stacks($info, base_stack_omega => 'wide') }
		qr/base_stack_omega must be a number between 0 and 180/,
		'and so is one that is not a number';
	throws_ok { structure_base_stacks($info, face_distance => 5) }
		qr/unknown option 'face_distance'/,
		'a threshold belonging to another feature is refused, not ignored';
	throws_ok { structure_base_stacks('not a structure') }
		qr/structure_base_stacks/,
		'and so is something that is not a structure';
}

done_testing();
