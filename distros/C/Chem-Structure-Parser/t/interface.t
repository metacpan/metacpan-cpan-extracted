#!/usr/bin/env perl
# The interface between two partners, against the readers it was taken from.
#
# structure_interface() is three other people's definitions run over one
# structure, and each is checked against its owner's answer on the same file,
# t/data/iface.pdb -- the whole of 1CKA, the c-Crk SH3 domain (chain A) holding
# the C3G peptide PPPALPPKK (chain B), lifted by t/data/generate.pl from
# PDBbind v2020's 1cka.ent.pdb:
#
#   prodigy-prot 2.4.0 (Vangone and Bonvin 2015, eLife 4:e07454) -- the residue
#     contacts, their classes, the non-interacting surface and the IC_NIS
#     estimate.  Frozen from
#
#         python -c 'from prodigy_prot.modules.parsers import parse_structure
#         from prodigy_prot.modules.prodigy import Prodigy
#         m, _, _ = parse_structure("t/data/iface.pdb")
#         p = Prodigy(m[0], selection=["A", "B"]); p.predict()
#         print(p.as_dict(), p.ic_network)'
#
#     in a python 3.14.2 virtualenv with prodigy-prot 2.4.0 and freesasa
#     installed from PyPI.  It answers the same for t/data/iface.cif.
#   ~/ui/pepPriML/py/features.pdb.20260806.py -- the salt bridges, the polar
#     (N/O/S) pairs and their backbone split, the bridging waters, cation-pi,
#     the heavy-atom pair counts at three cutoffs, and the two distances.
#     Frozen from
#
#         features.pdb.20260806.py iface.pdb --pep-chain B --no-openmm
#
#     with mdtraj 1.11.1.  Its distances are float32 nanometres; see the
#     tolerance where they are compared.  The sixteen pocket_* features of its
#     pocket_block() come from the same run, as the "features" of
#     iface.pdb.features.json, and the pocket's residues from its
#     ctx.pocket_res after pocket_block(ctx).
#   Biopython 1.87 -- Bio.SeqUtils.IsoelectricPoint's charge_at_pH(7.0) and
#     pi(), for each chain's net charge and isoelectric point.  Frozen from
#     IsoelectricPoint(seq) over the sequences written beside each answer.
#
# Two differences from that script are this module's on purpose, and neither
# is exercised by 1cka: its cation-pi counts histidine both as a cation and as
# a ring, where Gallivan and Dougherty (1999) count it as neither; and it leaves
# an ACE or NH2 cap out of the peptide, where a chain named as a partner here
# takes in whatever is peptide-bonded into it.  Over twenty peptide complexes
# of PDBbind the two agree on every count once those are allowed for.  The
# pocket was run over a spread of forty PDBbind peptide complexes, 2026-09-27,
# with the script given the chain this module chose as the peptide and
# --receptor-mode all.  35 agree on every count and fraction; the other five
# -- 1bbz, 1nlo, 3fe7, 3ov1 and 3zha -- have an ACE or NH2 cap, or a
# non-standard residue peptide-bonded into a chain, that is in a partner here
# and not there.  The surfaces differ in fourteen by at most 0.23 A^2, one or
# two sphere points, which is mdtraj's float32 kernel as t/data/features.py
# discusses it.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Test::More;
use Test::Exception;
use Chem::Structure::Parser;

my $data = dirname(abs_path(__FILE__)) . '/data';

# PRODIGY's contact list for 1cka, calculate_ic() with d_cutoff 5.5: chain A
# residue, chain B residue.  32 pairs.
my @PRODIGY_IC = qw(
	141:1 141:2 141:3 142:2 143:5 146:5 147:8 149:8 150:8 166:7 166:8 166:9
	167:9 168:6 168:7 169:5 169:6 169:7 169:8 169:9 181:8 183:5 183:6 184:6
	185:3 185:4 185:6 186:2 186:3 186:4 186:5 186:6
);
# analyse_contacts()'s bins, under the names this module gives them
my %PRODIGY_BIN = (
	charged_charged => 6, charged_polar => 0, charged_apolar => 5,
	polar_polar     => 0, apolar_polar  => 3, apolar_apolar  => 18,
);
my %PRODIGY = (nis_a => 39.285714285714285, nis_c => 44.642857142857146,
               dg => -4.187177142857141);

# features.pdb.20260806.py's answers for the same file
my %SCRIPT = (
	salt_bridges => 4, polar => 8, bb_bb => 0, bb_sc => 4, sc_sc => 4,
	bridging_waters => 7, cation_pi => 1,
	contacts_50 => 318, contacts_45 => 171, contacts_40 => 89,
	com_distance => 12.108205810281412,   # com_dist_nm, times ten
	min_distance => 2.737168073654175,    # min_heavy_dist_nm, times ten
);

# Biopython 1.87's IsoelectricPoint over each protein chain in t/data
my @BJELLQVIST = (
	[ 'iface.pdb', 'A', 'AEYVRALFDFNGNDEEDLPFKKGDILRIRDKPEEQWWNAEDSEGKRGMIPVPYVEKY',
	  -5.182949158313175, 4.560101509094238 ],
	[ 'iface.pdb', 'B', 'PPPALPPKK', 1.9565308655803535, 10.01866092681885 ],
	[ 'fold.pdb', 'A', 'HWGYGKHNGPEHWHKDFPIAKGERQSPVDIDTHTAKYDPSLKPLSVSYDQATSLRILNN',
	  0.19918527631586969, 7.153891944885253 ],
	[ 'sheet.pdb', 'A', 'KMTQIMFETFNVPAMYVAIQAVLSLYASGRTTGIVLDSGDGVTHNVPIYEGYALPHAIMR',
	  -1.0627025682704212, 6.018874168395995 ],
	[ 'ss.pdb', 'A', 'CCCCC', -0.2894033363057468, 5.492488288879394 ],
	[ 'stack.pdb', 'A', 'WHFWHWF', -0.06555000930152344, 6.917725944519043 ],
	[ 'mini.pdb', 'A', 'MAGCMHHSC', -0.345098916147501, 6.680138969421387 ],
	[ 'ensemble.pdb', 'B', 'PLPPY', -0.04247013342064576, 5.950042152404785 ],
);

my %info = map { ($_ => structure_info("$data/iface.$_")) } qw(pdb cif);

#--------
# both formats, and the partners it finds by itself
#--------
for my $fmt (qw(pdb cif)) {
	my $x = $info{$fmt}{features}{interface};
	ok($x, "$fmt: structure_info() computes the interface by default");
	is_deeply($x->{partners}, [ ['A'], ['B'] ],
		"$fmt: the domain against the peptide, the shorter chain on its own");
	is_deeply($x->{n_residues}, [ 57, 9 ], "$fmt: every residue of each chain, no water");
	is(structure_interface($info{$fmt}), $x, "$fmt: structure_interface() is a lookup");
}
is_deeply($info{cif}{features}{interface}, $info{pdb}{features}{interface},
	'the two formats give the same interface, every field of it');

my $x = $info{pdb}{features}{interface};

#--------
# PRODIGY
#--------
is_deeply([ sort map { "$_->{residue1}:$_->{residue2}" } @{ $x->{contacts} } ],
          [ sort @PRODIGY_IC ], "the residue contacts are PRODIGY's, pair for pair");
ok(!(grep { $_->{chain1} ne 'A' || $_->{chain2} ne 'B' } @{ $x->{contacts} }),
	'residue1 is always the first partner');
is_deeply($x->{ic}, \%PRODIGY_BIN, 'and so are the six classes they fall into');
ok(!(grep { $_->{distance} >= 5.5 } @{ $x->{contacts} }), 'every contact is under 5.5 A');

# The non-interacting surface is PRODIGY's definition over this module's
# surface, and the two surfaces are Shrake-Rupley with different radii: mdtraj's
# here, NACCESS's in freesasa.  On 1cka that moves one residue across the 5%
# line -- GLY A180, 3.1% exposed here and 6.8% there -- so this counts 55 exposed
# residues where PRODIGY counts 56, one of them apolar.  One residue is what the
# fractions are allowed: 100/55 percentage points.  The estimate is allowed what
# one residue can move it by, the two NIS coefficients times that share, 0.59
# kcal/mol; it moved by 0.094.  Over 148 PDBbind entries PRODIGY can read, the
# contacts agree exactly in every one and the estimate is never further off
# than 0.22.
my $one = 100 / 55;
cmp_ok(abs(100 * $x->{nis}{apolar} - $PRODIGY{nis_a}), '<=', $one + 1e-9,
	'the apolar share of the surface is PRODIGY\'s, to one residue');
cmp_ok(abs(100 * $x->{nis}{charged} - $PRODIGY{nis_c}), '<=', $one + 1e-9,
	'and so is the charged share');
cmp_ok(abs($x->{nis}{apolar} + $x->{nis}{charged} + $x->{nis}{polar} - 1), '<', 1e-12,
	'the three shares are all of it');
cmp_ok(abs($x->{prodigy}{dg} - $PRODIGY{dg}), '<=', (0.18681 + 0.13810) * $one,
	'the IC_NIS estimate is PRODIGY\'s, to what one residue can move it');
{
	# dg_to_kd() in prodigy_prot/modules/utils.py, at the default 25 C
	my $kd = exp($x->{prodigy}{dg} / (0.0019858775 * 298.15));
	cmp_ok(abs($x->{prodigy}{kd} / $kd - 1), '<', 1e-12, 'the Kd is exp(dg / RT) at 25 C');
	is($x->{prodigy}{temperature}, 25, 'and says which temperature');
	my $y = structure_interface($info{pdb}, temperature => 37);
	cmp_ok(abs($y->{prodigy}{kd} / exp($y->{prodigy}{dg} / (0.0019858775 * 310.15)) - 1),
		'<', 1e-12, 'temperature => 37 is the Kd at 37 C');
}

#--------
# the pepPriML script's definitions
#--------
is(scalar @{ $x->{salt_bridges} },    $SCRIPT{salt_bridges},    'salt bridges');
is(scalar @{ $x->{polar_contacts} },  $SCRIPT{polar},           'N/O/S pairs under 3.5 A');
{
	my %n = (bb_bb => 0, bb_sc => 0, sc_sc => 0);
	for (@{ $x->{polar_contacts} }) {
		my $k = $_->{backbone1} + $_->{backbone2};
		$n{ $k == 2 ? 'bb_bb' : $k == 1 ? 'bb_sc' : 'sc_sc' }++;
	}
	is_deeply(\%n, { map { ($_ => $SCRIPT{$_}) } qw(bb_bb bb_sc sc_sc) },
		'and which of them are backbone');
}
is(scalar @{ $x->{bridging_waters} }, $SCRIPT{bridging_waters}, 'bridging waters');
is(scalar @{ $x->{cation_pi} },       $SCRIPT{cation_pi},       'cation-pi');
is($x->{cation_pi}[0]{resname1} . $x->{cation_pi}[0]{resname2} . $x->{cation_pi}[0]{cation},
   'TRPLYS2', 'which is the peptide\'s lysine over the domain\'s tryptophan');
for my $d ([ 5.0, 'contacts_50' ], [ 4.5, 'contacts_45' ], [ 4.0, 'contacts_40' ]) {
	is(structure_interface($info{pdb}, interface_distance => $d->[0])->{n_atom_contacts},
	   $SCRIPT{ $d->[1] }, "heavy-atom pairs under $d->[0] A");
}
# The script's distances are mdtraj's, whose coordinates are float32 in
# nanometres: 24 bits of mantissa on a coordinate near 13 nm is about 1e-6 nm
# apart, and the two here differ by 3.0e-6 A (the closest approach) and 4.8e-7 A
# (the centres).  1e-5 A is three times the larger.
cmp_ok(abs($x->{com_distance} - $SCRIPT{com_distance}), '<', 1e-5,
	'the centres of mass are the script\'s distance apart');
cmp_ok(abs($x->{min_distance} - $SCRIPT{min_distance}), '<', 1e-5,
	'and so are the closest two heavy atoms');
ok(!(grep { $_->{distance} >= 4.0 } @{ $x->{salt_bridges} }), 'every salt bridge is under 4 A');
ok(!(grep { $_->{distance} >= 3.5 } @{ $x->{polar_contacts} }), 'every polar pair is under 3.5 A');

#--------
# the pocket, against the script's pocket_block()
#--------
{
	# features.pdb.20260806.py's pocket_* for iface.pdb; the surfaces are its
	# nm^2, and a hundred of them are this module's A^2
	my %want = (
		n_atoms => 130, n_residues => 18, n_chains => 1, charge => -6,
		hydropathy => -1.0166666666666666, hydropathy_max => 4.2,
		aromatic_fraction => 0.2222222222222222, hydrophobic_fraction => 0.4444444444444444,
		polar_fraction => 0.16666666666666666, charged_fraction => 0.3333333333333333,
		buried_fraction => 0.4444444444444444, packing_density => 2.6615384615384614,
	);
	my %want_sasa = (total => 10.296524143137503, hydrophobic => 3.2722341048065573,
	                 polar => 7.024290038330946);
	my @want_res = qw(141 142 143 145 146 147 149 150 151 166 167 168 169 181 183 184 185 186);
	for my $fmt (qw(pdb cif)) {
		my $p = $info{$fmt}{features}{interface}{pocket};
		ok($p, "$fmt: the interface has a pocket by default");
		is_deeply([ map { $_->{residue} } @{ $p->{residues} } ], \@want_res,
			"$fmt: the pocket is the script's eighteen residues of the domain");
		# The counts are integers and the fractions one integer over another,
		# the same NV.  The hydropathy is a sum of eighteen table values, which
		# can be added in another order: it was 2.2e-16 from the script's on a
		# double perl, and 1e-12 is headroom for a wider NV rounding it
		# differently.
		for my $k (sort keys %want) {
			cmp_ok(abs($p->{$k} - $want{$k}), '<=', 1e-12 * (1 + abs $want{$k}),
				"$fmt: pocket $k is the script's");
		}
		# The script's surfaces are mdtraj's float32 kernel, and the three
		# here were 2.3e-8 of themselves from it on 1cka (1.7e-5 A^2 in 327):
		# float32 addition over 130 atoms.  A sphere point that flipped would be
		# 0.13 A^2, 1.3e-4 of the total, so 1e-6 tells the two apart with forty
		# times the observed difference to spare.
		for my $k (sort keys %want_sasa) {
			cmp_ok(abs($p->{sasa}{$k} / (100 * $want_sasa{$k}) - 1), '<', 1e-6,
				"$fmt: the pocket's $k surface alone is the script's");
		}
		# a mean of eighteen float32 quotients: 8.8e-9 from the script's
		cmp_ok(abs($p->{rsa} - 0.3083244125001126), '<', 1e-6,
			"$fmt: and so is its mean relative surface alone");
	}
	my $p = $x->{pocket};
	my $n = 0;
	$n += $_->{n_atoms} for @{ $p->{residues} };
	is($n, $p->{n_atoms}, 'the pocket residues account for every pocket atom');
	my $a = 0;
	$a += $_->{sasa_alone} for @{ $p->{residues} };
	cmp_ok(abs($a - $p->{sasa}{total}), '<', 1e-8, 'and for its surface');
	cmp_ok(abs($p->{sasa}{hydrophobic} + $p->{sasa}{polar} - $p->{sasa}{total}), '<', 1e-8,
		'which is its hydrophobic residues\' and the rest');
	ok(!(grep { !defined $_->{rsa_alone} } @{ $p->{residues} }),
		'every pocket residue of 1cka has a relative surface');

	# What the pocket is, from the coordinates: the first partner's atoms within
	# pocket_distance of any atom of the second, hydrogens and all -- iface.pdb
	# has them, and the script counts them -- and the heavy atoms of the first
	# within packing_distance of a heavy atom of the second, per heavy atom of
	# the second.  Brute force over the two chains, at the defaults and at
	# cutoffs either side of them.
	my $atoms = sub {
		my ($c) = @_;
		my $ch = $info{pdb}{chains}{$c};
		# the chain's amino acids: its waters are in neither partner
		return [ map {
			my $r = $_;
			map { [ $r->{key}, $_->{element}, $_->{x}, $_->{y}, $_->{z} ] }
				map { $r->{atoms}{$_} } @{ $r->{atom_order} }
		} grep { $_->{type} eq 'amino_acid' } map { $ch->{residues}{$_} } @{ $ch->{residue_order} } ];
	};
	my ($A, $B) = map { $atoms->($_) } qw(A B);
	my $close = sub {
		my ($u, $list, $cut) = @_;
		for my $v (@$list) {
			my ($dx, $dy, $dz) = map { $u->[$_] - $v->[$_] } 2 .. 4;
			return 1 if $dx * $dx + $dy * $dy + $dz * $dz < $cut * $cut;
		}
		return 0;
	};
	my @heavy_b = grep { $_->[1] ne 'H' } @$B;
	for my $cut ([ 6.0, 8.0 ], [ 4.0, 5.0 ], [ 9.0, 12.0 ]) {
		my ($pk, $pack) = @$cut;
		my @in = grep { $close->($_, $B, $pk) } @$A;
		my %res = map { ($_->[0] => 1) } @in;
		my $n_pack = grep { $_->[1] ne 'H' && $close->($_, \@heavy_b, $pack) } @$A;
		my $y = $pk == 6.0 ? $p
		      : structure_interface($info{pdb}, pocket_distance => $pk,
		                            packing_distance => $pack)->{pocket};
		is($y->{n_atoms}, scalar @in, "pocket_distance => $pk: every atom of A within $pk A of B");
		is($y->{n_residues}, scalar keys %res, "pocket_distance => $pk: and their residues");
		cmp_ok(abs($y->{packing_density} - $n_pack / @heavy_b), '<', 1e-12,
			"packing_distance => $pack: A's heavy atoms within $pack A of B's, per heavy atom of B");
	}

	# The first partner's pocket around the second: the other way round it is
	# the peptide's atoms around the domain
	my $y = structure_interface($info{pdb}, partners => [ 'B', 'A' ])->{pocket};
	is($y->{n_atoms}, scalar(grep { $close->($_, $A, 6.0) } @$B),
		'partners => [B, A] is the peptide\'s atoms around the domain');
	is($y->{n_chains}, 1, 'on one chain');
	is_deeply(structure_interface($info{pdb}, partners => [ ['A'], ['B'] ])->{pocket}, $p,
		'the interface computed alone has the same pocket, exactly');

	my $none = structure_interface($info{pdb}, pocket_distance => 0.5)->{pocket};
	is_deeply($none, { n_atoms => 0, n_residues => 0, n_chains => 0, residues => [],
	                   packing_density => $p->{packing_density} },
		'a pocket with nothing in it has its counts and nothing to average');
	ok(!exists structure_features($info{pdb}, pocket => 0)->{interface}{pocket},
		'pocket => 0 leaves it out');
	ok(!exists structure_interface($info{pdb}, pocket => 0)->{pocket},
		'and so does structure_interface()');

	my $m = structure_info("$data/mini.pdb");
	my $l = structure_interface($m, partners => [ ['A'], ['NAG_A_201'] ])->{pocket};
	ok($l->{n_atoms} > 0, 'a ligand has a pocket of the chain around it');
	my $r = structure_interface($m, partners => [ ['NAG_A_201'], ['A'] ])->{pocket};
	ok($r->{n_residues} == 1 && !exists $r->{hydropathy} && !exists $r->{rsa},
		'and a ligand as the first partner is a pocket with no amino acid to score');
}

#--------
# the surfaces
#--------
{
	# The default read starts the complex from the whole structure's surface
	# and recomputes only the atoms near something outside it; asking for the
	# interface on its own computes the complex whole.  On 1cka 608 of the 659
	# partner atoms have a water within reach and are recomputed, and 51 keep
	# the whole structure's surface, which is the case that matters: the two
	# must agree to the last bit.
	my $alone = structure_interface($info{pdb}, partners => [ ['A'], ['B'] ]);
	is_deeply($alone->{residues}, $x->{residues},
		'the interface computed alone has the same per-residue surfaces, exactly');
	is_deeply($alone->{sasa}, $x->{sasa}, 'and the same totals');
	is_deeply($alone->{buried}, $x->{buried}, 'and buries the same area');
	ok(!exists $alone->{pi_stacking}, 'computed alone it has no ring pairs to filter');
	# a chain named twice is on its side once: it used to be counted twice, and
	# 1cka came back with 114 residues on side A, a NIS of its own and a dg of
	# -4.655 where it is -4.281
	is_deeply(structure_interface($info{pdb}, partners => [ ['A', 'A'], ['B'] ]), $alone,
		'naming a chain twice is naming it once');
}
{
	my $b = $x->{buried};
	cmp_ok(abs($b->{total} - $b->{side}[0] - $b->{side}[1]), '<', 1e-8,
		'the buried area is what the two sides bury');
	cmp_ok(abs($b->{total} - $b->{apolar} - $b->{polar}), '<', 1e-8,
		'and the apolar and polar halves of it');
	cmp_ok(abs($x->{sasa}{alone}[0] + $x->{sasa}{alone}[1] - $x->{sasa}{complex} - $b->{total}),
		'<', 1e-8, 'and the surface the two have apart, less the one they have together');
	my $sum = 0;
	$sum += $_->{buried} for map { @$_ } @{ $x->{residues} };
	cmp_ok(abs($sum - $b->{total}), '<', 1e-8, 'the interface residues account for all of it');
	# the script's buried_sasa_nm2, 9.9162 nm^2, is mdtraj's float32 surface
	# with its own radii table; within 0.2% is the same number
	cmp_ok(abs($b->{total} / 991.6154861450195 - 1), '<', 2e-3,
		'and it is the script\'s buried area');
}
{
	my %res = map { ("$_->{chain}$_->{residue}" => $_) } map { @$_ } @{ $x->{residues} };
	ok(!(grep { !$res{"A$_"} } map { (split /:/)[0] } @PRODIGY_IC),
		'every contacting residue of the domain is an interface residue');
	is($res{B8}{n_contacts}, scalar(grep { /:8\z/ } @PRODIGY_IC),
		'and counts its contacts: LYS B8 has as many as PRODIGY lists for it');
	ok(!(grep { $_->{buried} < 0 } values %res), 'nothing is more exposed in the complex');
}
is_deeply($x->{bfactor}{mean}[1] > 0 && $x->{bfactor}{interface}[0] > 0 ? 1 : 0, 1,
	'both partners have a mean B-factor, and so do their interfaces');

#--------
# naming the partners
#--------
{
	my $y = structure_interface($info{pdb}, partners => [ 'B', 'A' ]);
	is_deeply($y->{partners}, [ ['B'], ['A'] ], 'a chain id on its own is a partner');
	is(scalar @{ $y->{contacts} }, 32, 'and the other way round finds the same contacts');
	ok(!(grep { $_->{chain1} ne 'B' } @{ $y->{contacts} }), 'with the first partner first');
	is_deeply($y->{ic}, $x->{ic}, 'in the same classes');

	my $m = structure_info("$data/mini.pdb");
	my $l = structure_interface($m, partners => [ ['A'], ['NAG_A_201', 'ZN_A_202'] ]);
	is_deeply($l->{partners}, [ ['A'], [ 'NAG_A_201', 'ZN_A_202' ] ],
		'ligand keys, as structure_ligands() writes them, are partners');
	# chain A's polymer is the nine residues of MAGCMHHSC; the NAG and the zinc
	# carry its letter and are not part of it
	is_deeply($l->{n_residues}, [ length $m->{chains}{A}{sequence}, 2 ],
		'the chain\'s polymer against the two of them');
	ok(!$l->{prodigy}, 'and no PRODIGY estimate for something that is not a protein');

	my $one_chain = structure_info("$data/mini.pdb", chains => ['A']);
	is_deeply($one_chain->{features}{interface}{partners}, [ ['A'], ['NAG_A_201'] ],
		'one polymer chain is split against its largest ligand, and not against an ion');
	my $ens = structure_info("$data/ensemble.pdb");
	ok(!$ens->{features}{interface},
		'a peptide whose only heterogen is its own ACE cap has no second partner');
	throws_ok { structure_interface($ens) } qr/no two partners to split/,
		'and asking for its interface says so';
}

#--------
# off, and the other feature switches
#--------
ok(!exists structure_features($info{pdb}, interface => 0)->{interface},
	'interface => 0 leaves it out');
{
	# sasa => 0 asks for no surface, and the interface's is one: what does not
	# need a surface is still there, and is the same
	my $y = structure_features($info{pdb}, sasa => 0)->{interface};
	ok($y, 'sasa => 0 still finds the interface');
	ok(!exists $y->{$_}, "sasa => 0: no $_") for qw(sasa buried nis prodigy);
	is_deeply($y->{$_}, $x->{$_}, "sasa => 0: the same $_")
		for qw(contacts ic salt_bridges polar_contacts cation_pi bridging_waters
		       n_atom_contacts com_distance min_distance bfactor);
	is_deeply([ map { [ map { "$_->{chain}$_->{residue}" } @$_ ] } @{ $y->{residues} } ],
	          [ map { [ map { "$_->{chain}$_->{residue}" } grep { $_->{n_contacts} } @$_ ] }
	                @{ $x->{residues} } ],
		'sasa => 0: the interface residues are the ones in contact');
	ok(!(grep { exists $_->{buried} } map { @$_ } @{ $y->{residues} }),
		'and carry no surface');
	my %p = %{ $x->{pocket} };
	delete @p{qw(sasa rsa buried_fraction)};
	$p{residues} = [ map { my %r = %$_; delete @r{qw(sasa_alone rsa_alone)}; \%r }
	                 @{ $p{residues} } ];
	is_deeply($y->{pocket}, \%p, 'sasa => 0: the pocket, less its surfaces');
	throws_ok { structure_interface($info{pdb}, sasa => 0) } qr/unknown option 'sasa'/,
		'structure_interface() always computes its surface, so sasa is not its option';
}
ok(!exists structure_info("$data/fold.pdb")->{features}{interface},
	'a structure of one chain and nothing else has none');

#--------
# the chain properties that came with it
#--------
for my $b (@BJELLQVIST) {
	my ($file, $cid, $seq, $q, $pi) = @$b;
	my $c = structure_info("$data/$file")->{chains}{$cid};
	is($c->{sequence}, $seq, "$file $cid: the sequence Biopython was given");
	# The same NV on a double perl.  A wider NV evaluates the powers of ten in
	# more bits, and both answers move: on 5.44.0-quadmath and 5.12.5's long
	# double the largest difference over these eight chains was 2.73 double
	# epsilons in the charge (fold A) and 1.05 in the isoelectric point (iface
	# B), measured 2026-09-27.  64 leaves some twenty-fold headroom over that.
	my $tol = 64 * 2.220446049250313e-16;
	cmp_ok(abs($c->{charge} - $q), '<=', $tol * (1 + abs $q), "$file $cid: charge at pH 7");
	cmp_ok(abs($c->{isoelectric_point} - $pi), '<=', $tol * $pi, "$file $cid: isoelectric point");
}
{
	my $f = $info{pdb}{features};
	cmp_ok(abs($f->{charge} - $info{pdb}{chains}{A}{charge} - $info{pdb}{chains}{B}{charge}),
		'<', 1e-12, 'the structure\'s charge is its chains\' added up');
}
for my $file (qw(iface.pdb sheet.pdb fold.pdb)) {
	my $i = structure_info("$data/$file");
	for my $cid (grep { $i->{chains}{$_}{ss_fraction} } @{ $i->{chain_order} }) {
		my $c = $i->{chains}{$cid};
		my %n = (H => 0, E => 0, C => 0);
		my $tot = 0;
		for (@{ $c->{residue_order} }) {
			my $s = $c->{residues}{$_}{ss_simple};
			next unless defined $s;
			$n{$s}++;
			$tot++;
		}
		is_deeply($c->{ss_fraction}, { map { ($_ => $n{$_} / $tot) } keys %n },
			"$file $cid: ss_fraction is the share of each ss_simple letter");
	}
}

done_testing();
