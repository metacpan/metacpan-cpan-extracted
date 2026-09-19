#!/usr/bin/env perl
# Against real structures, when there are any to hand.
#
# The fixtures test the cases that were thought of.  This tests the ones that
# were not: a few thousand real entries carry every quirk thirty years of a
# format collects, and most of them are in files nobody would think to write
# by hand.
#
# Set STRUCTURE_INFO_TEST_DIR to a directory of .pdb/.ent files to run it
# somewhere else.  With nothing to read, the file skips rather than fails --
# the distribution has to build on a machine with no structures on it.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::More;

# Windows has no HOME, and a smoker runs with warnings fatal, so reading it
# to build the maintainer's default path is what failed the file there rather
# than skipping it.  USERPROFILE is the Windows spelling; with neither set
# there is no default path to try, and the entry drops out.
my $home = defined $ENV{HOME} ? $ENV{HOME} : $ENV{USERPROFILE};

my @DIRS = grep { defined && -d } (
	$ENV{STRUCTURE_INFO_TEST_DIR},
	defined $home ? "$home/ui/pepPriML/PPB/PDB/PDBbind.v2020" : undef,
	dirname(abs_path(__FILE__)) . '/real',
);
plan skip_all => 'no directory of real structures found; set STRUCTURE_INFO_TEST_DIR'
	unless @DIRS;

opendir(my $dh, $DIRS[0]) or plan skip_all => "cannot read $DIRS[0]: $!";
my @all = sort grep { /\.(pdb|ent)(\.gz)?\z/ } readdir $dh;
closedir $dh;
plan skip_all => "no structure files in $DIRS[0]" unless @all;

# a spread across the directory rather than the first N, which in a directory
# named by PDB id would be all the same vintage
my $want = $ENV{STRUCTURE_INFO_TEST_ALL} ? @all : 60;
my $step = @all > $want ? int(@all / $want) : 1;
my @files = map { "$DIRS[0]/$all[$_]" } grep { $_ % $step == 0 } 0 .. $#all;
@files = @files[0 .. $want - 1] if @files > $want;

diag(sprintf('reading %d of %d structures in %s', scalar @files, scalar @all, $DIRS[0]));

# --- an independent reader, for the things worth checking twice ------------
#
# The point of the XS is to slice fixed columns quickly.  This does the same
# slicing in the most obvious Perl there is, and the two are compared on every
# file: if the C ever reads a column wrong, the two will disagree.  It is
# deliberately naive -- no options, no filtering, model 1 only.
#
# It returns two things.  The residue list is every residue in the file as
# chain/number/insertion code/name, which tests the column reading and nothing
# else.  The protein sequences are built from amino acids alone, which tests
# the reading and the single-letter codes without going near the ambiguity
# over whether a lone GUA is a nucleotide or a free base.
#
# A residue is a chain, a number and an insertion code, which is how the
# module keys them, and the name is carried along rather than being part of
# the identity.  It cannot be part of it: one position is sometimes modelled
# in two chemical states at once, as complementary altloc groups, and both
# are the same residue.  3zeu has ten methionines each written as MSE in
# altlocs A and B and MET in C and D, a selenomethionine that only went
# halfway in; 2ftm has an aspartate at A115 that is IAS in altloc A and ASP
# in B, 5nai a CSD/CYS at A198, 5za2 a SEP/SER at B64 and 6e4z a NEP/HIP at
# H58.  Counting those twice would put a second M in the sequence of a
# protein that has one.  The name still has to agree, because it is in the
# string being compared -- only the counting is by position.
sub reference_read {
	my ($file) = @_;
	open my $fh, '<', $file or die "$file: $!";
	my (%res, %seq, %seen, $ended);
	while (my $l = <$fh>) {
		last if $ended;
		$ended = 1 if $l =~ /\AENDMDL/;
		next unless $l =~ /\A(?:ATOM  |HETATM)/;
		my $chain   = substr($l, 21, 1);
		my $resname = substr($l, 17, 3);
		my $num     = substr($l, 22, 4);
		my $icode   = substr($l, 26, 1);
		for ($chain, $resname, $num, $icode) { s/\A\s+//; s/\s+\z// }
		my $key = "$chain|$num|$icode";
		next if $seen{$key}++;
		push @{ $res{$chain} }, "$num|$icode|$resname";
		$seq{$chain} .= aa3to1($resname) if res_type($resname) eq 'amino_acid';
	}
	close $fh;
	return (\%res, \%seq);
}

my $checked = 0;
my $chains_with_seqres = 0;
my @over;
for my $file (@files) {
	my $name = (split m{/}, $file)[-1];
	# features => 0: this loop is about reading the file, and the surface is
	# five times the cost of the read.  The properties get their own pass below.
	my $info = eval { structure_info($file, features => 0) };
	if (!$info) {
		fail("$name: $@");
		next;
	}
	$checked++;

	# --- the counts have to add up ---------------------------------------
	my $chain_atoms = 0;
	$chain_atoms += $info->{chains}{$_}{n_atoms} for @{ $info->{chain_order} };
	is($chain_atoms, $info->{stats}{n_atoms}, "$name: the chains account for every atom")
		or next;

	my $ok = 1;
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		my ($res_atoms, $polymer) = (0, 0);
		for my $rk (@{ $c->{residue_order} }) {
			my $r = $c->{residues}{$rk};
			$res_atoms += $r->{n_atoms};
			$polymer++ if $r->{type} eq 'amino_acid' || $r->{type} eq 'nucleotide';
			# every residue key is the number with its insertion code on the end
			$ok &&= $rk eq (defined $r->{number} ? $r->{number} : '') . $r->{icode};
		}
		$ok &&= $res_atoms == $c->{n_atoms};
		$ok &&= $polymer   == $c->{n_polymer};
		$ok &&= length($c->{sequence}) == $c->{n_polymer};
		$ok &&= $c->{sequence} =~ /\A[A-Z]*\z/;
		$ok &&= scalar(@{ $c->{residue_order} }) == scalar(keys %{ $c->{residues} });
	}
	ok($ok, "$name: residues, atoms and sequence lengths agree inside every chain");

	# --- against the naive reader ----------------------------------------
	my ($ref_res, $ref_seq) = reference_read($file);
	my $got_res = {};
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		$got_res->{$cid} = [ map {
			my $r = $c->{residues}{$_};
			"$r->{number}|$r->{icode}|$r->{resname}"
		} @{ $c->{residue_order} } ];
	}
	is_deeply($got_res, $ref_res,
		"$name: the XS reads the same residues, in the same order, as plain Perl substr does");

	# Amino acids by name, on both sides, so that this compares column reading
	# and single-letter codes and nothing else.  Whether a given residue ends
	# up in the chain's sequence is a question of classification -- a free
	# glycine in a binding site does not -- and that is structure.t's business,
	# not this comparison's.
	my $got_seq = {};
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		my $s = join '', map  { aa3to1($c->{residues}{$_}{resname}) }
		                 grep { res_type($c->{residues}{$_}{resname}) eq 'amino_acid' }
		                 @{ $c->{residue_order} };
		$got_seq->{$cid} = $s if length $s;
	}
	is_deeply($got_seq, { map { $_ => $ref_seq->{$_} } grep { length $ref_seq->{$_} } keys %$ref_seq },
		"$name: and the same amino acid sequence");

	# --- what the header said, where it said anything --------------------
	if (defined $info->{resolution}) {
		ok($info->{resolution} > 0 && $info->{resolution} < 100,
			"$name: resolution $info->{resolution} is a plausible number");
	}
	if (defined $info->{r_free}) {
		ok($info->{r_free} > 0 && $info->{r_free} < 1, "$name: R-free is a fraction");
	}
	# The observed sequence is normally no longer than SEQRES -- every residue
	# with coordinates ought to be one that was declared.  It is not a rule the
	# format enforces, though: 3lms has ATOM residues numbered 567, 1501, 1889
	# and 2356 in a chain whose SEQRES is 309 long.  So this is counted across
	# the corpus rather than asserted per file, which still catches the failure
	# that matters -- a classification bug that starts sweeping ligands or
	# waters into sequences would push the rate up at once.
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		next unless defined $c->{seqres} && length $c->{sequence};
		$chains_with_seqres++;
		if (length($c->{sequence}) > length($c->{seqres})) {
			push @over, sprintf('%s chain %s: %d observed vs %d in SEQRES',
				$name, $cid, length $c->{sequence}, length $c->{seqres});
		}
	}
}

diag("longer than SEQRES: $_") for @over;
ok(@over <= $chains_with_seqres / 20,
	sprintf('the observed sequence is no longer than SEQRES in all but a few chains (%d of %d)',
		scalar @over, $chains_with_seqres));

# --- the id in the file agrees with the name of the file -------------------
{
	my $named = 0;
	for my $file (@files[0 .. ($#files > 20 ? 20 : $#files)]) {
		my $name = (split m{/}, $file)[-1];
		my ($stem) = $name =~ /\A(?:pdb)?([0-9a-z]{4})[.]/i or next;
		my $info = structure_info($file, features => 0);
		next unless defined $info->{header}{id_code} && length $info->{header}{id_code};
		$named++;
		is($info->{id}, uc $stem, "$name: the id in HEADER matches the file name");
	}
	ok($named > 0, 'at least one file had an id to check');
}

# --- the physical properties, on real structures --------------------------
#
# What is checked here is what the file itself settles, in the spirit of the
# rest of this file: a total that is the sum of its parts, a surface no atom can
# exceed, a stacked pair that is inside the thresholds it was found by.  Whether
# the numbers are *right* is t/features.t's question, and it asks mdtraj.
#
# A smaller spread than the reading above, because the surface is nine hundred
# and sixty sphere points per atom and a real entry has tens of thousands of
# atoms.
{
	my $want = $ENV{STRUCTURE_INFO_TEST_ALL} ? scalar @files : 12;
	my @some = @files[0 .. ($want > @files ? $#files : $want - 1)];
	# the largest van der Waals radius in the table is francium's 3.48 A, so no
	# atom's accessible sphere can be larger than this whatever it is made of
	my $cap = 4 * atan2(1, 0) * 2 * (3.48 + 1.4) ** 2;
	my ($n_ring_pairs, $checked_features, $n_puckers, $n_pairs) = (0, 0, 0, 0);
	my $n_stacks = 0;
	for my $file (@some) {
		my $name = (split m{/}, $file)[-1];
		my $info = structure_info($file);
		my $f = $info->{features};
		next unless $f && $f->{n_atoms};
		$checked_features++;

		my ($atoms, $chains, $worst) = (0, 0, 0);
		for my $cid (@{ $info->{chain_order} }) {
			my $c = $info->{chains}{$cid};
			$chains += $c->{sasa};
			my $residues = 0;
			for my $rk (@{ $c->{residue_order} }) {
				my $r = $c->{residues}{$rk};
				$residues += $r->{sasa};
				my $sum = 0;
				for my $an (@{ $r->{atom_order} }) {
					my $a = $r->{atoms}{$an};
					$worst = $a->{sasa} if $a->{sasa} > $worst;
					$sum += $a->{sasa};
					$atoms += $a->{sasa};
				}
				die "$name: residue $cid/$rk does not add up" if abs($sum - $r->{sasa}) > 1e-6;
				next unless defined $r->{rsa};
				# a residue cut off from its neighbours can beat the Gly-X-Gly
				# maximum, but not by a factor of three
				ok($r->{rsa} >= 0 && $r->{rsa} < 3,
					"$name: $r->{resname} $rk has a believable relative accessibility")
					if $r->{rsa} < 0 || $r->{rsa} >= 3;
			}
			# The sugar pucker, where there is one, against what it is by
			# construction rather than against a reference: the phase is an
			# atan2 mapped into 0 to 360, the amplitude is a ring torsion
			# divided by the cosine of that and Altona and Sundaralingam's
			# convention makes it positive, the name is the phase binned in
			# tens of degrees, and there are five nu or there is no pucker.
			# Whether the numbers are right is t/features.t's question.
			for my $rk (@{ $c->{residue_order} }) {
				my $r = $c->{residues}{$rk};
				next unless defined $r->{pucker_phase};
				my @name = ("C3'-endo", "C4'-exo", "O4'-endo", "C1'-exo", "C2'-endo",
				            "C3'-exo", "C4'-endo", "O4'-exo", "C1'-endo", "C2'-exo");
				my $where = "$name: $r->{resname} $cid/$rk";
				$n_puckers++;
				die "$where: pucker phase $r->{pucker_phase} is outside 0 to 360"
					unless $r->{pucker_phase} >= 0 && $r->{pucker_phase} < 360;
				die "$where: pucker amplitude $r->{pucker_amplitude} is not positive"
					unless $r->{pucker_amplitude} > 0;
				die "$where: pucker '$r->{pucker}' is not the name for that phase"
					unless $r->{pucker} eq $name[ int($r->{pucker_phase} / 36) ];
				die "$where: a pucker without five ring torsions"
					unless $r->{nu} && @{ $r->{nu} } == 5;
				die "$where: glycosidic '$r->{glycosidic}' does not match chi $r->{chi}"
					if defined $r->{chi}
					&& $r->{glycosidic} ne (abs($r->{chi}) <= 90 ? 'syn' : 'anti');
			}
			die "$name: chain $cid does not add up" if abs($residues - $c->{sasa}) > 1e-5;
		}
		cmp_ok(abs($atoms - $f->{sasa}{total}) / ($f->{sasa}{total} || 1), '<', 1e-9,
			"$name: the atoms account for the whole surface");
		cmp_ok(abs($chains - $f->{sasa}{total}) / ($f->{sasa}{total} || 1), '<', 1e-9,
			"$name: and so do the chains");
		cmp_ok($worst, '<', $cap, "$name: no atom is larger than the largest sphere there is");
		cmp_ok(abs($f->{sasa}{apolar} + $f->{sasa}{polar} - $f->{sasa}{total}), '<', 1e-6,
			"$name: apolar plus polar is the total");
		cmp_ok($f->{mass}, '>', 0, "$name: it weighs something");
		cmp_ok($f->{rg}, '>', 0, "$name: and has a radius of gyration");
		# half the longest side of the bounding box is a lower bound on the
		# radius of gyration only for a shell, so use the diagonal as the upper
		# one: no atom is further from the centroid than that
		my $bb = $info->{stats}{bbox};
		my $diag = sqrt(($bb->{xmax} - $bb->{xmin}) ** 2
		              + ($bb->{ymax} - $bb->{ymin}) ** 2
		              + ($bb->{zmax} - $bb->{zmin}) ** 2);
		cmp_ok($f->{rg}, '<', $diag, "$name: which is smaller than the bounding box diagonal");

		# The base pairs, again against what they are by construction: the two
		# residues are not the same one, every hydrogen bond and the stagger are
		# inside the thresholds the answer was found with, the Saenger type
		# matches the two letters, and both residues carry the pair.  Whether
		# the pairs are the right ones is t/features.t's question, against the
		# archive's own annotation.
		{
			my %res;
			for my $cid (@{ $info->{chain_order} }) {
				my $c = $info->{chains}{$cid};
				$res{"$cid/$_"} = $c->{residues}{$_} for @{ $c->{residue_order} };
			}
			my %saenger = ('G-C' => 19, 'C-G' => 19, 'A-U' => 20, 'U-A' => 20,
			               'A-T' => 20, 'T-A' => 20, 'G-U' => 28, 'U-G' => 28,
			               'G-T' => 28, 'T-G' => 28);
			for my $bp (@{ $f->{base_pairs} }) {
				my $k1 = "$bp->{chain1}/$bp->{residue1}";
				my $k2 = "$bp->{chain2}/$bp->{residue2}";
				my $where = "$name: base pair $k1 $k2";
				$n_pairs++;
				die "$where: a residue paired with itself" if $k1 eq $k2;
				die "$where: type '$bp->{type}' is not a canonical pair"
					unless $saenger{ $bp->{type} };
				die "$where: type $bp->{type} is not Saenger $bp->{saenger}"
					unless $saenger{ $bp->{type} } == $bp->{saenger};
				die "$where: Saenger $bp->{saenger} wants "
				  . ($bp->{saenger} == 19 ? 3 : 2) . ' hydrogen bonds'
					unless @{ $bp->{hbonds} } == ($bp->{saenger} == 19 ? 3 : 2);
				for my $h (@{ $bp->{hbonds} }) {
					die "$where: a hydrogen bond of $h->{distance} A"
						if $h->{distance} > 3.5;
				}
				die "$where: a stagger of $bp->{stagger} A" if $bp->{stagger} > 2.6;
				die "$where: a plane angle of $bp->{plane_angle} degrees"
					if $bp->{plane_angle} < 0 || $bp->{plane_angle} > 90;
				for my $end ([ $k1, $bp->{chain2}, $bp->{residue2} ],
				             [ $k2, $bp->{chain1}, $bp->{residue1} ]) {
					my ($me, $yc, $yr) = @$end;
					die "$where: $me does not carry the pair"
						unless grep { $_->{chain} eq $yc && $_->{residue} eq $yr }
						       @{ $res{$me}{base_pair} || [] };
				}
			}
		}

		# The base stacks, on the same terms: the pair is inside both of the
		# cutoffs it was found with, Xi is there exactly when the overlap angle
		# is inside its own, the score is in the range the paper gives it, and
		# both residues carry the stack.  Whether the numbers are right is
		# t/stacking.t's question, against the paper's Figure 4.
		{
			my %res;
			for my $cid (@{ $info->{chain_order} }) {
				my $c = $info->{chains}{$cid};
				$res{"$cid/$_"} = $c->{residues}{$_} for @{ $c->{residue_order} };
			}
			for my $s (@{ $f->{base_stacks} }) {
				my $k1 = "$s->{chain1}/$s->{residue1}";
				my $k2 = "$s->{chain2}/$s->{residue2}";
				my $where = "$name: base stack $k1 $k2";
				$n_stacks++;
				die "$where: a base stacked on itself" if $k1 eq $k2;
				die "$where: a separation of $s->{distance} A"
					if $s->{distance} > 5.0;
				die "$where: an overlap angle of $s->{omega} degrees"
					if $s->{omega} < 0 || $s->{omega} > 180;
				if ($s->{omega} <= 50) {
					die "$where: inside the overlap cutoff and carries no Xi"
						unless defined $s->{xi};
					die "$where: a Xi of $s->{xi} degrees"
						if $s->{xi} < 0 || $s->{xi} > 90;
				} else {
					die "$where: past the overlap cutoff and carries a Xi"
						if exists $s->{xi};
					die "$where: past the overlap cutoff and scores $s->{score}"
						if $s->{score} != 0;
				}
				die "$where: a score of $s->{score}%"
					if $s->{score} < -100 || $s->{score} > 100;
				die "$where: stacked is $s->{stacked} at $s->{score}%"
					unless $s->{stacked} == ($s->{score} > 50 ? 1 : 0);
				for my $end ([ $k1, $s->{chain2}, $s->{residue2}, "5'" ],
				             [ $k2, $s->{chain1}, $s->{residue1}, "3'" ]) {
					my ($me, $yc, $yr, $side) = @$end;
					die "$where: $me does not carry the stack, or not as the $side base"
						unless grep { $_->{chain} eq $yc && $_->{residue} eq $yr
						              && $_->{side} eq $side }
						       @{ $res{$me}{base_stack} || [] };
				}
			}
		}

		for my $s (@{ $f->{pi_stacking} }) {
			$n_ring_pairs++;
			my $where = "$name: $s->{chain1}/$s->{residue1}/$s->{ring1}"
			          . " with $s->{chain2}/$s->{residue2}/$s->{ring2}";
			# a pair of rings on one residue is fused, not stacked
			isnt("$s->{chain1}/$s->{residue1}", "$s->{chain2}/$s->{residue2}",
				"$where: two different residues")
				if "$s->{chain1}/$s->{residue1}" eq "$s->{chain2}/$s->{residue2}";
			my ($far, $lo, $hi) = $s->{type} eq 'face' ? (5.5, 0, 35) : (6.5, 50, 90);
			ok($s->{distance} <= $far + 1e-9, "$where: inside its centroid cutoff")
				if $s->{distance} > $far + 1e-9;
			ok($s->{plane_angle} >= $lo - 1e-9 && $s->{plane_angle} <= $hi + 1e-9,
				"$where: inside its plane angle range")
				if $s->{plane_angle} < $lo - 1e-9 || $s->{plane_angle} > $hi + 1e-9;
		}
	}
	# --- the disulfides the coordinates show, against the ones the file
	#     declares in its SSBOND records ---------------------------------------
	#
	# Two independent answers to the same question, one computed here and one
	# written by the depositor, so a disagreement is a fact about the entry
	# rather than a failure of either.  On the default spread all 18 entries
	# that have disulfides agree; over a wider sweep of PDBbind they agree on 21
	# of 22, and the one that does not is 1A4K, a Fab present in the file twice,
	# whose SSBOND records cover one copy and whose coordinates show both.  That
	# is why this is counted across the corpus the way the SEQRES check above
	# is, rather than asserted per file.
	#
	# The declared length is also worth reading: SSBOND carries the distance the
	# depositor measured, to two decimals, so where both name the same pair the
	# two numbers can be compared outright.
	{
		# @differ last, and declared on its own: an array in the middle of a list
		# assignment swallows every value after it
		my ($entries, $paired, $worst) = (0, 0, 0);
		my @differ;
		# every file of the spread, not the twelve the surface uses: finding the
		# disulfides touches the cysteines and nothing else, so it costs about
		# what reading the file costs and the corpus is worth having whole
		for my $file (@files) {
			my $name = (split m{/}, $file)[-1];
			my $info = eval { structure_info($file, features => 0) } or next;
			my $found = structure_disulfides($info);
			my $said  = $info->{ssbond} || [];
			next unless @$found || @$said;
			$entries++;
			my %got = map { join('|', sort("$_->{chain1}/$_->{residue1}",
			                               "$_->{chain2}/$_->{residue2}")) => $_->{distance} }
			          @$found;
			my %want;
			for my $b (@$said) {
				my $k = join('|', sort("$b->{chain1}/$b->{resseq1}",
				                       "$b->{chain2}/$b->{resseq2}"));
				$want{$k} = $b->{length};
			}
			push @differ, sprintf('%s: found %d, declared %d', $name,
				scalar keys %got, scalar keys %want)
				unless join(',', sort keys %got) eq join(',', sort keys %want);
			for my $k (keys %want) {
				next unless exists $got{$k} && defined $want{$k} && $want{$k} > 0;
				$paired++;
				my $d = abs($got{$k} - $want{$k});
				$worst = $d if $d > $worst;
			}
		}
		diag("computed and declared disulfides differ: $_") for @differ;
		ok(@differ <= $entries / 5,
			sprintf('the disulfides found match the ones declared in all but a few entries (%d of %d)',
				scalar @differ, $entries));
		# SSBOND writes the length in two decimals, so rounding alone allows
		# 0.005 A, and the observed worst over the spread is 0.0055 A across 82
		# bonds -- a whisker past rounding, which is what refinement does.  The bound
		# is 0.01, one further step, because a re-refined entry can carry a
		# length measured before the last round of refinement; anything past
		# that would mean the two are measuring different atoms.
		cmp_ok($worst, '<', 0.01,
			sprintf('and where both name a bond, the lengths agree (%d bonds, worst %.4f A)',
				$paired, $worst));
	}

	ok($checked_features > 0, 'the physical properties were computed on real structures');
	diag("computed the properties of $checked_features structures, "
	   . "$n_ring_pairs stacked ring pairs, $n_puckers sugar puckers, "
	   . "$n_pairs base pairs and $n_stacks base stacks between them");
}

diag("checked $checked structures");
done_testing();
