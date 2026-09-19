#!/usr/bin/env perl
# Memory.  XS that builds Perl data structures is exactly where reference
# counts go wrong, and a leak of a few hundred SVs per file is invisible on
# one structure and fatal on a directory of twenty thousand.
#
# The structure is also checked for reference cycles: a residue that pointed
# back at its chain would never be freed, and no test of a single file would
# ever notice.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Scalar::Util qw(refaddr weaken);
use Test::More;

my $data = dirname(abs_path(__FILE__)) . '/data';

BEGIN {
	eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 }
		or plan skip_all => 'Test::LeakTrace is not installed';
}
use Chem::Structure::Parser;

# Devel::Cover, under which there is no leak count to take.
#
# Test::LeakTrace's CAVEATS say it "does not work with Devel::Cover", and
# leaks_cmp_ok() carries the guard for it: where the runops routine is not
# perl's own it reports 'skipped (under Devel::Cover)' and tests nothing.
# Devel::Cover 1.52 installs no runops routine, so that guard never fires and
# every statement it has instrumented is counted as a leak instead -- `cover -t'
# failed 65 of this file's 85 tests, each reported leak one of Devel::Cover's
# own per-statement counters (an IV holding a pointer) attributed to a line of
# Parser.pm.  They are not this module's SVs and no arrangement of this module's
# reference counts would make them go away.
#
# ~/Scripts/stats/t/01.t writes `unless $INC{'Devel/Cover.pm'}' on each call.
# Spelled that way here the blocks would not run at all, and a coverage run
# would then have no figure for the paths several of them are the only caller
# of, so the guard is in one place and runs the block anyway: what is dropped is
# the count, which is the only part Devel::Cover has made meaningless.
if (exists $INC{'Devel/Cover.pm'}) {
	no warnings 'redefine';    # the same prototype, so no mismatch to warn about
	*no_leaks_ok = sub (&;$) {
		my ($block, $description) = @_;
		my $ok = eval { $block->(); 1 };
		diag($@) unless $ok;
		ok($ok, (defined $description ? "$description: " : '')
		        . 'skipped (under Devel::Cover)');
	};
}

#--------
# the XS parse
#--------
no_leaks_ok {
	Chem::Structure::Parser::_parse_file("$data/mini.pdb", {});
} '_parse_file does not leak';

no_leaks_ok {
	Chem::Structure::Parser::_parse_string("ATOM      1  CA  ALA A   1      1.0  2.0  3.0\n", {});
} '_parse_string does not leak';

no_leaks_ok {
	eval { Chem::Structure::Parser::_parse_file("$data/no.such.file.pdb", {}) };
} 'a failed open does not leak the buffer it had already allocated';

no_leaks_ok {
	eval { Chem::Structure::Parser::_parse_string('', 'not a hashref') };
} 'a rejected argument does not leak';

# the mmCIF parse, which allocates on its own account: the tag list of every
# loop_ is a Newx block that has to be freed on each of the ways out of one
no_leaks_ok {
	Chem::Structure::Parser::_parse_cif_file("$data/mini.cif", {});
} '_parse_cif_file does not leak';

no_leaks_ok {
	Chem::Structure::Parser::_parse_cif_file("$data/quirks.cif", {});
} 'nor does one that leans on the syntax';

no_leaks_ok {
	Chem::Structure::Parser::_parse_cif_string("data_x\nloop_\n_atom_site.id\n1\n", {});
} '_parse_cif_string does not leak';

no_leaks_ok {
	Chem::Structure::Parser::_parse_cif_string("data_x\nloop_\n_atom_site.id\n", {});
} 'a loop_ with tags and no rows does not leak the tags';

no_leaks_ok {
	Chem::Structure::Parser::_parse_cif_string("data_x\nloop_\nvalue\n", {});
} 'nor does a loop_ with no tags at all';

no_leaks_ok {
	eval { Chem::Structure::Parser::_parse_cif_file("$data/no.such.file.cif", {}) };
} 'a failed open does not leak on the mmCIF path either';

no_leaks_ok { aa3to1('ALA'); aa3to1('NAG'); res1('DA'); res_type('HOH');
              aa1to3('A'); aa1to3('*') }
	'the residue name lookups do not leak';

no_leaks_ok { eval { aa3to1(undef) } } 'nor does the croak on an undefined name';

#--------
# the whole read
#--------
no_leaks_ok { structure_info("$data/mini.pdb") } 'structure_info does not leak';
no_leaks_ok { structure_info("$data/nmr.pdb", model => 'all') }
	'reading every model does not leak';
no_leaks_ok { structure_info("$data/mini.pdb", atoms => 0, waters => 0, hydrogens => 0) }
	'reading with the filters on does not leak';
no_leaks_ok { structure_info("$data/empty.pdb") } 'an empty file does not leak';

no_leaks_ok { structure_info("$data/mini.cif") } 'reading an mmCIF does not leak';
no_leaks_ok { structure_info("$data/nmr.cif", model => 'all') }
	'nor does reading every model of one';
no_leaks_ok { structure_info("$data/mini.cif", atoms => 0, waters => 0, hydrogens => 0) }
	'nor does reading one with the filters on';
no_leaks_ok { structure_info("$data/empty.cif") } 'nor does an empty one';

#--------
# the views
#--------
{
	my $info = structure_info("$data/mini.pdb");
	no_leaks_ok { structure_atoms($info) }     'structure_atoms does not leak';
	no_leaks_ok { structure_residues($info) }  'structure_residues does not leak';
	no_leaks_ok { structure_ligands($info) }   'structure_ligands does not leak';
	no_leaks_ok { structure_sequences($info) } 'structure_sequences does not leak';
	no_leaks_ok { structure_summary($info) }   'structure_summary does not leak';
	no_leaks_ok { eval { structure_atoms($info, 'Z') } } 'a failed view does not leak';
	no_leaks_ok { is_single_ion($info, 'A'); is_single_ion($info->{chains}{B}) }
		'is_single_ion does not leak: it reads the hash and takes nothing from it';
	no_leaks_ok { eval { is_single_ion($info) }; eval { is_single_ion($info, 'Z') } }
		'nor do its complaints';
}

#--------
# the physical properties
#
# Every one of these allocates on its own account -- the coordinate arrays, the
# grid, the sphere points, the neighbour list -- and hands back a hash of hashes
# built from scratch, so both halves of the usual XS mistake are available here.
# The store => 1 form also writes into a structure that already exists, which is
# the case where an SV is overwritten rather than created.
#--------
{
	my $info = structure_info("$data/stack.pdb");
	no_leaks_ok { structure_features($info) } 'structure_features does not leak';
	no_leaks_ok { structure_features($info, store => 0) }
		'nor does it with nothing written back';
	no_leaks_ok { structure_sasa($info) }        'structure_sasa does not leak';
	no_leaks_ok { structure_pi_stacking($info) } 'structure_pi_stacking does not leak';
	no_leaks_ok { structure_disulfides($info) } 'structure_disulfides does not leak';
	no_leaks_ok { structure_features($info, sasa => 0) }
		'nor does asking for only half of it';
	no_leaks_ok { structure_features($info, pi_stacking => 0) } 'or the other half';
	no_leaks_ok { structure_features($info, disulfides => 0) } 'or without the disulfides';
	no_leaks_ok { structure_contacts($info) } 'structure_contacts does not leak';
	no_leaks_ok { structure_hbonds($info) }   'structure_hbonds does not leak';
	no_leaks_ok { structure_dssp($info) }     'structure_dssp does not leak';
}
{
	# fold.pdb is a real backbone, so this is the secondary structure with
	# something in it rather than an empty hash of hashes: the roll-up builds an
	# array per chain per letter and one SV per residue, which is exactly the
	# shape a reference count goes wrong in
	my $info = structure_info("$data/fold.pdb");
	no_leaks_ok { structure_dssp($info) } 'nor does it on a structure with a fold';
	no_leaks_ok { structure_features($info, store => 0) }
		'nor with nothing written back onto the residues';
	no_leaks_ok { structure_info("$data/fold.pdb", 'dssp') }
		"structure_info(\$file, 'dssp') does not leak";
	no_leaks_ok { structure_info("$data/fold.pdb", dssp => 1) }
		'nor does dssp => 1';
	no_leaks_ok { eval { structure_info("$data/fold.pdb", 'nosuch') } }
		'nor does a view that is not one';
	for my $off (qw(shape dihedrals contacts exposure hbonds secondary interface)) {
		no_leaks_ok { structure_features($info, $off => 0) } "nor does $off => 0";
	}
	no_leaks_ok { eval { structure_features($info, probe => -1) } }
		'a refused option does not leak';
	no_leaks_ok { eval { structure_features({ chains => {} }) } }
		'nor does a structure with nothing in it';
}
{
	# the croak path with the arrays already allocated: read without atom
	# hashes, so set_build() has filled its buffers before it gives up
	my $bare = structure_info("$data/stack.pdb", atoms => 0);
	no_leaks_ok { eval { structure_features($bare) } }
		'giving up on a structure read with atoms => 0 frees what was allocated first';
}
no_leaks_ok { structure_features(structure_info("$data/empty.pdb")) }
	'an empty structure does not leak';
no_leaks_ok { structure_features(structure_info("$data/bases.cif")) }
	'nor does an mmCIF one with rings in it';
{
	# the disulfide list is written onto the residues as well as returned, and
	# a second call has to replace it rather than add to it -- which is a
	# delete and a fresh AV, the shape a reference count goes wrong in
	my $ss = structure_info("$data/ss.pdb");
	no_leaks_ok { structure_features($ss) } 'a structure with disulfides does not leak';
	no_leaks_ok { structure_features($ss) for 1 .. 3 }
		'nor does replacing what an earlier call wrote onto its residues';
}
no_leaks_ok { structure_info("$data/ss.pdb") }
	'and neither does structure_info computing all of it on the way past';
{
	# the folded fixture is the one with hydrogen bonds, secondary structure and
	# torsion angles in it, all of which are written onto the residues and all of
	# which have to be replaced rather than added to on a second call
	my $fold = structure_info("$data/fold.pdb");
	no_leaks_ok { structure_features($fold) } 'a folded structure does not leak';
	no_leaks_ok { structure_features($fold) for 1 .. 3 }
		'nor does asking three more times';
	no_leaks_ok { structure_hbonds($fold, peptide_bond => 2.0) }
		'nor does a hydrogen bond list built to a different rule';
}
no_leaks_ok { structure_info("$data/fold.cif") }
	'nor the same structure read as mmCIF';
{
	# the nucleic fixtures are where the torsion block writes a five-element
	# array and three strings onto every residue, all of which a second call
	# has to replace rather than add to
	my $rna = structure_info("$data/rna.pdb");
	no_leaks_ok { structure_features($rna) } 'an RNA structure does not leak';
	no_leaks_ok { structure_features($rna) for 1 .. 3 }
		'nor does replacing the nu list and the pucker names three times over';
	no_leaks_ok { structure_features($rna, phosphodiester_bond => 1.2) }
		'nor a torsion set built to a rule that links nothing';
	no_leaks_ok { structure_info("$data/duplex.cif") }
		'nor a B-DNA duplex read as mmCIF';

	# and the base pairs, which build a list of hashes per pair and hang a
	# second list off each of the two residues
	my $wob = structure_info("$data/wobble.pdb");
	no_leaks_ok { structure_base_pairs($wob) } 'structure_base_pairs does not leak';
	no_leaks_ok { structure_base_pairs($wob) for 1 .. 3 }
		'nor does replacing every residue\'s base_pair list three times over';
	no_leaks_ok { structure_base_pairs($wob, base_pair_stagger => 0) }
		'nor a rule that pairs nothing, which has to clear them instead';
	no_leaks_ok { structure_base_pairs($wob, base_pair_hbond => 5.3, store => 0) }
		'nor a wider one asked without storing';
	no_leaks_ok { structure_features($wob, base_pairs => 0) } 'or without them at all';
	no_leaks_ok { structure_info("$data/wobble.cif") }
		'nor the same duplex read as mmCIF';

	# and the base stacks, which are the same shape again: a list of hashes per
	# pair, a second list hung off each of the two residues, and two cutoffs
	# either of which can leave a residue with nothing on it
	my $afm = structure_info("$data/aform.pdb");
	no_leaks_ok { structure_base_stacks($afm) } 'structure_base_stacks does not leak';
	no_leaks_ok { structure_base_stacks($afm) for 1 .. 3 }
		'nor does replacing every residue\'s base_stack list three times over';
	no_leaks_ok { structure_base_stacks($afm, base_stack_distance => 3) }
		'nor a cutoff that stacks nothing, which has to clear them instead';
	no_leaks_ok { structure_base_stacks($afm, base_stack_omega => 30, store => 0) }
		'nor a narrower one asked without storing, where no pair carries a Xi';
	no_leaks_ok { structure_features($afm, base_stacks => 0) } 'or without them at all';
	no_leaks_ok { structure_info("$data/aform.cif") }
		'nor the same strand read as mmCIF';
}

#--------
# structure_rmsd(), which builds a matrix of new SVs and holds several
# structsets open at once
#--------
{
	my $ens = structure_info("$data/ensemble.pdb", model => 'all', features => 0);
	my @m = map { $ens->{models}{$_} } sort { $a <=> $b } keys %{ $ens->{models} };
	no_leaks_ok { Chem::Structure::Parser::_rmsd(\@m, {}) }
		'the XS behind structure_rmsd does not leak';
	no_leaks_ok { Chem::Structure::Parser::_rmsd([ @m[0, 1] ], { transform => 1 }) }
		'nor does the rotation and translation it hands back on request';
	no_leaks_ok { Chem::Structure::Parser::_rmsd([ @m[0, 1] ], { fit => 0 }) }
		'nor the answer without a fit';
	no_leaks_ok { Chem::Structure::Parser::_rmsd(\@m, { select => 'ca', min_atoms => 6 }) }
		'nor a matrix whose cells are all undef for want of atoms';
	no_leaks_ok { eval { Chem::Structure::Parser::_rmsd(\@m, { select => 'no such' }) } }
		'and a rejected option gives back everything it had allocated';
	no_leaks_ok { structure_rmsd($ens) } 'structure_rmsd over an ensemble does not leak';
	no_leaks_ok { structure_rmsd($ens, chain_map => { B => 'B' }, select => 'heavy') }
		'nor the copies a chain_map makes';
	no_leaks_ok { structure_rmsd("$data/nmr.pdb", "$data/nmr.cif") }
		'nor reading the two files it is given';
	no_leaks_ok { eval { structure_rmsd($ens, fitt => 1) } }
		'nor a call that dies in the argument check';
}

#--------
# no cycles: the whole structure must go away when the caller drops it
#--------
for my $stem (qw(mini.pdb mini.cif)) {
	my $info = structure_info("$data/$stem");
	my $chain   = $info->{chains}{A};
	my $residue = $info->{chains}{A}{residues}{6};
	my $atom    = $info->{chains}{A}{residues}{6}{atoms}{CA};
	# with the properties written into it too, in case one of them left a
	# reference pointing back up the structure
	structure_features($info);
	weaken($chain);
	weaken($residue);
	weaken($atom);
	undef $info;
	is($chain,   undef, "$stem: dropping the structure frees its chains");
	is($residue, undef, "$stem: and its residues");
	is($atom,    undef, "$stem: and its atoms: nothing points back up at its parent");
}

done_testing();
