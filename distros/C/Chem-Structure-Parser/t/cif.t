#!/usr/bin/env perl
# mmCIF.
#
# The claim this file exists to check is a single one: which format a
# structure arrived in does not change the structure.  So most of what is
# below reads the same structure twice, once from a .pdb and once from a .cif,
# and asserts that the two are equal -- not similar, not equal in the fields
# that were thought of, but equal, by is_deeply, over the whole coordinate
# half of the returned hash.
#
# The fixture pairs are written by t/data/generate.pl, which converts the PDB
# records into the mmCIF loop rather than typing the atoms twice, so that any
# difference between the two files is one the generator put there on purpose.
# The one it puts there on purpose is the naming: the .cif files carry
# label_asym_id and label_seq_id that deliberately disagree with the chain ids
# and residue numbers, because auth_* is what a PDB record carries and auth_*
# is what a reader has to use.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Temp 'tempdir';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

my $data = dirname(abs_path(__FILE__)) . '/data';

# coords() -- the half of a parsed structure that the coordinates decide: every
# chain, every residue, every atom, and the counts over them.
#
# What is taken back out is the handful of things _chain_stats() folds into a
# chain from the header, because those are the header's answer and not the
# coordinates', and the header section below tests them against each other one
# at a time.  A fixture pair cannot be equal on all of them anyway -- mini.cif
# names the entity every ligand belongs to and mini.pdb has no record that
# does -- and burying that in this comparison would only make it say
# 'structures differ' about something the header tests say properly.
my @FROM_HEADER = qw(seqres seqres_length n_missing mol_id molecule organism
                     fragment ec dbref);

sub coords {
	my ($i) = @_;
	my %s = %{ $i->{stats} };
	delete $s{n_lines};    # an mmCIF row and a PDB record are not the same line
	my $strip = sub {
		my ($set) = @_;
		return { map {
			my %c = %{ $set->{$_} };
			delete @c{@FROM_HEADER};
			$_ => \%c;
		} keys %$set };
	};
	return {
		chains      => $strip->($i->{chains}),
		chain_order => $i->{chain_order},
		stats       => \%s,
		model       => $i->{model},
		n_models    => $i->{n_models},
		(exists $i->{models}
			? (models => { map { $_ => { chains      => $strip->($i->{models}{$_}{chains}),
			                             chain_order => $i->{models}{$_}{chain_order} } }
			               keys %{ $i->{models} } })
			: ()),
	};
}

#--------------------------------------------------------------------
# the same structure, both ways
#--------------------------------------------------------------------
for my $pair ([ 'mini', 'one of everything' ],
              [ 'nmr',  'a three model ensemble' ],
              [ 'bare', 'coordinates and nothing else' ]) {
	my ($stem, $what) = @$pair;
	my $p = structure_info("$data/$stem.pdb");
	my $c = structure_info("$data/$stem.cif");

	is($p->{format}, 'pdb',   "$stem.pdb is read as PDB");
	is($c->{format}, 'mmcif', "$stem.cif is read as mmCIF");
	is_deeply(coords($c), coords($p),
		"$stem: $what -- every chain, residue, atom and count is the same from either file");

	# and the views over it, which are what most callers actually touch
	is_deeply(structure_atoms($c),    structure_atoms($p),    "$stem: structure_atoms agrees");
	is_deeply(structure_residues($c), structure_residues($p), "$stem: structure_residues agrees");
	is_deeply(structure_ligands($c),  structure_ligands($p),  "$stem: structure_ligands agrees");
	is_deeply(structure_sequences($c), structure_sequences($p), "$stem: structure_sequences agrees");
	is_deeply(structure_sequences("$data/$stem.cif"), structure_sequences("$data/$stem.pdb"),
		"$stem: structure_sequences agrees when handed the file name");
}

# bare.cif has no _atom_site.type_symbol, as bare.pdb has no element columns,
# so both readers have to get the element out of the atom name -- and get the
# same answer, which is what stops a CA becoming calcium in one and carbon in
# the other
{
	my $c = structure_info("$data/bare.cif");
	is($c->{chains}{A}{residues}{1}{atoms}{CA}{element}, 'C',
		'with no type_symbol the element is worked out from the atom name');
	is_deeply($c->{stats}{elements}, structure_info("$data/bare.pdb")->{stats}{elements},
		'and the element counts come out the same as from the PDB');
}

# the per-chain tally, which the two readers fill in from the same rule and so
# have to agree on chain by chain as well as structure-wide
{
	my $c = structure_info("$data/mini.cif");
	my $p = structure_info("$data/mini.pdb");
	is_deeply([ map { $c->{chains}{$_}{elements} } @{ $c->{chain_order} } ],
	          [ map { $p->{chains}{$_}{elements} } @{ $p->{chain_order} } ],
		'the per-chain element counts agree with the PDB reader');
	is($c->{chains}{A}{elements}{Zn}, 1,
		'and a type_symbol of ZN is filed under the IUPAC symbol');
}

#--------------------------------------------------------------------
# the header, where the two formats file the same fact differently
#--------------------------------------------------------------------
{
	my $p = structure_info("$data/mini.pdb");
	my $c = structure_info("$data/mini.cif");

	is($c->{id}, '9XYZ', 'the id comes from _entry.id');
	is($c->{title}, $p->{title}, 'the title is the same (a semicolon text field either way)');
	is($c->{resolution}, $p->{resolution}, 'the resolution is the same (REMARK 2 / _refine)');
	is($c->{r_work}, $p->{r_work}, 'R work is the same');
	is($c->{r_free}, $p->{r_free}, 'R free is the same');
	is($c->{temperature}, $p->{temperature}, 'the temperature is the same');
	is($c->{ph}, $p->{ph}, 'the pH is the same');
	is_deeply($c->{experiment}, $p->{experiment}, 'the experimental method is the same');
	is_deeply($c->{keywords},   $p->{keywords},   'the keywords are the same');
	is_deeply($c->{cryst1},     $p->{cryst1},     'the cell is the same (CRYST1 / _cell + _symmetry)');
	is($c->{header}{classification}, $p->{header}{classification},
		'the classification is the same (HEADER / _struct_keywords)');

	# SEQRES, which mmCIF splits across _entity_poly and _entity_poly_seq
	is_deeply($c->{seqres}, $p->{seqres}, 'SEQRES is the same, chain for chain');
	is($c->{chains}{A}{seqres}, 'MAGLKCMHHSC', 'and reaches the chain');
	is($c->{chains}{A}{n_missing}, $p->{chains}{A}{n_missing},
		'so the count of unmodelled residues is the same');
	is(chain_sequence($c, 'A', 'seqres'), chain_sequence($p, 'A', 'seqres'),
		'chain_sequence(seqres) agrees');
	is(chain_sequence($c, 'A', 'observed'), chain_sequence($p, 'A', 'observed'),
		'chain_sequence(observed) agrees');

	# the annotations
	is_deeply($c->{helix},  $p->{helix},  'HELIX is the same (_struct_conf)')
		or diag explain $c->{helix};
	is_deeply($c->{ssbond}, $p->{ssbond}, 'SSBOND is the same (_struct_conn disulf)');
	is_deeply($c->{link},   $p->{link},   'LINK is the same (_struct_conn covale)');
	is_deeply($c->{cispep}, $p->{cispep}, 'CISPEP is the same (_struct_mon_prot_cis)');
	is_deeply($c->{modres}, $p->{modres}, 'MODRES is the same (_pdbx_struct_mod_residue)');
	is_deeply($c->{dbref},  $p->{dbref},  'DBREF is the same (_struct_ref + _struct_ref_seq)');
	is($c->{sheet}[0]{init_resseq}, $p->{sheet}[0]{init_resseq}, 'SHEET starts at the same residue');
	is($c->{sheet}[0]{end_chain},   $p->{sheet}[0]{end_chain},   'and ends in the same chain');

	# the molecule a chain is, which mmCIF keeps in _entity
	is($c->{chains}{A}{molecule}, $p->{chains}{A}{molecule}, 'the chain knows its molecule');
	is($c->{chains}{B}{molecule}, $p->{chains}{B}{molecule}, 'and so does the second one');
	is($c->{chains}{A}{organism}, $p->{chains}{A}{organism}, 'and its organism');
	is($c->{chains}{A}{ec},       $p->{chains}{A}{ec},       'and its EC number');

	# heterogens: HET/HETNAM/FORMUL against _chem_comp/_pdbx_nonpoly_scheme
	is($c->{het}{NAG}{name},    $p->{het}{NAG}{name},    'a heterogen is named the same');
	is($c->{het}{ZN}{formula},  $p->{het}{ZN}{formula},  'and carries the same formula');
	is(scalar @{ $c->{het}{ZN}{instances} }, scalar @{ $p->{het}{ZN}{instances} },
		'and has the same number of instances');
	ok($c->{het}{HOH}{water}, 'water is marked as water');
	ok(!exists $c->{het}{ALA}, 'a standard residue is not a heterogen');

	is(scalar @{ $c->{authors} }, scalar @{ $p->{authors} }, 'the authors are all there');
	is($c->{journal}{pmid}, $p->{journal}{pmid}, 'the PubMed id is the same');
	is($c->{journal}{doi},  $p->{journal}{doi},  'the DOI is the same');
	is($c->{journal}{titl}, $p->{journal}{titl}, 'the paper title is the same');

	# a fact one format has and the other does not reads as absent, not as
	# wrong: an mmCIF file has no REMARK records
	is_deeply($c->{remarks}, {}, 'an mmCIF file has no remarks, and says so by having none');
	is_deeply($c->{conect}, [], 'and no CONECT');
	ok(exists $c->{keywords} && exists $c->{revdat} && exists $c->{compound},
		'but every key a caller might read is still there');
}

#--------------------------------------------------------------------
# options, which have to mean the same thing in both formats
#--------------------------------------------------------------------
for my $opt ([ { hydrogens => 0 },        'hydrogens => 0' ],
             [ { waters    => 0 },        'waters => 0' ],
             [ { hetatm    => 0 },        'hetatm => 0' ],
             [ { atoms     => 0 },        'atoms => 0' ],
             [ { meta      => 0 },        'meta => 0' ],
             [ { chains    => ['A'] },    'chains => [A]' ],
             [ { altloc    => 'highest' },'altloc => highest' ],
             [ { hydrogens => 0, waters => 0, hetatm => 0 }, 'three at once' ]) {
	my ($o, $what) = @$opt;
	is_deeply(coords(structure_info("$data/mini.cif", %$o)),
	          coords(structure_info("$data/mini.pdb", %$o)),
	          "$what does the same thing to an mmCIF as to a PDB");
}

# models
{
	for my $m (1, 2, 3) {
		is_deeply(coords(structure_info("$data/nmr.cif", model => $m)),
		          coords(structure_info("$data/nmr.pdb", model => $m)),
		          "model => $m picks the same model out of either format");
	}
	my $c = structure_info("$data/nmr.cif", model => 'all');
	my $p = structure_info("$data/nmr.pdb", model => 'all');
	is_deeply(coords($c), coords($p), "model => 'all' gives every model from either format");
	is($c->{n_models}, 3, 'and there are three of them');
	is($c->{n_models}, $p->{n_models}, 'which is what the PDB says as well');
	is($c->{n_models_declared}, $p->{n_models_declared},
		'NUMMDL and _pdbx_nmr_ensemble agree about how many were deposited');
	is_deeply($c->{seqres}, $p->{seqres}, 'and SEQRES is the same across an ensemble too');
	is($c->{chains}{A}{n_missing}, $p->{chains}{A}{n_missing},
		'so nothing reads as unmodelled in one and modelled in the other');

	# a model number the file does not have is not an empty structure
	my $one = structure_info("$data/nmr.cif", model => 9);
	is($one->{model}, 1, 'asking for a model that is not there falls back to the first');
	ok($one->{stats}{n_atoms} > 0, 'and comes back with atoms in it');
}

#--------------------------------------------------------------------
# how the format is written down
#--------------------------------------------------------------------
{
	my $q = structure_info("$data/quirks.cif");

	is($q->{id}, 'QRK', 'a comment on the data_ line does not become part of the block name');
	is($q->{title}, 'A file that leans on the syntax', 'a double-quoted value');
	is_deeply($q->{keywords}, [ 'one', 'two', 'three' ], 'a single-quoted value, split on commas');
	is_deeply($q->{experiment}, [ 'SOLUTION NMR' ], 'a semicolon text field');

	my $r = $q->{chains}{B}{residues}{1};
	is($r->{resname}, 'G', 'a row read with its columns in an unusual order');
	is_deeply([ @{ $r->{atom_order} } ], [ 'P', 'OP1', "O5'", "C1'" ],
		"a quote inside a value is part of it: O5' is an atom name, not an open string");
	is($r->{atoms}{P}{charge}, '', 'a formal charge of ? is no charge');
	is($r->{atoms}{OP1}{charge}, '1-', 'an mmCIF charge of -1 reads as the PDB spelling');
	is($r->{atoms}{"O5'"}{charge}, '0',
		'a charge of 0 reads as 0, which is not the same answer as no charge at all');
	is($r->{atoms}{"C1'"}{charge}, '3+', 'and a positive one takes its sign after it');
	is($r->{atoms}{P}{altloc}, '', 'a . altloc is an empty field');
	is($r->{atoms}{P}{bfactor}, 10, 'and the numbers around it still line up');

	my $zn = $q->{chains}{B}{residues}{'40A'};
	is($zn->{resname}, 'ZN', 'the HETATM row');
	is($zn->{icode}, 'A', 'has its insertion code');
	is($zn->{type}, 'ion', 'and is typed as an ion');
	is($zn->{atoms}{ZN}{charge}, '2+', 'with a charge of 2+');
	is($q->{het}{ZN}{name}, 'ZINC ION',
		'a category written as plain tags is read as a category with one row in it');
	is($q->{het}{ZN}{formula}, 'ZN 2+', 'both of its items');

	is($q->{journal}{titl}, 'A paper with a full stop.  And two sentences.',
		'a quoted value keeps its full stops');
	is($q->{cryst1}{a}, undef, 'a . value is nothing');
	is($q->{cryst1}{b}, undef, 'and so is a ? value');
	is($q->{header}{deposit_date}, '.',
		"but a quoted '.' is a full stop, because quoting is what makes it a value");

	# comments in every position
	ok($q->{stats}{n_atoms} == 5, 'a comment between rows of a loop ends the loop and nothing else');
}

#--------------------------------------------------------------------
# getting there: detection, the named entry points, strings, gzip
#--------------------------------------------------------------------
{
	is_deeply([ formats() ], [ 'mmcif', 'pdb' ], 'formats() lists both');
	my $all = formats();
	is($all->{mmcif}, 'supported', 'and mmCIF is one of the supported ones');

	# the names the format goes by, all meaning the one reader
	for my $name (qw(mmcif cif pdbx MMCIF CIF)) {
		is(structure_info("$data/mini.cif", format => $name)->{format}, 'mmcif',
			"format => '$name' names the mmCIF reader, and it reports back as mmcif");
	}
	is(structure_info("$data/mini.pdb", format => 'ent')->{format}, 'pdb',
		"format => 'ent' names the PDB reader");
	throws_ok { structure_info("$data/mini.cif", format => 'nonsense') }
		qr/unrecognized format/, 'a format that does not exist still dies';

	is(cif_info("$data/mini.cif")->{format}, 'mmcif', 'cif_info() reads an mmCIF');
	is(pdb_info("$data/mini.pdb")->{format}, 'pdb',   'pdb_info() still reads a PDB');
	is_deeply(coords(cif_info("$data/mini.cif")), coords(structure_info("$data/mini.cif")),
		'cif_info() and structure_info() agree about a file they both read');

	# cif_info() and pdb_info() are the caller saying which format this is, and
	# saying so wrongly reads no atoms rather than dying -- the same as
	# format => 'pdb' on anything else, which t/errors.t pins down.  It is why
	# neither of them is the usual way in: structure_info() works it out.
	is(cif_info("$data/mini.pdb")->{stats}{n_atoms}, 0,
		'a PDB read as mmCIF because it was told to yields nothing, rather than nonsense');
	is(structure_info("$data/mini.pdb")->{format}, 'pdb',
		'while structure_info() looks at the file and gets it right');

	# the name decides, and when the name says nothing the contents do
	my $dir = tempdir(CLEANUP => 1);
	for my $ext (qw(cif mmcif pdbx)) {
		my $f = "$dir/x.$ext";
		open my $fh, '>', $f or die $!;
		open my $in, '<', "$data/mini.cif" or die $!;
		print {$fh} <$in>;
		close $in;
		close $fh;
		is(structure_info($f)->{format}, 'mmcif', ".$ext is recognised by its name");
	}
	{
		my $f = "$dir/nameless.dat";
		open my $fh, '>', $f or die $!;
		open my $in, '<', "$data/mini.cif" or die $!;
		print {$fh} <$in>;
		close $in;
		close $fh;
		is(structure_info($f)->{format}, 'mmcif',
			'a name that gives nothing away is settled by the first records');
	}

	# from a string
	my $text = do {
		open my $in, '<', "$data/mini.cif" or die $!;
		local $/;
		<$in>;
	};
	is_deeply(coords(structure_info_string($text)),
	          coords(structure_info("$data/mini.cif")),
	          'structure_info_string() reads mmCIF text and gets the same structure');
	is(structure_info_string($text)->{format}, 'mmcif', 'and knows what it read');

	# an empty file is not an error in either format
	lives_ok { structure_info("$data/empty.cif") } 'an empty mmCIF does not die';
	is(structure_info("$data/empty.cif")->{stats}{n_atoms}, 0, 'and has no atoms');

	# .gz
	SKIP: {
		eval { require IO::Compress::Gzip; 1 } or skip 'IO::Compress is not installed', 2;
		IO::Compress::Gzip::gzip("$data/mini.cif" => "$dir/mini.cif.gz")
			or skip 'cannot gzip the fixture: '
			        . do { no warnings 'once'; $IO::Compress::Gzip::GzipError }, 2;
		my $gz = structure_info("$dir/mini.cif.gz");
		is($gz->{format}, 'mmcif', 'a gzipped .cif.gz is still an mmCIF');
		is_deeply(coords($gz), coords(structure_info("$data/mini.cif")),
			'and reads the same as the file it was made from');
	}
}

#--------------------------------------------------------------------
# damage.  A file that is wrong is not the caller's fault, and half a
# structure is usually still worth having.
#--------------------------------------------------------------------
{
	my $dir = tempdir(CLEANUP => 1);
	my %broken = (
		'a loop_ whose last row stops short' =>
			"data_x\nloop_\n_atom_site.group_PDB\n_atom_site.auth_atom_id\n"
			. "_atom_site.auth_comp_id\n_atom_site.auth_asym_id\n_atom_site.auth_seq_id\n"
			. "_atom_site.Cartn_x\n_atom_site.Cartn_y\n_atom_site.Cartn_z\n"
			. "ATOM CA ALA A 1 1.0 2.0 3.0\nATOM CB ALA A 1\n",
		'a semicolon field that is never closed' =>
			"data_x\n_struct.title\n;a title that runs off the end of the file\n",
		'a quote that is never closed' =>
			"data_x\n_struct.title  'off the end\n",
		'a tag with no value after it' =>
			"data_x\n_struct.title\n",
		'a loop_ with tags and no rows' =>
			"data_x\nloop_\n_atom_site.group_PDB\n_atom_site.id\n",
		'a loop_ with no tags at all' => "data_x\nloop_\nATOM 1 2 3\n",
		'nothing but a data_ line'    => "data_x\n",
		'a stray value with no tag'   => "data_x\nlonely\n_entry.id  Z\n",
	);
	for my $what (sort keys %broken) {
		my $f = "$dir/broken.cif";
		open my $fh, '>', $f or die $!;
		print {$fh} $broken{$what};
		close $fh;
		lives_ok { structure_info($f) } "$what does not die";
	}
}

done_testing();
