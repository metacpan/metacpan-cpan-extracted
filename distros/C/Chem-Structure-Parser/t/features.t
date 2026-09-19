#!/usr/bin/env perl
# The physical properties, against the implementations they came from.
#
# structure_features(), structure_sasa() and structure_pi_stacking() are
# translations: the Shrake-Rupley surface, the van der Waals radii, the ring
# geometry and the atomic masses are all mdtraj's, and the two sequence numbers
# are Biopython's.  So this compares against those, not against what this module
# currently does.
#
#   mdtraj 1.11.1 -- mdtraj.geometry.shrake_rupley, mdtraj.geometry.pi_stacking,
#     mdtraj.geometry.compute_rg and mdtraj/core/element.py.  What it answered
#     for every structure in t/data is frozen in t/data/features.txt, written by
#     t/data/features.pl from t/data/features.py; the test reads that so the
#     comparison runs on a machine with no python, and re-runs features.py where
#     mdtraj is importable so the frozen answer cannot go stale.
#   Biopython 1.87 -- Bio.SeqUtils.ProtParam.ProteinAnalysis.gravy() and
#     .aromaticity(), the Kyte-Doolittle scale of Bio.SeqUtils.ProtParamData.kd,
#     and Bio.SeqUtils.gc_fraction() for the nucleic acid half.  Those take a
#     sequence rather than a structure, so their answers are written out below
#     as fixtures the way t/foreign.t writes its cases down, with the sequence
#     each came from.
#   gemmi 0.7.5 -- calculate_dihedral(), as a second opinion on the nucleic acid
#     torsions.  mdtraj has no compute_alpha() and no equivalent, so features.py
#     names the four atoms of each torsion itself, from the IUPAC-IUB (1983)
#     definitions, and runs them through both readers' dihedral kernels; the
#     frozen line carries both answers and this checks against both.
#   3DNA, at one remove -- no reader here finds base pairs, so the base pair
#     answers are the wwPDB's own annotation of the entries the fixtures were
#     lifted from, which is 3DNA's: the _ndb_struct_na_base_pair loop of
#     1BNA.cif and 1MSY.cif, written out below the way t/foreign.t writes its
#     cases down.  The geometry those pairs are found by is measured by mdtraj
#     and gemmi in features.py and checked against both.
#
# Set STRUCTURE_INFO_PYTHON to a python that can import mdtraj and numpy to run
# the live half as well; /home/con/.pyenv/versions/3.14.2/bin/python3 is one.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Basename 'dirname';
use File::Spec;
use Chem::Structure::Parser qw(
	structure_info structure_features structure_sasa structure_pi_stacking
	structure_disulfides structure_base_pairs structure_dssp
);

my $dir = File::Spec->catdir(dirname(__FILE__), 'data');

# ---- the frozen answer ---------------------------------------------------

# One section per structure, '== <file>' or '== <file> refused'.  A refused
# file is one mdtraj will not read at all and there is nothing to compare.
sub read_frozen {
	my ($path) = @_;
	open my $fh, '<', $path or die "$path: $!";
	my (%sec, $cur);
	while (my $l = <$fh>) {
		chomp $l;
		if ($l =~ /\A== (\S+)(?:\s+(refused))?\z/) {
			$cur = $1;
			$sec{$cur} = $2 ? undef : [];
			next;
		}
		next unless defined $cur && defined $sec{$cur};
		next if $l =~ /\A#/ || !length $l;
		push @{ $sec{$cur} }, $l;
	}
	close $fh;
	return \%sec;
}

my $frozen = read_frozen(File::Spec->catfile($dir, 'features.txt'));
ok(scalar(keys %$frozen) > 0, 'features.txt holds answers to compare against');

# every structure in t/data has an answer, so that adding one without re-running
# the generator is a failure rather than a silently smaller test
{
	opendir(my $dh, $dir) or die "$dir: $!";
	my @have = sort grep { /\.(?:pdb|ent|cif|mmcif)\z/ } readdir $dh;
	closedir $dh;
	my @missing = grep { !exists $frozen->{$_} } @have;
	is_deeply(\@missing, [], 'features.txt has an answer for every structure in t/data')
		or diag('re-run t/data/features.pl with STRUCTURE_INFO_PYTHON set');
}

# ---- what this module says -----------------------------------------------

# The residues of a structure in the order the file wrote them, which is the
# order mdtraj indexes them in.  Chains are not part of the key: mdtraj takes an
# mmCIF file's chains from label_asym_id rather than auth_asym_id, so mini.cif's
# one protein chain is three chains to it, in the same order.
sub walk {
	my ($info) = @_;
	my @res;
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		push @res, $c->{residues}{$_} for @{ $c->{residue_order} };
	}
	return \@res;
}

# a stacked pair, named the way the frozen file names it: the two residues'
# positions in that walk, and which of their rings it was
sub pair_key {
	my ($res, $s) = @_;
	my %at = map { $res->[$_]{chain} . '/' . $res->[$_]{key} => $_ } 0 .. $#$res;
	my @e = sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] }
	        [ $at{"$s->{chain1}/$s->{residue1}"}, $s->{ring1} ],
	        [ $at{"$s->{chain2}/$s->{residue2}"}, $s->{ring2} ];
	return join ' ', map { defined $_->[0] ? "$_->[0]|$_->[1]" : '?' } @e;
}

# ---- the comparison ------------------------------------------------------
#
# Two tolerances, and they are different in kind.
#
# Against the float64 column -- mdtraj's own loop with the dtype changed -- the
# answers are the same calculation and agree to the last digit the generator
# prints.  The observed largest disagreement over every atom and residue of
# every structure in t/data is 4e-9 A^2 absolute, which is the 1e-9 the
# generator rounds to; 1e-7 leaves two orders of magnitude of headroom on that
# and would still catch a single sphere point, the smallest real difference
# there is (0.126 A^2 for a carbon).
#
# Against the float32 column -- mdtraj as it ships -- an atom can differ by a
# whole sphere point, because a point sitting within a float32 ulp of a
# neighbouring atom's surface is accessible at one width and covered at the
# other.  The generator prints what one point is worth for each atom, so the
# bound is one point and does not need a copy of the radius table here.  Over
# t/data that happens to four atoms of 620; the test allows one point everywhere
# rather than recording which four, because which four is a property of float32
# rounding and not of either implementation.
#
# Plus a millionth of the area, because mdtraj's number is itself a float32: an
# atom's area is a count of points times the point value, and both the product
# and the sum that follows it are rounded to 24 bits, so an atom that really is
# one point apart comes out 1.0000025 points apart on mini.pdb.  float32's
# relative epsilon is 1.19e-7, so 1e-6 is most of an order of magnitude of
# headroom and is still a hundredth of the point it is added to.
my $EXACT = 1e-7;

sub compare {
	my ($file, $rows) = @_;
	my $info = structure_info(File::Spec->catfile($dir, $file));
	my $feat = structure_features($info);
	my $res  = walk($info);

	my ($n_atom, $n_res, $worst64, $worst32) = (0, 0, 0, 0);
	my (%want_pi, %want_ss, %want_alone, %want_tors, %want_cont, %want_hse,
	    %want_hb, %want_dssp, %want_nuc, %want_pucker, %want_bp, %seen_res);
	for my $l (@$rows) {
		my @w = split ' ', $l;
		if ($w[0] eq 'A') {
			my ($ri, $name) = split /\|/, $w[1], 2;
			my ($a32, $a64, $pt) = @w[2, 3, 4];
			my $atom = $res->[$ri] ? $res->[$ri]{atoms}{$name} : undef;
			unless ($atom && defined $atom->{sasa}) {
				fail("$file: atom $w[1] is in mdtraj's answer and not in this one");
				next;
			}
			$n_atom++;
			my $d64 = abs($atom->{sasa} - $a64);
			my $d32 = abs($atom->{sasa} - $a32);
			$worst64 = $d64 if $d64 > $worst64;
			my $allow = $pt + 1e-6 * $a32;
			$worst32 = $d32 / $allow if $allow > 0 && $d32 / $allow > $worst32;
		} elsif ($w[0] eq 'R') {
			my ($ri, undef, $num, $name, $a32, $a64) = @w[1 .. 6];
			my $r = $res->[$ri];
			unless ($r) {
				fail("$file: residue $ri is in mdtraj's answer and not in this one");
				next;
			}
			$seen_res{$ri} = 1;
			$n_res++ if $r->{number} == $num && $r->{resname} eq $name;
			my $d64 = abs(($r->{sasa} || 0) - $a64);
			$worst64 = $d64 if $d64 > $worst64;
		} elsif ($w[0] eq 'T') {
			my $name = $w[1];
			if ($name eq 'sasa') {
				cmp_ok(abs($feat->{sasa}{total} - $w[3]), '<', $EXACT,
					"$file: total surface, against the float64 kernel");
				cmp_ok(abs($feat->{sasa}{total} - $w[2]), '<=', $w[4] + 1e-6 * $w[2],
					"$file: total surface, within one point per atom of mdtraj");
			} elsif ($name eq 'mass') {
				cmp_ok(abs($feat->{mass} - $w[2]), '<', 1e-6,
					"$file: mass, against mdtraj's element table");
			} elsif ($name eq 'rg') {
				# mdtraj's compute_rg() default is equal weights, so the centre
				# it measures from is the centroid and the two are the same
				# quantity.  Its xyz is float32 nanometres, which is why this is
				# a relative tolerance and the surfaces above are absolute.
				cmp_ok(abs($feat->{rg} - $w[2]) / $w[2], '<', 1e-6,
					"$file: radius of gyration");
			} elsif ($name eq 'rg_mass') {
				cmp_ok(abs($feat->{rg_mass} - $w[2]) / $w[2], '<', 1e-6,
					"$file: mass-weighted radius of gyration, about the centre of mass");
			} elsif ($name eq 'center' || $name eq 'com') {
				my $got = $feat->{ $name eq 'center' ? 'center' : 'center_of_mass' };
				my $off = 0;
				for my $k (0 .. 2) {
					my $d = abs($got->[$k] - $w[2 + $k]);
					$off = $d if $d > $off;
				}
				cmp_ok($off, '<', 1e-5, "$file: $name");
			}
		} elsif ($w[0] eq 'P') {
			$want_pi{"$w[1] $w[2]"} = 1;
		} elsif ($w[0] eq 'S') {
			$want_ss{"$w[1] $w[2]"} = $w[3];
		} elsif ($w[0] eq 'B') {
			$want_hb{"$w[1] $w[2]"} = [ $w[3], $w[4] ];   # energy, is the link real
		} elsif ($w[0] eq 'X') {
			$want_dssp{$w[1]} = $w[2];
		} elsif ($w[0] eq 'C') {
			$want_cont{"$w[1] $w[2]"} = $w[3];
		} elsif ($w[0] eq 'H') {
			$want_hse{"$w[1]|$w[2]" . ($w[3] eq '-' ? '' : $w[3])} = [ $w[4], $w[5] ];
		} elsif ($w[0] eq 'D') {
			# value, is the link real, is the angle defined at all
			$want_tors{"$w[1] $w[2]"} = [ @w[3 .. 5] ];
		} elsif ($w[0] eq 'N') {
			# mdtraj's angle, gemmi's or '-', is the link real, is it defined
			$want_nuc{"$w[1] $w[2]"} = [ @w[3 .. 6] ];
		} elsif ($w[0] eq 'Q') {
			$want_pucker{$w[1]} = [ $w[2], $w[3] ];   # phase, amplitude
		} elsif ($w[0] eq 'W') {
			# the two letters, the Saenger type, then mdtraj's centroid
			# distance, plane angle, stagger and hydrogen bonds, and gemmi's
			my $n = $w[5];
			$want_bp{"$w[1] $w[2]"} = {
				letters => $w[3], saenger => $w[4],
				mdtraj  => [ @w[6 .. 8 + $n] ],
				gemmi   => ($w[9 + $n] eq '-' ? undef : [ @w[9 + $n .. 11 + 2 * $n] ]),
			};
		} elsif ($w[0] eq 'I') {
			$want_alone{$w[1]} = [ @w[2 .. 5] ];   # n_atoms, f32, f64, one point
		}
	}

	cmp_ok($worst64, '<', $EXACT,
		sprintf('%s: every atom and residue surface matches the float64 kernel (worst %.2e)',
			$file, $worst64));
	cmp_ok($worst32, '<=', 1.0,
		sprintf('%s: no atom differs from mdtraj by more than one sphere point', $file));
	is($n_res, scalar keys %seen_res,
		"$file: every residue mdtraj found is here, with the same number and name");
	ok($n_atom > 0, "$file: atoms were compared");

	my %got_pi = map { pair_key($res, $_) => 1 } @{ $feat->{pi_stacking} };
	is_deeply([ sort keys %got_pi ], [ sort keys %want_pi ],
		"$file: the same stacked pairs of rings as mdtraj");

	# Backbone hydrogen bonds, against mdtraj's kabsch_sander.  Exact: over the
	# real entries this was developed against -- 1A42, 1A22, 1AHW and 3AU6 --
	# the two agree on which bonds exist and on their energies to 4e-5 kcal/mol,
	# which is float32 rounding on mdtraj's side.  The only bonds not required
	# to be here are the ones whose amide hydrogen mdtraj placed from a residue
	# that is not peptide-bonded to the donor; see the block in Parser.xs.
	{
		my %index = map { $res->[$_]{chain} . '/' . $res->[$_]{key} => $_ } 0 .. $#$res;
		my %got;
		for my $b (@{ $feat->{hbonds} }) {
			my $a = $index{"$b->{acceptor_chain}/$b->{acceptor_residue}"};
			my $d = $index{"$b->{donor_chain}/$b->{donor_residue}"};
			$got{"$a $d"} = $b->{energy} if defined $a && defined $d;
		}
		my ($n, $worst, @missing, @extra) = (0, 0);
		for my $k (sort keys %want_hb) {
			my ($e, $real) = @{ $want_hb{$k} };
			if (!$real) {
				push @extra, $k if exists $got{$k};
				next;
			}
			unless (exists $got{$k}) { push @missing, $k; next }
			$n++;
			my $d = abs($got{$k} - $e);
			$worst = $d if $d > $worst;
		}
		is_deeply(\@missing, [], "$file: every hydrogen bond mdtraj found is here");
		is_deeply(\@extra, [],
			"$file: and none whose hydrogen mdtraj built from an unbonded residue");
		my @unknown = grep { !exists $want_hb{$_} } sort keys %got;
		is_deeply(\@unknown, [], "$file: and none mdtraj did not find");
		cmp_ok($worst, '<', 1e-4,
			sprintf('%s: %d hydrogen bond energies, worst %.2e kcal/mol', $file, $n, $worst));
	}

	# Residue contacts, mdtraj's closest-heavy scheme.  Only the pairs mdtraj's
	# `all' considers are frozen -- same chain, three or more apart in it -- so
	# this checks that every one of those under the cutoff is here with the same
	# distance, and that none over it is.  The neighbouring and cross-chain pairs
	# this module also reports are not mdtraj's to have an opinion about.
	{
		my %got;
		my %index = map { $res->[$_]{chain} . '/' . $res->[$_]{key} => $_ } 0 .. $#$res;
		for my $ct (@{ $feat->{contacts} }) {
			my @e = sort { $a <=> $b } $index{"$ct->{chain1}/$ct->{residue1}"},
			                           $index{"$ct->{chain2}/$ct->{residue2}"};
			$got{"$e[0] $e[1]"} = $ct->{distance};
		}
		my $cut = 4.5;   # structure_features' contact_distance default
		my ($n, $worst) = (0, 0);
		for my $k (sort keys %want_cont) {
			my $want = $want_cont{$k};
			if ($want <= $cut) {
				unless (exists $got{$k}) {
					fail("$file: residues $k are $want A apart and are not in the contacts");
					next;
				}
				$n++;
				my $d = abs($got{$k} - $want);
				$worst = $d if $d > $worst;
			} elsif (exists $got{$k}) {
				fail("$file: residues $k are $want A apart and should not be a contact");
			}
		}
		# a distance off float32 nanometre coordinates, as the disulfides are
		cmp_ok($worst, '<', 1e-5,
			sprintf('%s: %d contacts mdtraj also found, at the same distance (worst %.2e)',
				$file, $n, $worst));
	}

	# Half-sphere exposure, Biopython's HSExposureCB.  Keyed on the residue the
	# way this module keys one, so an insertion code is part of the name.
	for my $k (sort keys %want_hse) {
		my ($cid, $rk) = split /\|/, $k, 2;
		my $c = $info->{chains}{ $cid eq '-' ? '' : $cid };
		my $r = $c && $c->{residues}{$rk};
		unless ($r) {
			fail("$file: Biopython has a residue $k and this does not");
			next;
		}
		is($r->{hse_up},   $want_hse{$k}[0], "$file: residue $k hse_up");
		is($r->{hse_down}, $want_hse{$k}[1], "$file: residue $k hse_down");
	}

	# Torsion angles.  mdtraj computes a phi or a psi between whichever residues
	# are next to each other in the file, so a chain with a gap in it gets one
	# measured across the gap; this module asks first whether the two are
	# peptide-bonded, at Biopython's PPBuilder radius.  So the frozen line
	# carries mdtraj's angle and whether the link is real, and both halves are
	# checked: the angle where it is, and no angle at all where it is not.
	#
	# The tolerance is on an angle derived from float32 nanometre coordinates,
	# and an angle is a ratio of differences of them, so it loses more than a
	# distance does: the largest disagreement over t/data is 2.5e-4 degrees, and
	# the bound is 1e-3.
	for my $k (sort keys %want_tors) {
		my ($ri, $what) = split ' ', $k;
		my ($value, $real, $defined) = @{ $want_tors{$k} };
		my $r = $res->[$ri] or next;
		my $got = $what =~ /\Achi([0-9])\z/
		        ? ($r->{chi} ? $r->{chi}[$1 - 1] : undef)
		        : $r->{$what};
		if (!$real) {
			ok(!defined $got,
				"$file: residue $ri has no $what, because the residues it would span are not bonded");
			next;
		}
		if (!$defined) {
			ok(!defined $got,
				"$file: residue $ri has no $what, because its four atoms are collinear");
			next;
		}
		unless (defined $got) {
			fail("$file: residue $ri has no $what and mdtraj measured one");
			next;
		}
		# an angle wraps, so 180 and -180 are the same place
		my $d = abs($got - $value);
		$d = abs($d - 360) if $d > 180;
		cmp_ok($d, '<', 1e-3, "$file: residue $ri $what");
	}

	# Nucleic acid torsions.  Two readers rather than one: features.py names the
	# four atoms of each from the IUPAC-IUB definitions and runs them through
	# mdtraj's compute_dihedrals() and gemmi's calculate_dihedral(), and both
	# answers are on the frozen line.  The gemmi column is '-' where gemmi
	# refuses the file or splits it into a different number of residues, which
	# is a fact about gemmi and not a licence to skip the mdtraj half.
	#
	# The linked flag rides along the way it does for phi and psi, and for the
	# same reason: an alpha, an epsilon or a zeta spans two residues, and one
	# measured across a gap in the model is a number rather than an answer.
	# features.py applies gemmi's own phosphodiester rule to decide, which is
	# the rule Parser.xs applies.
	#
	# Tolerances.  Against mdtraj, 1e-3 degrees: the same bound the protein
	# torsions use, for the same reason -- mdtraj's coordinates are float32
	# nanometres and an angle is a ratio of differences of them.  The largest
	# disagreement over t/data is 1.9e-4 degrees.
	#
	# Against gemmi, 1e-8, because there is nothing left to disagree about:
	# gemmi reads the same decimal columns into the same double and does the
	# same arithmetic on them, so what is measured here is how far the frozen
	# file's nine decimal places round.  The largest disagreement over t/data is
	# 5.0e-10 degrees, which is that rounding and nothing else; 1e-8 is twenty
	# times it and is still five orders of magnitude below the mdtraj bound, so
	# a real difference in the atoms picked would not fit through it.
	for my $k (sort keys %want_nuc) {
		my ($ri, $what) = split ' ', $k;
		my ($value, $gemmi, $real, $defined) = @{ $want_nuc{$k} };
		my $r = $res->[$ri] or next;
		my $got = $what =~ /\Anu([0-4])\z/
		        ? ($r->{nu} ? $r->{nu}[$1] : undef)
		        : $r->{$what};
		if (!$real) {
			ok(!defined $got, "$file: residue $ri has no $what, "
			 . 'because the residues it would span are not bonded');
			next;
		}
		if (!$defined) {
			ok(!defined $got,
				"$file: residue $ri has no $what, because its four atoms are collinear");
			next;
		}
		unless (defined $got) {
			fail("$file: residue $ri has no $what and mdtraj measured one");
			next;
		}
		for my $want ([ $value, 1e-3, 'mdtraj' ],
		              ($gemmi eq '-' ? () : [ $gemmi, 1e-8, 'gemmi' ])) {
			# an angle wraps, so 180 and -180 are the same place
			my $d = abs($got - $want->[0]);
			$d = abs($d - 360) if $d > 180;
			cmp_ok($d, '<', $want->[1], "$file: residue $ri $what, against $want->[2]");
		}
	}

	# The sugar pucker, from those torsions through Altona and Sundaralingam's
	# equations.  features.py works it out from mdtraj's five nu in degrees and
	# Parser.xs from its own five in radians, so this is the two transcriptions
	# of one published formula agreeing, on top of the torsions agreeing above.
	# The phase inherits the torsions' 1e-3; the amplitude is nu2 divided by a
	# cosine of it, so it inherits it too.  The largest disagreement over t/data
	# is 1.4e-4 degrees on the phase and 1.1e-4 on the amplitude.
	for my $ri (sort { $a <=> $b } keys %want_pucker) {
		my ($phase, $amp) = @{ $want_pucker{$ri} };
		my $r = $res->[$ri] or next;
		unless (defined $r->{pucker_phase}) {
			fail("$file: residue $ri has no pucker and mdtraj's torsions give one");
			next;
		}
		my $d = abs($r->{pucker_phase} - $phase);
		$d = abs($d - 360) if $d > 180;      # the cycle wraps at 0 as an angle does
		cmp_ok($d, '<', 1e-3, "$file: residue $ri pseudorotation phase");
		cmp_ok(abs($r->{pucker_amplitude} - $amp), '<', 1e-3,
			"$file: residue $ri pucker amplitude");
		# the name is the phase binned in tens, so it follows from the number --
		# what is checked is that the bin edges are where they are said to be
		my @name = ("C3'-endo", "C4'-exo", "O4'-endo", "C1'-exo", "C2'-endo",
		            "C3'-exo", "C4'-endo", "O4'-exo", "C1'-endo", "C2'-exo");
		is($r->{pucker}, $name[ int($phase / 36) ],
			"$file: residue $ri pucker name for a phase of " . sprintf('%.1f', $phase));
		# and that the glycosidic label bisects chi where it is said to
		is($r->{glycosidic}, abs($r->{chi}) <= 90 ? 'syn' : 'anti',
			"$file: residue $ri glycosidic conformation")
			if defined $r->{chi};
	}

	# A residue mdtraj found no nucleic torsion for must have none here either,
	# so that a fixture with no nucleotide in it is a check and not a gap.
	{
		my @extra;
		for my $i (0 .. $#$res) {
			for my $what (qw(alpha beta gamma delta epsilon zeta nu
			                 pucker pucker_phase pucker_amplitude glycosidic)) {
				next unless defined $res->[$i]{$what};
				my $key = $what =~ /\Apucker|\Aglycosidic\z/ ? "$i nu2" : "$i $what";
				$key = "$i nu0" if $what eq 'nu';
				push @extra, "$i $what" unless exists $want_nuc{$key};
			}
		}
		is_deeply(\@extra, [], "$file: no nucleic torsion here that mdtraj did not measure");
	}

	# Base pairs.  features.py measures every pair of complementary bases the
	# screen in Parser.xs would look at, through mdtraj's kernel and gemmi's;
	# the rule is applied to those numbers here, so what is compared is the set
	# this module reports against the set the frozen geometry says it should
	# report -- both ways round, so a pair too many fails as loudly as one too
	# few.  Where the fixture's pairs are the wwPDB's annotation of the entry
	# they were lifted from is checked separately, below.
	#
	# The thresholds are structure_features()'s defaults, named once here.  No
	# candidate in t/data comes anywhere near either of them.  Of the 18 pairs
	# accepted the tightest has 0.27 A of hydrogen bond and 1.92 A of stagger in
	# hand; of the 58 rejected the nearest miss is 0.72 A outside.  So which
	# side of the rule a fixture falls on cannot turn on a rounding difference
	# between the two implementations.
	{
		my $HB = 3.5;   # base_pair_hbond
		my $SAG = 2.6;  # base_pair_stagger
		my %ix = map { $res->[$_]{chain} . '/' . $res->[$_]{key} => $_ } 0 .. $#$res;
		my %got;
		for my $bp (@{ $feat->{base_pairs} }) {
			my $i = $ix{"$bp->{chain1}/$bp->{residue1}"};
			my $j = $ix{"$bp->{chain2}/$bp->{residue2}"};
			unless (defined $i && defined $j) {
				fail("$file: a base pair names a residue that is not in the walk");
				next;
			}
			$got{join ' ', sort { $a <=> $b } ($i, $j)} = $bp;
		}
		my @want;
		for my $k (sort keys %want_bp) {
			# gemmi's numbers where there are any: they are float64 from the
			# same decimal columns, where mdtraj's are float32
			my $w = $want_bp{$k};
			my $m = $w->{gemmi} || $w->{mdtraj};
			my ($d, $ang, $sag, @bond) = @$m;
			next if $sag > $SAG;
			next if grep { $_ > $HB } @bond;
			push @want, $k;
		}
		is_deeply([ sort keys %got ], [ sort @want ],
			"$file: the base pairs are the ones the frozen geometry says");
		for my $k (@want) {
			my $bp = $got{$k} or next;
			my $w = $want_bp{$k};
			is($bp->{saenger}, $w->{saenger}, "$file: base pair $k is Saenger type $w->{saenger}");
			is($bp->{type}, join('-', split //, $w->{letters}),
				"$file: base pair $k is $w->{letters}");
			for my $ref ([ $w->{mdtraj}, 1e-4, 'mdtraj' ],
			             ($w->{gemmi} ? [ $w->{gemmi}, 1e-8, 'gemmi' ] : ())) {
				my ($m, $tol, $who) = @$ref;
				my ($d, $ang, $sag, @bond) = @$m;
				cmp_ok(abs($bp->{distance} - $d), '<', $tol,
					"$file: base pair $k centroid distance, against $who");
				cmp_ok(abs($bp->{plane_angle} - $ang), '<', $tol,
					"$file: base pair $k plane angle, against $who");
				cmp_ok(abs($bp->{stagger} - $sag), '<', $tol,
					"$file: base pair $k stagger, against $who");
				my @h = map { $_->{distance} } @{ $bp->{hbonds} };
				is(scalar @h, scalar @bond, "$file: base pair $k has " . @bond . ' hydrogen bonds');
				for my $i (0 .. $#bond) {
					cmp_ok(abs(($h[$i] // 0) - $bond[$i]), '<', $tol,
						"$file: base pair $k hydrogen bond $i, against $who");
				}
			}
			# and each of the two residues carries the other
			for my $end ([ 1, 2 ], [ 2, 1 ]) {
				my ($me, $you) = @$end;
				my ($mc, $mr) = ($bp->{"chain$me"}, $bp->{"residue$me"});
				my ($yc, $yr) = ($bp->{"chain$you"}, $bp->{"residue$you"});
				my $r = $res->[ $ix{"$mc/$mr"} ];
				my ($note) = grep { $_->{residue} eq $yr && $_->{chain} eq $yc }
				             @{ $r->{base_pair} || [] };
				ok($note, "$file: base pair $k is on residue $me as well");
				is($note->{saenger}, $bp->{saenger},
					"$file: and with the same Saenger type") if $note;
			}
		}
		# nothing carries a base_pair note that is not in the list
		my $notes = 0;
		$notes += scalar @{ $res->[$_]{base_pair} || [] } for 0 .. $#$res;
		is($notes, 2 * scalar(keys %got),
			"$file: every base pair is noted on both of its residues and nowhere else");
	}

	# Each chain's surface on its own, which with the surface it has in the
	# structure is what the chains bury between them.  Only PDB files carry
	# these lines: see the head of features.py for why an mmCIF file has no
	# author chain id for mdtraj to group by.
	for my $cid (sort keys %want_alone) {
		my ($n, $a32, $a64, $pt) = @{ $want_alone{$cid} };
		my $c = $info->{chains}{ $cid eq '-' ? '' : $cid };
		unless ($c) {
			fail("$file: mdtraj has a chain '$cid' and this does not");
			next;
		}
		cmp_ok(abs($c->{sasa_alone} - $a64), '<', $EXACT,
			"$file: chain $cid on its own, against the float64 kernel");
		cmp_ok(abs($c->{sasa_alone} - $a32), '<=', $pt + 1e-6 * $a32,
			"$file: chain $cid on its own, within one point per atom of mdtraj");
		cmp_ok(abs($c->{buried} - ($c->{sasa_alone} - $c->{sasa})), '<', 1e-9,
			"$file: chain $cid buries what it lost");
	}

	# Secondary structure.  Exactly mdtraj's, letter for letter: the assignment
	# is mdtraj's own dssp.cpp transcribed, on a hydrogen bond table built to
	# mdtraj's rules rather than to this module's, and there is nothing to be
	# within a tolerance of.  A residue that disagrees is a bug, not a rounding.
	#
	# sheet.pdb is the one with the whole dictionary in it -- H, G, I, E, B, T,
	# S and coil, all eight -- and it is here for this comparison: the beta half
	# of the assignment is most of the code, and before it was added no fixture
	# had a strand in it.
	if (%want_dssp) {
		my ($n, $bad) = (0, 0);
		my %simple = (H => 'H', G => 'H', I => 'H', E => 'E', B => 'E',
		              T => 'C', S => 'C', '_' => 'C');
		for my $ri (sort { $a <=> $b } keys %want_dssp) {
			my $want = $want_dssp{$ri};
			next if $want eq 'NA';
			my $r = $res->[$ri] or next;
			my $got = defined $r->{ss} ? $r->{ss} : undef;
			unless (defined $got) {
				fail("$file: residue $ri has no secondary structure and mdtraj gave it $want");
				next;
			}
			$got = '_' if $got eq ' ';
			$n++;
			if ($got ne $want) {
				$bad++;
				fail("$file: residue $ri is $want to mdtraj and $got here")
					if $bad <= 5;   # one failure per residue, up to five, then the count
			}
			is($r->{ss_simple}, $simple{$got}, "$file: residue $ri three-state letter")
				if $r->{ss_simple} ne ($simple{$got} || 'C');
		}
		is($bad, 0, sprintf('%s: every one of %d residues has mdtraj\'s DSSP letter', $file, $n))
			if $n;

		# and the roll-up is the same assignment read the other way round: chain,
		# then letter, then where in that chain's residue_order the residues with
		# it are.  Every residue that has a letter is in it exactly once.
		my $dssp = structure_dssp($info);
		my %seen;
		for my $cid (sort keys %$dssp) {
			for my $lt (sort keys %{ $dssp->{$cid} }) {
				my $order = $info->{chains}{$cid}{residue_order};
				for my $ix (@{ $dssp->{$cid}{$lt} }) {
					my $r = $info->{chains}{$cid}{residues}{ $order->[$ix] };
					$seen{"$cid/$ix"}++;
					is($r->{ss}, $lt, "$file: $cid index $ix is filed under '$lt'")
						if !defined $r->{ss} || $r->{ss} ne $lt;
				}
			}
		}
		my $lettered = 0;
		for my $cid (@{ $info->{chain_order} }) {
			my $order = $info->{chains}{$cid}{residue_order};
			for my $ix (0 .. $#$order) {
				next unless defined $info->{chains}{$cid}{residues}{ $order->[$ix] }{ss};
				$lettered++;
				fail("$file: $cid index $ix has a letter and is not in the roll-up")
					unless $seen{"$cid/$ix"};
			}
		}
		is(scalar(grep { $seen{$_} != 1 } keys %seen), 0,
			"$file: no residue is in the roll-up twice");
		is(scalar keys %seen, $lettered,
			"$file: the roll-up holds every residue that has a letter, and nothing else");
	}

	# Disulfides.  The frozen answer is mdtraj's rule with its units made
	# consistent, not a call into mdtraj: its own create_disulfide_bonds()
	# compares angstrom positions with a 0.3 nm cutoff and so finds nothing on
	# any file.  The head of this file and the block in Parser.xs say so at
	# length; #sg_bonds_recorded in features.txt is what mdtraj's topology
	# actually held, and it is zero for every structure here.
	my %index = map { $res->[$_]{chain} . '/' . $res->[$_]{key} => $_ } 0 .. $#$res;
	my %got_ss;
	for my $bond (@{ $feat->{disulfides} }) {
		my @e = sort { $a <=> $b } $index{"$bond->{chain1}/$bond->{residue1}"},
		                           $index{"$bond->{chain2}/$bond->{residue2}"};
		$got_ss{"$e[0] $e[1]"} = $bond->{distance};
	}
	is_deeply([ sort keys %got_ss ], [ sort keys %want_ss ],
		"$file: the same disulfide bonds as mdtraj's rule");
	# The distances themselves separately, because the frozen ones come off
	# mdtraj's float32 nanometre coordinates.  The error is in the coordinates
	# and not in the separation: a coordinate near 50 A is 5 nm, where a float32
	# is spaced 6e-7 nm apart, so it carries about 6e-6 A of representation error
	# and a distance built from two of them up to twice that.  The largest
	# disagreement over t/data is 1.13e-6 A, on ss.pdb's second bond.
	for my $k (sort keys %want_ss) {
		next unless exists $got_ss{$k};
		cmp_ok(abs($got_ss{$k} - $want_ss{$k}), '<', 1e-5,
			"$file: disulfide $k is the same length");
	}
}

for my $file (sort keys %$frozen) {
	next unless defined $frozen->{$file};
	compare($file, $frozen->{$file});
}

# a file mdtraj refuses is still a file this module has to survive
for my $file (sort grep { !defined $frozen->{$_} } keys %$frozen) {
	my $info = structure_info(File::Spec->catfile($dir, $file));
	lives_ok { structure_features($info) }
		"$file: mdtraj refuses it; this does not die on it";
}

# ---- what the file says about its own disulfides -------------------------
#
# The other half of the comparison, and the half that comes from the file rather
# than from another reader: ss.pdb is five cysteines of chain A of 1AHW, and the
# entry declares all four of its bonds in SSBOND records.  Two of those four
# residues are in this fixture twice over, as two bonds; the fixture's own
# SSBOND records are not carried across by t/data/generate.pl, so what is
# checked here is the geometry and the residue-level bookkeeping.
{
	my $info = structure_info(File::Spec->catfile($dir, 'ss.pdb'));
	my $ss = $info->{features}{disulfides};
	is(scalar @$ss, 2, 'ss.pdb: two disulfides');
	my $c = $info->{chains}{A};
	is_deeply([ map { $_->{disulfide} ? $_->{disulfide}[0]{residue} : undef }
	            map { $c->{residues}{$_} } @{ $c->{residue_order} } ],
	          [ '88', '23', '194', '134', undef ],
		'each bonded cysteine names its partner, and the free one names nobody');
	# 1AHW's SSBOND records give 2.05 and 2.03 A for these two, rounded to the
	# two decimals the format allows; the coordinates give 2.011 and 2.041
	for my $bond (@$ss) {
		cmp_ok($bond->{distance}, '>', 1.9, 'a disulfide is about 2 A long');
		cmp_ok($bond->{distance}, '<', 2.2, '... and not much more');
	}
	is(scalar @{ structure_disulfides($info) }, 2,
		'structure_disulfides returns the same list');
	# the cutoff is the whole of the rule, so shrinking it below a real bond
	# length must find nothing
	is_deeply(structure_disulfides($info, disulfide_distance => 1.9), [],
		'and no bond is shorter than 1.9 A');
	# and widening it sweeps in pairs that are nowhere near bonded.  The next
	# two SG-SG separations after the two real bonds are 21.17 and 22.50 A,
	# both to the free CYS 214, so 23 A is the cutoff that first admits them.
	is(scalar @{ structure_disulfides($info, disulfide_distance => 21) }, 2,
		'nothing between 2.04 and 21 A');
	is(scalar @{ structure_disulfides($info, disulfide_distance => 23) }, 4,
		'and a 23 A cutoff sweeps in the free cysteine twice over');
}

# ---- the sequence numbers, against Biopython -----------------------------
#
# gravy() sums the Kyte-Doolittle index over the sequence and divides by its
# length; aromaticity() is the relative frequency of F, W and Y.  The sequences
# are the protein chains of t/data's structures as this module reads them, plus
# a few chosen to cover the twenty letters and the two extremes, and the numbers
# beside them are what Biopython 1.87 returns for them:
#
#   python3 -c 'from Bio.SeqUtils.ProtParam import ProteinAnalysis as P;
#               p = P("...."); print(p.gravy(), p.aromaticity())'
#
# Both are exact rational sums, so they are compared to 1e-12 rather than to a
# measured tolerance -- there is no floating point question here beyond the
# order the terms are added in.
my @protparam = (
	# sequence,                    gravy,                aromaticity
	[ 'MAGCMHHSC',                  0.33333333333333326, 0.0    ],
	[ 'MKWVTFISLLFLFSSAYS',         1.2333333333333334,  0.2777777777777778 ],
	[ 'ACDEFGHIKLMNPQRSTVWY',      -0.49000000000000005, 0.15000000000000002 ],
	[ 'FWY',                        0.19999999999999993, 1.0    ],
	[ 'GGGGG',                     -0.4,                 0.0    ],
	[ 'MRNQELARIFEEIGLMSEFLGDNPFRVRAYHQAARTLYDLDTPIEEIAEKGKEALMELPGVGPDLAEKILEFLRTG',
	                               -0.3197368421052632,  0.07894736842105264 ],
);
my %KD = (
	A =>  1.8, R => -4.5, N => -3.5, D => -3.5, C =>  2.5,
	Q => -3.5, E => -3.5, G => -0.4, H => -3.2, I =>  4.5,
	L =>  3.8, K => -3.9, M =>  1.9, F =>  2.8, P => -1.6,
	S => -0.8, T => -0.7, W => -0.9, Y => -1.3, V =>  4.2,
);
for my $c (@protparam) {
	my ($seq, $gravy, $arom) = @$c;
	my ($sum, $n, $a) = (0, 0, 0);
	for my $aa (split //, $seq) {
		$a++ if $aa =~ /[FWY]/;
		next unless exists $KD{$aa};
		$sum += $KD{$aa};
		$n++;
	}
	cmp_ok(abs($sum / $n - $gravy), '<', 1e-12, "Biopython gravy of $seq");
	cmp_ok(abs($a / length($seq) - $arom), '<', 1e-12, "Biopython aromaticity of $seq");
}

# and the same two numbers as structure_features() computes them, over the
# sequence structure_info() read out of the file
{
	my $info = structure_info(File::Spec->catfile($dir, 'mini.pdb'));
	my $f = structure_features($info);
	is($info->{chains}{A}{sequence}, 'MAGCMHHSC', 'mini.pdb chain A reads as expected');
	cmp_ok(abs($f->{hydropathy} - 0.33333333333333326), '<', 1e-12,
		'structure_features hydropathy is gravy over that sequence');
	cmp_ok(abs($f->{aromatic_fraction} - 0), '<', 1e-12,
		'structure_features aromatic_fraction is aromaticity over that sequence');
	is($f->{n_aromatic}, 0, 'no aromatic residues in mini.pdb');
	is($f->{sequence_length}, 9, 'nine residues of protein sequence');
	cmp_ok(abs($info->{chains}{A}{hydropathy} - $f->{hydropathy}), '<', 1e-12,
		'the one protein chain carries the same hydropathy as the structure');

	my $stack = structure_info(File::Spec->catfile($dir, 'stack.pdb'));
	my $sf = structure_features($stack);
	# TRP TRP TRP PHE PHE and two HIS: five of seven are F, W or Y
	is($sf->{n_aromatic}, 5, 'stack.pdb has five F/W/Y residues');
	cmp_ok(abs($sf->{aromatic_fraction} - 5 / 7), '<', 1e-12,
		'aromatic_fraction counts histidine in the denominator and not the numerator');
}

# ---- the nucleic acid sequence numbers, against Biopython ----------------
#
# gc_fraction() divides the C and G by the C, G, A, T and U, so an ambiguous or
# unknown letter is in neither half.  That is its default, ambiguous =>
# 'remove', and it is the rule structure_features() applies:
#
#   python3 -c 'from Bio.SeqUtils import gc_fraction; print(gc_fraction("...."))'
#
# An exact rational sum, so it is compared to 1e-12 rather than to a measured
# tolerance.  The last three cases are the ones that say what 'remove' means: an
# N, an I and an X are in neither the numerator nor the denominator, so ACGTN
# and ACGT are both 0.5 and not 0.4.
my @gcfrac = (
	# sequence,     Bio.SeqUtils.gc_fraction()
	[ 'ACGUAA',     0.3333333333333333 ],   # rna.pdb chain A
	[ 'CGAA',       0.5                ],   # duplex.pdb chain A
	[ 'TTCG',       0.5                ],   # duplex.pdb chain B
	[ 'CAGTAT',     0.3333333333333333 ],   # bases.pdb chain P
	[ 'GGCC',       1.0                ],
	[ 'AAAA',       0.0                ],
	[ 'GCGCGCGCGC', 1.0                ],
	[ 'ACGTN',      0.5                ],
	[ 'ACGTNIX',    0.5                ],
);
for my $c (@gcfrac) {
	my ($seq, $want) = @$c;
	my ($gc, $n) = (0, 0);
	for my $b (split //, $seq) {
		next unless $b =~ /[ACGTU]/;
		$gc++ if $b =~ /[CG]/;
		$n++;
	}
	cmp_ok(abs($gc / $n - $want), '<', 1e-12, "Biopython gc_fraction of $seq");
}

# and the same number as structure_features() computes it, over the sequence
# structure_info() read out of the file
{
	my $rna = structure_info(File::Spec->catfile($dir, 'rna.pdb'));
	my $rf  = structure_features($rna);
	is($rna->{chains}{A}{type}, 'rna', 'rna.pdb chain A reads as RNA');
	is($rna->{chains}{A}{sequence}, 'ACGUAA', '... with the sequence 1MSY has there');
	cmp_ok(abs($rf->{gc_fraction} - 0.3333333333333333), '<', 1e-12,
		'structure_features gc_fraction is gc_fraction over that sequence');
	cmp_ok(abs($rna->{chains}{A}{gc_fraction} - $rf->{gc_fraction}), '<', 1e-12,
		'the one nucleic chain carries the same fraction as the structure');
	# A, C, G, U, A, A: four of the six are purines
	cmp_ok(abs($rf->{purine_fraction} - 4 / 6), '<', 1e-12, 'and four of six are purines');
	is($rf->{n_gc}, 2, 'two of them are G or C');
	is($rf->{nucleotide_length}, 6, 'six nucleotides of sequence');
	is_deeply($rna->{chains}{A}{base_counts}, { A => 3, C => 1, G => 1, U => 1 },
		'base_counts tallies every letter of it');
	# no protein in the file, so no protein numbers: a hydropathy of zero would
	# read as a chain of alanine and glycine rather than as no chain at all
	ok(!exists $rf->{hydropathy}, 'an RNA structure gets no hydropathy');
	is($rf->{sequence_length}, 0, '... and no protein sequence length');

	my $dup = structure_info(File::Spec->catfile($dir, 'duplex.pdb'));
	my $df  = structure_features($dup);
	is($dup->{chains}{A}{type}, 'dna', 'duplex.pdb chain A reads as DNA');
	is($dup->{chains}{B}{type}, 'dna', '... and so does chain B');
	is($dup->{chains}{A}{sequence}, 'CGAA', 'chain A is the CGAA of 1BNA 3 to 6');
	is($dup->{chains}{B}{sequence}, 'TTCG', 'chain B is its complement read 19 to 22');
	# the strands are complementary, so each is the other's G+C by symmetry
	cmp_ok(abs($dup->{chains}{A}{gc_fraction} - 0.5), '<', 1e-12, 'chain A is half G+C');
	cmp_ok(abs($dup->{chains}{B}{gc_fraction} - 0.5), '<', 1e-12, 'and so is chain B');
	cmp_ok(abs($df->{gc_fraction} - 0.5), '<', 1e-12, 'and the duplex with them');
	# ... and each other's purines: three of chain A's four, one of chain B's
	cmp_ok(abs($dup->{chains}{A}{purine_fraction} - 3 / 4), '<', 1e-12,
		'chain A is three-quarters purine');
	cmp_ok(abs($dup->{chains}{B}{purine_fraction} - 1 / 4), '<', 1e-12,
		'chain B a quarter, which is what antiparallel means');
	cmp_ok(abs($df->{purine_fraction} - 0.5), '<', 1e-12, 'and the pair exactly half');
	is($df->{nucleotide_length}, 8, 'eight nucleotides over the two chains');
	is_deeply($df->{base_counts}, { A => 2, C => 2, G => 2, T => 2 },
		'base_counts adds the chains up');

	# a structure with no nucleic acid in it gets none of these keys at all
	my $prot = structure_features(structure_info(File::Spec->catfile($dir, 'fold.pdb')));
	ok(!exists $prot->{gc_fraction},       'a protein structure gets no gc_fraction');
	ok(!exists $prot->{nucleotide_length}, '... and no nucleotide length');
	ok(!exists $prot->{base_counts},       '... and no base counts');
}

# ---- what the two forms of helix actually say ----------------------------
#
# The point of the torsions, and the one thing no per-angle comparison above
# says out loud: an A-form helix and a B-form helix are told apart by the sugar.
# rna.pdb is six nucleotides of an rRNA hairpin and duplex.pdb is four base
# pairs of the Drew-Dickerson dodecamer, and every ribose in the first is
# C3'-endo (phase within 90 degrees of 0, the north half of the cycle) while
# every deoxyribose in the second is in the south half.  Both fixtures are real
# entries and neither was chosen for this; that is simply what they are.
{
	my $rna = structure_info(File::Spec->catfile($dir, 'rna.pdb'));
	my $dup = structure_info(File::Spec->catfile($dir, 'duplex.pdb'));
	my (@north, @south);
	for my $t ([ $rna, \@north ], [ $dup, \@south ]) {
		my ($info, $out) = @$t;
		for my $cid (@{ $info->{chain_order} }) {
			my $c = $info->{chains}{$cid};
			for my $rk (@{ $c->{residue_order} }) {
				my $r = $c->{residues}{$rk};
				next unless defined $r->{pucker_phase};
				push @$out, [ "$cid/$rk", $r->{pucker_phase}, $r->{pucker},
				              $r->{glycosidic} ];
			}
		}
	}
	is(scalar @north, 6, 'every nucleotide of rna.pdb has a pucker');
	is(scalar @south, 8, 'and every nucleotide of duplex.pdb');
	is_deeply([ grep { $_->[1] > 90 && $_->[1] < 270 } @north ], [],
		'every ribose of the RNA is in the north half of the cycle');
	is_deeply([ grep { $_->[2] ne "C3'-endo" } @north ], [],
		'... and C3-endo to the name, which is what A-form means');
	is_deeply([ grep { $_->[1] <= 90 || $_->[1] >= 270 } @south ], [],
		'every deoxyribose of the B-DNA is in the south half');
	is_deeply([ grep { $_->[3] ne 'anti' } @north ], [],
		'and every base of the RNA is anti about its glycosidic bond');
}

# ---- the chain's view of the same torsions -------------------------------
#
# Every angle written onto a residue above is also gathered onto its chain, one
# array per torsion, parallel to the chain's residue_order.  Nothing new is
# measured, so there is no other reader to ask: what is checked is that the two
# views hold the same numbers in the same order, which is the whole claim.
{
	# every key the chain arrays can carry, so that a chain holding one this
	# does not know about is a failure rather than something nobody looked at
	my @all = qw(phi psi omega chi alpha beta gamma delta epsilon zeta
	             nu pucker pucker_phase pucker_amplitude glycosidic);

	# the two kinds of chain, and which of those keys each should end up with
	my %want = (
		'fold.pdb' => [ qw(phi psi omega chi) ],
		'rna.pdb'  => [ qw(alpha beta gamma delta epsilon zeta chi nu
		                   pucker pucker_phase pucker_amplitude glycosidic) ],
	);

	for my $file (sort keys %want) {
		my $info = structure_info(File::Spec->catfile($dir, $file));
		for my $cid (@{ $info->{chain_order} }) {
			my $c = $info->{chains}{$cid};
			my $t = $c->{torsions};
			ok($t, "$file: chain $cid has a torsions hash") or next;
			is_deeply([ sort keys %$t ], [ sort @{ $want{$file} } ],
				"$file: chain $cid carries exactly the torsions its residues have");
			for my $key (@all) {
				# a key no residue has is absent, not an array of undefs
				my @res = map { $c->{residues}{$_}{$key} }
				          @{ $c->{residue_order} };
				unless (grep { defined } @res) {
					ok(!exists $t->{$key},
						"$file: chain $cid has no $key, because no residue of it does");
					next;
				}
				is(scalar @{ $t->{$key} }, scalar @{ $c->{residue_order} },
					"$file: chain $cid $key is one element per residue");
				is_deeply($t->{$key}, \@res,
					"$file: chain $cid $key is what its residues say, in residue_order");
			}
		}
	}

	# a residue with no phi -- the first of the chain -- holds an undef in the
	# array rather than shortening it, which is what keeps the index meaningful
	my $fold = structure_info(File::Spec->catfile($dir, 'fold.pdb'));
	my $ch = $fold->{chains}{A};
	ok(!defined $ch->{torsions}{phi}[0],
		'the first residue of a chain has an undef where its phi would be');
	ok(defined $ch->{torsions}{phi}[1], '... and the second has its phi');
	ok(!defined $ch->{torsions}{psi}[ $#{ $ch->{residue_order} } ],
		'and the last residue has no psi, for the same reason');

	# chi is one list per residue, and the chain names the residue's own list
	# rather than a copy of it
	is($ch->{torsions}{chi}[0], $ch->{residues}{ $ch->{residue_order}[0] }{chi},
		'a chi in the chain array is the same list the residue has');

	# asking twice replaces the answer rather than adding to it
	my $n = scalar @{ $ch->{torsions}{phi} };
	structure_features($fold);
	is(scalar @{ $fold->{chains}{A}{torsions}{phi} }, $n,
		'asking a second time replaces the arrays rather than extending them');

	# store => 0 computes no torsions at all, so there is nothing to gather
	my $bare = structure_info(File::Spec->catfile($dir, 'fold.pdb'), features => 0);
	ok(!exists $bare->{chains}{A}{torsions},
		'features => 0 leaves no torsions hash on the chain');
	structure_features($bare, store => 0);
	ok(!exists $bare->{chains}{A}{torsions},
		'... and store => 0 does not put one there either');
}

# ---- the base pairs, against the archive's own annotation -----------------
#
# No reader on this machine finds base pairs, so the answer comes from the
# wwPDB, which deposits 3DNA's with the entry.  The rows below are the
# _ndb_struct_na_base_pair loop of the two entries the nucleic fixtures were
# lifted from, restricted to the residues that are actually in the fixture:
# i_auth_asym_id, i_auth_seq_id, the same for j, and hbond_type_28, which is
# Saenger's numbering of the twenty-eight pair types.  Written down here the way
# t/foreign.t writes its cases down, with the entry each came from, because
# there is nothing to run.
#
#   1BNA.cif, https://files.rcsb.org/download/1BNA.cif -- twelve pairs, of
#   which four are wholly inside duplex.pdb (chain A 3 to 6, chain B 19 to 22).
#   1MSY.cif, https://files.rcsb.org/download/1MSY.cif -- eleven, of which six
#   are inside wobble.pdb (chain A 2647 to 2652 and 2668 to 2673) and one
#   inside rna.pdb (chain A 2657 to 2662).
#
# A '?' is a pair the annotation records and cannot put a Saenger number on:
# it is a pair, but not one of the three this module looks for, so it must not
# be reported.  Those are the negative half of this test and are the reason
# these two fixtures were chosen.
{
	my %annotated = (
		'duplex.pdb' => [
			[ 'A', 3, 'B', 22, 19 ],
			[ 'A', 4, 'B', 21, 19 ],
			[ 'A', 5, 'B', 20, 20 ],
			[ 'A', 6, 'B', 19, 20 ],
		],
		'wobble.pdb' => [
			[ 'A', 2647, 'A', 2673, '?' ],   # a pair, and none of the twenty-eight
			[ 'A', 2648, 'A', 2672, 28 ],    # the wobble
			[ 'A', 2649, 'A', 2671, 19 ],
			[ 'A', 2650, 'A', 2670, 20 ],
			[ 'A', 2651, 'A', 2669, 19 ],
			[ 'A', 2652, 'A', 2668, 19 ],
		],
		'rna.pdb' => [
			[ 'A', 2659, 'A', 2662, '?' ],   # the only pair inside the hairpin
		],
	);
	for my $file (sort keys %annotated) {
		my $info = structure_info(File::Spec->catfile($dir, $file));
		my %got;
		for my $bp (@{ structure_base_pairs($info) }) {
			my @e = sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] }
			        [ $bp->{chain1}, $bp->{residue1} ], [ $bp->{chain2}, $bp->{residue2} ];
			$got{join '/', map { @$_ } @e} = $bp->{saenger};
		}
		my %want;
		for my $row (@{ $annotated{$file} }) {
			next unless $row->[4] =~ /\A[0-9]+\z/;
			my @e = sort { $a->[0] cmp $b->[0] || $a->[1] <=> $b->[1] }
			        [ @$row[0, 1] ], [ @$row[2, 3] ];
			$want{join '/', map { @$_ } @e} = $row->[4];
		}
		is_deeply(\%got, \%want,
			"$file: the pairs found are the ones the entry's own annotation calls "
		  . 'Watson-Crick or wobble, with the same Saenger type');
	}
	# and the two formats say the same thing, which t/cif.t asserts over the
	# whole structure and this asserts over the answer itself
	for my $stem (qw(duplex wobble rna)) {
		my $pdb = structure_base_pairs(structure_info(
			File::Spec->catfile($dir, "$stem.pdb")));
		my $cif = structure_base_pairs(structure_info(
			File::Spec->catfile($dir, "$stem.cif")));
		is_deeply($cif, $pdb, "$stem.cif finds the same base pairs as $stem.pdb");
	}
}

# ---- the options ----------------------------------------------------------
#
# Both thresholds are the whole of the rule, so both are options.  Widening the
# hydrogen bond to 4.0 A picks up the pair the 1MSY annotation records and
# cannot classify -- U2647-G2673, whose two bonds are 3.97 and 5.20 A, so it
# takes 5.3 A to reach the second one -- and tightening the stagger to 0 leaves
# nothing at all.
{
	my $info = structure_info(File::Spec->catfile($dir, 'wobble.pdb'));
	is(scalar @{ structure_base_pairs($info) }, 5, 'wobble.pdb has five pairs');
	is(scalar @{ structure_base_pairs($info, base_pair_hbond => 4.0) }, 5,
		'... still five at 4.0 A, because the pair it would add needs 5.3');
	is(scalar @{ structure_base_pairs($info, base_pair_hbond => 5.3) }, 6,
		'... and six at 5.3, which is U2647-G2673 arriving');
	is(scalar @{ structure_base_pairs($info, base_pair_stagger => 0) }, 0,
		'... and none at all with no stagger allowed');
	# structure_info() wrote the answer onto the residues on the way past, twice
	# per pair.  Asking again with a different cutoff replaces those notes
	# rather than adding to them, which is what the hv_delete() at the head of
	# base_pairs() is for; asking with store => 0 leaves the residues as they
	# were and answers with the list alone.  Both are structure_disulfides()'s
	# behaviour, which is where the pattern comes from.
	my $again = structure_info(File::Spec->catfile($dir, 'wobble.pdb'));
	my $notes = sub {
		my $n = 0;
		for my $cid (@{ $again->{chain_order} }) {
			my $c = $again->{chains}{$cid};
			$n += scalar @{ $c->{residues}{$_}{base_pair} || [] }
				for @{ $c->{residue_order} };
		}
		return $n;
	};
	is($notes->(), 10, 'structure_info noted all five pairs on both of their residues');
	structure_base_pairs($again, base_pair_hbond => 5.3);
	is($notes->(), 12, 'a wider cutoff replaces the notes rather than adding to them');
	structure_base_pairs($again, base_pair_stagger => 0);
	is($notes->(), 0, '... and one that finds nothing clears them');
	structure_base_pairs($again);
	is($notes->(), 0, 'the no-option call is the lookup and writes nothing');
	structure_features($again, base_pair_hbond => 3.5);
	is($notes->(), 10, '... and asking again puts the five pairs back');
	structure_base_pairs($again, base_pair_stagger => 0, store => 0);
	is($notes->(), 10, 'store => 0 answers without touching the residues');
}

# ---- the live half -------------------------------------------------------
#
# Where mdtraj is importable, run the generator's own dump again and check the
# frozen file still says what mdtraj says.  A fixture regenerated without
# re-running t/data/features.pl would otherwise leave every comparison above
# passing against an answer to an older file.
SKIP: {
	my $py = $ENV{STRUCTURE_INFO_PYTHON};
	skip 'set STRUCTURE_INFO_PYTHON to a python with mdtraj to check the frozen answer', 1
		unless defined $py && length $py;
	my $devnull = File::Spec->devnull;
	skip "$py cannot import mdtraj and numpy", 1
		unless system("$py -c 'import mdtraj, numpy' > $devnull 2> $devnull") == 0;
	my $dump = File::Spec->catfile($dir, 'features.py');
	my @stale;
	for my $file (sort keys %$frozen) {
		next unless defined $frozen->{$file};
		my $path = File::Spec->catfile($dir, $file);
		my @live = grep { length && !/\A#/ }
		           split /\n/, qx($py \Q$dump\E \Q$path\E 2> $devnull);
		push @stale, $file unless "@live" eq "@{ $frozen->{$file} }";
	}
	is_deeply(\@stale, [], 'the frozen answers are still what mdtraj says')
		or diag('re-run t/data/features.pl from t/data/');
}

done_testing();
