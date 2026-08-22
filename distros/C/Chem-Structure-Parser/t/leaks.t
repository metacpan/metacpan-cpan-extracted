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
# no cycles: the whole structure must go away when the caller drops it
#--------
for my $stem (qw(mini.pdb mini.cif)) {
	my $info = structure_info("$data/$stem");
	my $chain   = $info->{chains}{A};
	my $residue = $info->{chains}{A}{residues}{6};
	my $atom    = $info->{chains}{A}{residues}{6}{atoms}{CA};
	weaken($chain);
	weaken($residue);
	weaken($atom);
	undef $info;
	is($chain,   undef, "$stem: dropping the structure frees its chains");
	is($residue, undef, "$stem: and its residues");
	is($atom,    undef, "$stem: and its atoms: nothing points back up at its parent");
}

done_testing();
