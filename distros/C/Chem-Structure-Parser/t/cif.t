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
require 5.010001;
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
              [ 'bare', 'coordinates and nothing else' ],
              [ 'numbering', 'residue and serial numbers past the decimal columns' ]) {
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
	# The secondary structure is the one property whose inputs are not only
	# coordinates: it wants to know where one chain stops and the next begins,
	# and the two formats say so differently -- a TER record on one side and
	# label_asym_id on the other.  Neither is read; the chains are this module's
	# own, so both files answer the same.
	is_deeply(structure_dssp($c), structure_dssp($p), "$stem: structure_dssp agrees");
	is_deeply(structure_info("$data/$stem.cif", 'dssp'),
	          structure_info("$data/$stem.pdb", 'dssp'),
		"$stem: and so does structure_info(\$file, 'dssp')");
}

# The secondary structure over every pair in t/data, not only the three above.
# It is the one property that asks where a chain stops, and the two formats say
# so differently -- a TER record on one side, label_asym_id on the other --
# which makes it the property most likely to come apart across them.  fold.pdb
# is the one with a fold in it, so it is the one that has letters to compare.
{
	opendir(my $dh, $data) or die "$data: $!";
	my @stems = sort grep { -e "$data/$_.cif" }
	            map { /\A(.+)\.pdb\z/ ? $1 : () } readdir $dh;
	closedir $dh;
	ok(scalar @stems >= 3, 'there are structures in both formats to compare');
	my $lettered = 0;
	for my $stem (@stems) {
		my $d = structure_info("$data/$stem.pdb", 'dssp');
		is_deeply(structure_info("$data/$stem.cif", 'dssp'), $d,
			"$stem: the same secondary structure from either format");
		for my $cid (keys %$d) {
			$lettered += scalar @{ $d->{$cid}{$_} } for keys %{ $d->{$cid} };
		}
	}
	cmp_ok($lettered, '>', 0,
		'and there were residues with a letter, so this compared something');
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
	is_deeply($c->{sheet},  $p->{sheet},
		'SHEET is the same, strand count and sense included (_struct_sheet_range, _struct_sheet, _struct_sheet_order)')
		or diag explain $c->{sheet};
	is($c->{helix}[0]{id}, 'AA1', "a helix's id is the HELIX record's, not the mmCIF row's HELX_P1");
	is_deeply($c->{dbref}{B}, $p->{dbref}{B}, 'and a DBREF1/DBREF2 pair is the same as its _struct_ref row');

	# the molecule a chain is, which mmCIF keeps in _entity
	is($c->{chains}{A}{molecule}, $p->{chains}{A}{molecule}, 'the chain knows its molecule');
	is($c->{chains}{B}{molecule}, $p->{chains}{B}{molecule}, 'and so does the second one');
	is($c->{chains}{A}{organism}, $p->{chains}{A}{organism}, 'and its organism');
	is($c->{chains}{A}{ec},       $p->{chains}{A}{ec},       'and its EC number');
	is($c->{chains}{A}{fragment}, 'CATALYTIC DOMAIN',        'and its fragment (_entity.pdbx_fragment)');
	is($c->{chains}{A}{fragment}, $p->{chains}{A}{fragment}, 'the same as COMPND FRAGMENT');
	is($c->{chains}{B}{organism}, 'SYNTHETIC CONSTRUCT',
		'a synthetic entity names its organism (_pdbx_entity_src_syn)');
	is($c->{chains}{B}{organism}, $p->{chains}{B}{organism}, 'as SOURCE does');
	is($c->{source}{2}{synthetic}, $p->{source}{2}{synthetic}, 'and says it is synthetic as SOURCE does');

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
# getting there: detection, naming the format, strings, gzip
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

	is_deeply(coords(structure_info("$data/mini.cif", format => 'mmcif')),
	          coords(structure_info("$data/mini.cif")),
		'naming the format and letting it be detected give the same structure');

	# format => is the caller saying which format this is, and saying so wrongly
	# reads no atoms rather than dying -- the same as format => 'pdb' on anything
	# else, which t/errors.t pins down.  It is why naming it is not the usual way
	# in: structure_info() works it out.
	is(structure_info("$data/mini.pdb", format => 'mmcif')->{stats}{n_atoms}, 0,
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
	# .bz2
	SKIP: {
		eval { require IO::Compress::Bzip2; 1 } or skip 'IO::Compress::Bzip2 is not installed', 2;
		IO::Compress::Bzip2::bzip2("$data/mini.cif" => "$dir/mini.cif.bz2")
			or skip 'cannot bzip2 the fixture: '
			        . do { no warnings 'once'; $IO::Compress::Bzip2::Bzip2Error }, 2;
		my $bz = structure_info("$dir/mini.cif.bz2");
		is($bz->{format}, 'mmcif', 'a .cif.bz2 is still an mmCIF');
		is_deeply(coords($bz), coords(structure_info("$data/mini.cif")),
			'and reads the same as the file it was made from');
	}
}

#--------------------------------------------------------------------
# the rest of the syntax, and the categories the fixtures have no use for
#
# quirks.cif carries the syntax a real entry leans on; what is here is the
# syntax a real entry is allowed to lean on and generally does not, plus the
# header categories that only some entries carry.  They are strings rather than
# fixtures because none of them is a structure anybody deposited -- a file with
# all of them at once would be a file nothing wrote.
#--------------------------------------------------------------------
{
	# _atom_site written as plain tags.  A table with one row may be written
	# without a loop_, which the format allows for every category and which a
	# reader that only understands loop_ reads as a file with no atoms in it.
	my $i = structure_info_string(<<'CIF', format => 'mmcif');
data_SINGLE
_atom_site.group_PDB      ATOM
_atom_site.id             1
_atom_site.type_symbol    C
_atom_site.auth_atom_id   CA
_atom_site.auth_comp_id   ALA
_atom_site.auth_asym_id   A
_atom_site.auth_seq_id    1
_atom_site.Cartn_x        1.000
_atom_site.Cartn_y        2.000
_atom_site.Cartn_z        3.000
_atom_site.occupancy      1.00
_atom_site.B_iso_or_equiv 20.00
_atom_site_anisotrop.id   1
CIF
	is($i->{stats}{n_atoms}, 1, 'an _atom_site written as plain tags is one atom');
	is($i->{chains}{A}{residues}{1}{atoms}{CA}{x}, 1, 'with its coordinates');
	is($i->{chains}{A}{sequence}, 'A', 'and its residue');
	is($i->{stats}{n_anisou}, 1,
		'and an _atom_site_anisotrop written the same way is still counted');
}
{
	# An mmCIF chain id has no width.  A simulation program writes segment
	# names like these as auth_asym_id, and a reader that copied them into a
	# buffer of eight bytes read both as SEG1PRO and made one chain of two.
	my $text = <<'CIF';
data_X
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
ATOM 1 C CA ALA SEG1PROA 1 1 2 3
ATOM 2 C CA ALA SEG1PROB 1 4 5 6
ATOM 3 C CA GLY SEG1PROB 2 7 8 9
CIF
	for my $o ([], [ atoms => 0 ]) {
		my $i = structure_info_string($text, format => 'mmcif', @$o);
		is_deeply($i->{chain_order}, [ 'SEG1PROA', 'SEG1PROB' ],
			"chain ids longer than seven characters are kept whole (@$o)");
		is($i->{chains}{SEG1PROB}{sequence}, 'AG', 'and the second chain is its own');
	}
	my $one = structure_info_string($text, format => 'mmcif', chains => [ 'SEG1PROB' ]);
	is($one->{stats}{n_atoms}, 2, 'and chains => picks one of them out by its whole name');
}
{
	# One entity from more than one source.  1shz's chimera is seven segments,
	# rat and mouse by turns, seven rows of _entity_src_gen; its PDB file says
	# 'ORGANISM_SCIENTIFIC: RATTUS NORVEGICUS, MUS MUSCULUS' and
	# 'ORGANISM_TAXID: 10116, 10090'.  These are the first three of those rows,
	# cut down to the items read.
	my $i = structure_info_string(<<'CIF', format => 'mmcif');
data_1SHZ
_entry.id 1SHZ
loop_
_entity_poly.entity_id
_entity_poly.pdbx_strand_id
1 A,D
loop_
_entity_src_gen.entity_id
_entity_src_gen.pdbx_src_id
_entity_src_gen.pdbx_gene_src_scientific_name
_entity_src_gen.pdbx_gene_src_ncbi_taxonomy_id
_entity_src_gen.pdbx_host_org_scientific_name
1 1 'Rattus norvegicus' 10116 'Escherichia coli'
1 3 'Rattus norvegicus' 10116 'Escherichia coli'
1 2 'Mus musculus'      10090 'Escherichia coli'
loop_
_entity_src_nat.entity_id
_entity_src_nat.pdbx_organism_scientific
1 'Not this one'
CIF
	is($i->{source}{1}{organism_scientific}, 'Rattus norvegicus, Mus musculus',
		'an entity with several sources names each organism once, as SOURCE does');
	is($i->{source}{1}{organism_taxid}, '10116, 10090', 'and each taxonomy id');
	is($i->{source}{1}{expression_system}, 'Escherichia coli', 'and a host they share once');
	is($i->{entity_of_chain}{D}{organism}, 'Rattus norvegicus, Mus musculus',
		'which every chain of it carries');
}
{
	# Two loop_ blocks of one category, a value that spans lines, and a quote
	# inside a quoted value.  The first is legal and rare; the second is how
	# anything longer than a line is written; the third is why a closing quote
	# is one followed by whitespace rather than the first one found.
	my $i = structure_info_string(<<'CIF', format => 'mmcif');
data_X
_entry.id X
loop_
_entity.id
_entity.pdbx_description
1 'First molecule'
loop_
_entity.id
_entity.pdbx_description
2 'Second molecule'
loop_
_entity_poly.entity_id
_entity_poly.pdbx_strand_id
_entity_poly.pdbx_seq_one_letter_code_can
1 A
;MKVLA(MSE)
GSW
;
loop_
_entity_src_nat.entity_id
_entity_src_nat.pdbx_organism_scientific
_entity_src_nat.pdbx_ncbi_taxonomy_id
1 'Homo sapiens' 9606
loop_
_pdbx_audit_revision_history.ordinal
_pdbx_audit_revision_history.revision_date
_pdbx_audit_revision_history.data_content_type
1 2001-01-01 'Structure model'
2 2011-07-13 'Structure model'
_struct.title
;A title
that runs over
three lines
;
_struct_keywords.text  'it's here, and there'
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
ATOM 1 C CA ALA A 1 1.0 2.0 3.0
CIF
	is($i->{title}, "A title\nthat runs over\nthree lines",
		'a semicolon field is every line of it, newlines and all');
	is_deeply($i->{keywords}, [ "it's here", 'and there' ],
		"a quote inside a quoted value is part of the value: only one followed by space closes it");
	is($i->{compound}{1}{molecule}, 'First molecule',
		'the first of two loop_ blocks of one category is read');
	is($i->{compound}{2}{molecule}, 'Second molecule', 'and so is the second');
	is($i->{chains}{A}{molecule}, 'First molecule',
		'and the chain gets the molecule of the entity that claims it');
	is($i->{chains}{A}{organism}, 'Homo sapiens',
		'_entity_src_nat names the organism where _entity_src_gen would have');
	is($i->{seqres}{A}{sequence}, 'MKVLAXGSW',
		'a file with no _entity_poly_seq still has its sequence, with a bracketed residue as X');
	is($i->{seqres}{A}{length}, 9, 'and its length is the sequence it gave');
	is_deeply($i->{seqres}{A}{residues}, [],
		'what is lost is the residue names, which that form does not carry');
	is(scalar @{ $i->{revdat} }, 2, 'the revision history is the REVDAT of an mmCIF');
	is($i->{revdat}[1]{date}, '2011-07-13', 'with the date of each revision');
	is($i->{revdat}[1]{id}, 'X', 'filed under the entry the PDB reader would have named');
}
{
	# Microheterogeneity in the sequence: 1ejg.cif's _entity_poly_seq rows 20 to
	# 26, where num 22 is PRO and SER and num 25 is LEU and ILE, one row for
	# each.  1ejg.pdb's SEQRES names the first of each pair and nothing else,
	# which is what the PDB reader has to go on, so the two formats agree only
	# if this reads one residue per num.
	my $cif = structure_info_string(<<'CIF', format => 'mmcif', features => 0);
data_X
loop_
_entity_poly.entity_id
_entity_poly.pdbx_strand_id
1 A
loop_
_entity_poly_seq.entity_id
_entity_poly_seq.num
_entity_poly_seq.mon_id
_entity_poly_seq.hetero
1 20 GLY n
1 21 THR n
1 22 PRO y
1 22 SER y
1 23 GLU n
1 24 ALA n
1 25 LEU y
1 25 ILE y
1 26 CYS n
CIF
	my $pdb = structure_info_string(<<'PDB', features => 0);
SEQRES   1 A    7  GLY THR PRO GLU ALA LEU CYS
PDB
	is_deeply($cif->{seqres}{A}, $pdb->{seqres}{A},
		'two chemical states at one position are one SEQRES residue, as in the PDB file');
	is($cif->{seqres}{A}{sequence}, 'GTPEALC', 'the first of each, in order');
}
{
	# A quote its line never closes.  CIF 1.1 has no quoted value that spans
	# lines, so it was never an opening quote: the word is read as it stands,
	# and the loop stays in step.  Scanning on for a closing quote used to read
	# the three rows below as one atom's name and lose them.
	my $i = structure_info_string(<<'CIF', format => 'mmcif', features => 0);
data_X
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
ATOM 1 N N ALA A 1 1.0 2.0 3.0
ATOM 2 C 'CA ALA A 1 2.0 2.0 3.0
ATOM 3 C C ALA A 1 3.0 2.0 3.0
ATOM 4 O O ALA A 1 4.0 2.0 3.0
ATOM 5 N N GLY A 2 5.0 2.0 3.0
CIF
	is($i->{stats}{n_atoms}, 5, 'a quote its line does not close costs no row below it');
	is_deeply($i->{chains}{A}{residue_order}, [ 1, 2 ], 'and puts no row out of step');
	is_deeply($i->{chains}{A}{residues}{1}{atom_order}, [ 'N', "'CA", 'C', 'O' ],
		'the word it began is read as written');
	is($i->{chains}{A}{residues}{2}{atoms}{N}{x}, 5, 'and the rows after it keep their columns');
}
{
	# The same quote on the last line of a file with no newline after it: the
	# file ending is the line ending, and the word is still read as written.
	# The scan used to stop at the end of the buffer thinking the value closed,
	# and read the rest of the row as the atom's name.
	my $i = structure_info_string(<<'CIF' . "ATOM 2 C 'CA ALA A 1 2.0 2.0 3.0", format => 'mmcif', features => 0);
data_X
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
ATOM 1 N N ALA A 1 1.0 2.0 3.0
CIF
	is_deeply($i->{chains}{A}{residues}{1}{atom_order}, [ 'N', "'CA" ],
		'a quote the end of the file leaves open is read as written');
	is($i->{chains}{A}{residues}{1}{atoms}{"'CA"}{x}, 2, 'and its row keeps its columns');
}
{
	# A number with its standard uncertainty after it in parentheses, which is
	# CIF 1.1's numeric syntax.  gemmi 0.7.5's cif::as_number() reads '1.000(2)',
	# '-2.5(13)', '0.50(5)' and '10.0(1)' as 1, -2.5, 0.5 and 10 (checked with
	# gemmi.cif.as_number from its python module).  0.034 required the number to
	# be the whole field -- the PDB rule for a coordinate that overflowed its
	# columns -- and read all four as undef.
	my $i = structure_info_string(<<'CIF', format => 'mmcif', features => 0);
data_X
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
_atom_site.occupancy
_atom_site.B_iso_or_equiv
ATOM 1 N N ALA A 1 1.000(2) -2.5(13) 3.0 0.50(5) 10.0(1)
ATOM 2 C CA ALA A 1 2.0 2.0 3.0 1.0 12.5(
ATOM 3 C C ALA A 1 3.0 2.0 3.0 1.0 12.5()
CIF
	my $n = $i->{chains}{A}{residues}{1}{atoms}{N};
	is_deeply([ @{$n}{qw(x y z occupancy bfactor)} ], [ 1, -2.5, 3, 0.5, 10 ],
		'a standard uncertainty after a number is not part of it');
	is($i->{chains}{A}{residues}{1}{atoms}{CA}{bfactor}, undef,
		'a parenthesis with no uncertainty in it is not one');
	is($i->{chains}{A}{residues}{1}{atoms}{C}{bfactor}, undef, 'nor is an empty pair');
}
{
	# the annotation categories, and the identifiers they are read under.  Only
	# label_* here: auth_* is preferred where a row has both, and a row with
	# neither is a row nothing can be filed under.
	my $i = structure_info_string(<<'CIF', format => 'mmcif');
data_X
_entry.id X
loop_
_struct_conn.id
_struct_conn.conn_type_id
_struct_conn.ptnr1_label_asym_id
_struct_conn.ptnr1_label_seq_id
_struct_conn.ptnr1_label_comp_id
_struct_conn.ptnr1_label_atom_id
_struct_conn.ptnr2_label_asym_id
_struct_conn.ptnr2_label_seq_id
_struct_conn.ptnr2_label_comp_id
_struct_conn.ptnr2_label_atom_id
_struct_conn.pdbx_dist_value
disulf1 disulf A 6 CYS SG A 10 CYS SG 2.03
covale1 covale A 1 ALA C  A 2  GLY N  1.33
hydrog1 hydrog A 1 ALA N  A 2  GLY O  2.90
loop_
_chem_comp.id
_chem_comp.name
_chem_comp.formula
_chem_comp.pdbx_synonyms
HOH water 'H2 O' 'dihydrogen monoxide'
ALA alanine 'C3 H7 N O2' ?
loop_
_pdbx_nonpoly_scheme.mon_id
_pdbx_nonpoly_scheme.pdb_strand_id
_pdbx_nonpoly_scheme.pdb_seq_num
_pdbx_nonpoly_scheme.pdb_ins_code
ZN A 201 .
loop_
_pdbx_struct_mod_residue.auth_comp_id
_pdbx_struct_mod_residue.parent_comp_id
_pdbx_struct_mod_residue.details
MSE MET SELENOMETHIONINE
loop_
_citation.id
_citation.title
_citation.journal_abbrev
_citation.year
_citation.pdbx_database_id_PubMed
ref1 'A cited paper' 'J. Other' 1999 111
ref2 'Another one'   'J. More'  2000 222
loop_
_citation_author.citation_id
_citation_author.name
ref1 'Smith, A.'
ref2 'Jones, B.'
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
ATOM 1 C CA ALA A 1 1.0 2.0 3.0
CIF
	is(scalar @{ $i->{ssbond} }, 1, 'a _struct_conn of type disulf is an SSBOND');
	is($i->{ssbond}[0]{resseq2}, 10, 'read under label_seq_id where there is no auth_seq_id');
	is(scalar @{ $i->{link} }, 1, 'anything else bonded is a LINK');
	is($i->{link}[0]{name1}, 'C', 'with the atom names of both ends');
	is($i->{link}[0]{resname2}, 'GLY', 'and the residues they are in');
	ok(!grep({ ($_->{name1} || '') eq 'N' } @{ $i->{link} }),
		'and a hydrogen bond is not a LINK: the file says it is a hydrogen bond');
	is($i->{het}{HOH}{water}, 1, 'a _chem_comp for water is marked as water');
	is($i->{het}{HOH}{synonym}, 'dihydrogen monoxide', 'with its synonym');
	ok(!exists $i->{het}{ALA},
		'and a standard residue is not a heterogen, though _chem_comp describes it');
	is($i->{het}{ZN}{instances}[0]{resseq}, 201,
		'_pdbx_nonpoly_scheme says where each heterogen sits, as HET does');
	is($i->{het}{ZN}{instances}[0]{icode}, '',
		"and a '.' insertion code is the empty field a PDB record would have had");
	is($i->{modres}{MSE}{standard}, 'MET',
		'_pdbx_struct_mod_residue says what a modified residue was made from');
	is($i->{journal}{titl}, 'A cited paper',
		"an entry whose citations are all references takes the first: there is no 'primary'");
	is_deeply($i->{journal}{auth}, [ 'Smith, A.' ],
		'and only the authors of that citation');
}
{
	# a row with no identifier of either kind.  auth_* is preferred and label_*
	# is the fall-back, and a row carrying neither is a row nothing can be filed
	# under: it reads as undef rather than as an empty string, which is the same
	# answer a PDB record with a blank column gives.
	my $i = structure_info_string(<<'CIF', format => 'mmcif');
data_X
_entry.id X
loop_
_struct_conf.id
_struct_conf.conf_type_id
HELX1 HELX_P
loop_
_struct_conn.id
_struct_conn.conn_type_id
covale1 covale
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
ATOM 1 C CA ALA A 1 1.0 2.0 3.0
CIF
	is($i->{helix}[0]{id}, 'HELX1', 'a helix with no residues named is still a helix record');
	is($i->{helix}[0]{init_chain}, undef, 'and the chain it does not name is undef');
	is($i->{helix}[0]{init_resseq}, undef, 'as is the residue');
	is($i->{link}[0]{chain1}, undef, 'and the same for a bond that names neither partner');
}
{
	# a formal charge that is not the signed integer the format asks for.
	# quirks.cif covers the conversion; what is here is a writer that has put
	# the PDB spelling in the mmCIF field, which is passed through rather than
	# refused, and a charge too big for the two columns a PDB record gives it.
	my $p = Chem::Structure::Parser::_parse_cif_string(<<'CIF', {});
data_x
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
_atom_site.pdbx_formal_charge
HETATM 1 Zn ZN ZN A 1 1.0 2.0 3.0 2-
HETATM 2 Fe FE FE A 2 1.0 2.0 3.0 12
CIF
	is($p->{charge}[0], '2-',
		'a charge already written the way a PDB record writes it is passed through');
	is($p->{charge}[1], '',
		'and one that will not fit the two columns a PDB record has is no charge');
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

#--------------------------------------------------------------------
# a type_symbol that is not an element.
#
# The PDB reader does not believe columns 77-78 unless they spell letters: an
# entry from before the element column existed keeps the entry id in columns
# 73-80 instead, so what sits where the element goes in gemmi's
# tests/pdb1gdr.ent (a 1993 entry, and t/data/pdb1gdr.ent here) is '1G', and
# every atom in it would otherwise read as element '1'.  A file converted from
# one carries the same string in type_symbol, and a writer with no symbol to
# write sometimes writes '' rather than the '.' or '?' CIF has for it.  Both
# are the null field the PDB reader would have guessed past, so the mmCIF
# reader guesses past them too and the two formats agree about what the atom
# is made of.
#--------------------------------------------------------------------
{
	# atom name, type_symbol as the .cif writes it, what columns 77-78 of the
	# equivalent PDB record hold
	my @case = (
		[ 'CA', q{""}, '  ', 'an empty type_symbol'           ],
		[ 'CB', q{.},  '  ', 'a type_symbol that is CIF null' ],
		[ 'CG', q{?},  '  ', 'a type_symbol CIF calls unknown' ],
		[ 'CD', q{1G}, '1G', "a type_symbol that is an entry's id" ],
		[ 'ZN', q{ZN}, 'ZN', 'a type_symbol that is an element' ],
	);
	my $cif = "data_x\nloop_\n" . join('', map { "_atom_site.$_\n" } qw(
		group_PDB id type_symbol auth_atom_id auth_comp_id auth_asym_id
		auth_seq_id Cartn_x Cartn_y Cartn_z));
	my $pdb = '';
	my $n = 0;
	for my $c (@case) {
		$n++;
		$cif .= "ATOM $n $c->[1] $c->[0] ALA A 1 1.000 2.000 3.000\n";
		$pdb .= sprintf "ATOM  %5d %-4s ALA A   1       1.000   2.000   3.000  1.00  0.00          %2s\n",
			$n, " $c->[0]", $c->[2];
	}
	my $ci = structure_info_string($cif, format => 'mmcif');
	my $pi = structure_info_string($pdb);
	for my $c (@case) {
		my $got  = $ci->{chains}{A}{residues}{1}{atoms}{ $c->[0] }{element};
		my $want = $pi->{chains}{A}{residues}{1}{atoms}{ $c->[0] }{element};
		is($got, $want, "$c->[3] reads as the PDB reader reads it ('$want')");
	}
}

# The physical properties are the coordinate half read a different way, so they
# have to come out the same too -- and the whole hash, not the fields someone
# thought to check.  The stacked-ring list carries the depositor's chain ids and
# residue keys, which is what makes it comparable at all: an mmCIF file's
# label_asym_id would have named these chains something else.
for my $stem (qw(mini stack bases rna aform duplex wobble nmr bare)) {
	my $pdb = structure_features(structure_info("$data/$stem.pdb"));
	my $cif = structure_features(structure_info("$data/$stem.cif"));
	is_deeply($cif, $pdb, "$stem: the two formats give the same physical properties");
}

# and what was written into the structures matches down to the atom
for my $stem (qw(mini stack bases rna aform duplex wobble)) {
	my $pdb = structure_info("$data/$stem.pdb");
	my $cif = structure_info("$data/$stem.cif");
	structure_features($_) for $pdb, $cif;
	for my $cid (@{ $pdb->{chain_order} }) {
		is_deeply($cif->{chains}{$cid}, $pdb->{chains}{$cid},
			"$stem: chain $cid is identical with the surfaces filled in");
	}
}

# A formal charge the PDB writes sign first.  The format's spelling is the
# magnitude and then the sign, 1-, and mmCIF's is a signed integer, -1, which
# the mmCIF reader turns into 1-.  4byf and 4ui0 in PDBbind v2020 write their
# carboxylate and phosphate oxygens O-1 instead -- the line below is 4byf's
# atom 13730 exactly as deposited -- and the PDB reader handed that back as
# "-1", so the same atom had one charge from the .pdb and another from the
# .cif.  Both now say 1-.
{
	my $pdb = Chem::Structure::Parser::_parse_string(<<'PDB', {});
HETATM13730  O2B AOV A1001      -9.965   3.015 133.220  1.00 72.15           O-1
HETATM13731  O2A AOV A1001      -8.772  -0.645 136.087  1.00 12.87           O1-
HETATM13732  O3A AOV A1001      -8.772  -0.645 137.087  1.00 12.87           O+2
PDB
	my $cif = Chem::Structure::Parser::_parse_cif_string(<<'CIF', {});
data_4BYF
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
_atom_site.pdbx_formal_charge
HETATM 13730 O O2B AOV A 1001 -9.965 3.015 133.220 -1
HETATM 13731 O O2A AOV A 1001 -8.772 -0.645 136.087 -1
HETATM 13732 O O3A AOV A 1001 -8.772 -0.645 137.087 2
CIF
	is_deeply($pdb->{charge}, [ '1-', '1-', '2+' ],
		'a sign-first PDB charge is spelled magnitude first');
	is_deeply($cif->{charge}, $pdb->{charge}, 'which is what the mmCIF reader says');
}

# A formal charge too large to be one.  pdbx_formal_charge is free-form and
# str2iv() takes anything an IV holds, IV_MIN included, and negating IV_MIN
# overflows: the charge came back as "0-".  On a 32-bit perl the same two
# numbers are too wide for str2iv() and were passed through as text, cut to
# "-9" and "92".  Anything past one digit is not a charge the PDB spelling can
# hold, and comes back empty at every IV width, as 10 always did.
{
	my $cif = Chem::Structure::Parser::_parse_cif_string(<<'CIF', {});
data_X
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
_atom_site.pdbx_formal_charge
HETATM 1 ZN ZN ZN A 1 1.0 2.0 3.0 -9223372036854775808
HETATM 2 ZN ZN ZN A 2 1.0 2.0 3.0 9223372036854775807
HETATM 3 ZN ZN ZN A 3 1.0 2.0 3.0 -10
HETATM 4 ZN ZN ZN A 4 1.0 2.0 3.0 -9
CIF
	is_deeply($cif->{charge}, [ '', '', '', '9-' ],
		'a charge past one digit is no charge, at either end of an IV');
}

# A text field in a file with DOS line ends.  The lexer finds the lines by
# their LF, so every CR was left in the value -- one before each line break and
# one at the end -- and the same title read differently from the same file
# saved on two systems.  Bare values never had the problem, because a CR is
# whitespace between them.
{
	my $text = "data_X\n_struct.title\n;A title\nthat runs over\nthree lines\n;\n"
	         . "_struct_keywords.text 'one line'\n";
	(my $dos = $text) =~ s/\n/\r\n/g;
	my $u = Chem::Structure::Parser::_parse_cif_string($text, {});
	my $d = Chem::Structure::Parser::_parse_cif_string($dos, {});
	is($d->{cif}{'_struct.title'}, "A title\nthat runs over\nthree lines",
		'a text field written with CRLF line ends reads with LF ones');
	is_deeply($d->{cif}, $u->{cif}, 'and every tag reads as it does from the LF file');
}

#--------------------------------------------------------------------
# files gemmi reads differently, or refuses
#
# Each text below was read with gemmi 0.7.5 (read_structure) on 2026-10-09,
# and its answer is the one written against it.  The _atom_site columns are
# the ones gemmi needs before it will read a model at all.
#--------------------------------------------------------------------
my $SITE_HEAD = join '', map { "_atom_site.$_\n" } qw(group_PDB id type_symbol
	label_atom_id label_alt_id label_comp_id label_asym_id label_entity_id label_seq_id
	pdbx_PDB_ins_code Cartn_x Cartn_y Cartn_z occupancy B_iso_or_equiv auth_seq_id
	auth_asym_id pdbx_PDB_model_num);
{
	# Rows not in model order.  Nothing in the format asks for them to be, and
	# a reader that counted a model at each change of model number counted four
	# here, chain A of models 1 and 2 and then chain B of the same two.  gemmi
	# finds two models of two atoms each.
	my $i = structure_info_string("data_X\nloop_\n$SITE_HEAD" . <<'CIF', model => 'all', features => 0);
ATOM 1 C CA . GLY A 1 1 ? 1.0 0.0 0.0 1.0 10.0 1 A 1
ATOM 2 C CA . GLY A 1 1 ? 1.5 0.0 0.0 1.0 10.0 1 A 2
ATOM 3 C CA . ALA B 1 1 ? 5.0 0.0 0.0 1.0 10.0 1 B 1
ATOM 4 C CA . ALA B 1 1 ? 5.5 0.0 0.0 1.0 10.0 1 B 2
CIF
	is($i->{n_models}, 2, 'models are counted by number, not by each change of number');
	is_deeply([ sort keys %{ $i->{models} } ], [ 1, 2 ], 'and they are models 1 and 2');
	is_deeply([ map { $i->{models}{$_}{chains}{B}{n_atoms} } 1, 2 ], [ 1, 1 ],
		'each with its own atom of chain B');
}
{
	# Two data blocks.  gemmi refuses the file -- '2+ blocks are ok if only the
	# first one has coordinates' -- and reads only the first block of one whose
	# later blocks have none.  The blocks were read as one: block two's atoms
	# went under block one's residue numbers as conformers of them, and its
	# header over block one's.  The first block is the structure.
	my $block = sub {
		my ($name, $a, $x) = @_;
		return "data_$name\n_cell.length_a $a\n_cell.length_b $a\n_cell.length_c $a\n"
		     . "loop_\n$SITE_HEAD"
		     . "ATOM 1 N N . GLY A 1 1 ? $x 0.0 0.0 1.0 10.0 1 A 1\n"
		     . "ATOM 2 C CA . GLY A 1 1 ? 2.0 0.0 0.0 1.0 10.0 1 A 1\n";
	};
	my $i = structure_info_string($block->('ONE', 10, '1.0') . $block->('TWO', 99, '9.0'),
		features => 0);
	my $r = $i->{chains}{A}{residues}{1};
	is($r->{n_atoms}, 2, 'a second data block is not read into the first');
	ok(!exists $r->{atoms}{N}{altlocs}, 'its atoms are not conformers of the first block\'s');
	is($r->{atoms}{N}{x}, 1, 'the coordinates are the first block\'s');
	is($i->{cryst1}{a}, 10, 'and so is the header');
}
{
	# A last row with fewer values than the loop has tags: the file was cut
	# short.  gemmi refuses it, 'Wrong number of values in loop _atom_site.*'.
	# The row was read as an atom with no y or z, filed under its label_* chain
	# and number for want of the auth_* ones further along; it is left out, and
	# every whole row before it is read.
	my $i = structure_info_string("data_X\nloop_\n$SITE_HEAD" . <<'CIF', features => 0);
ATOM 1 C CA . GLY A 1 1 ? 1.0 0.0 0.0 1.0 10.0 1 A 1
ATOM 2 C CA . GLY A 1 2 ? 2.0
CIF
	is($i->{stats}{n_atoms}, 1, 'a row the file cut short is not an atom');
	is_deeply($i->{chain_order}, [ 'A' ], 'and makes no residue');
	is($i->{stats}{total_atoms}, 1, 'and is not counted as a record');
}
{
	# _atom_site_anisotrop of one row, written as plain tags rather than a
	# loop_: one record, however many tags it takes, as the loop counts it.  It
	# was counted once per tag, eight here, and kept nowhere with anisou => 1.
	my $tags = join '', map { "_atom_site_anisotrop.$_ 1\n" }
		qw(id type_symbol U[1][1] U[2][2] U[3][3] U[1][2] U[1][3] U[2][3]);
	my $text = "data_X\nloop_\n$SITE_HEAD"
	         . "ATOM 1 C CA . GLY A 1 1 ? 1.0 0.0 0.0 1.0 10.0 1 A 1\n" . $tags;
	my $i = structure_info_string($text, features => 0);
	is($i->{stats}{n_anisou}, 1, 'an anisotropic record of eight plain tags is one record');
	my $k = structure_info_string($text, features => 0, anisou => 1);
	is($k->{records}{_atom_site_anisotrop}, 1, 'and is kept, as the loop form is, with anisou => 1');
	is($k->{stats}{n_anisou}, 1, 'and is still one record');
}
{
	# An mmCIF file without _atom_site.type_symbol has only the name to go on,
	# and the name has no columns to say where it starts.  It was put where a
	# one-letter element goes, so a zinc read as Z, a magnesium as M and a
	# sodium as N.  An atom named for its own residue in two letters that spell
	# an element is the ion of that element; a carbon alpha is named CA in a
	# residue that is not called CA.  gemmi reads no model from a file without
	# type_symbol, so there is no answer of its to set beside these.
	my $head = $SITE_HEAD;
	$head =~ s/_atom_site\.type_symbol\n//;
	my $i = structure_info_string("data_X\nloop_\n$head" . <<'CIF', features => 0);
HETATM 1 ZN . ZN Z 1 . ? 1.0 0.0 0.0 1.0 10.0 1 Z 1
HETATM 2 MG . MG Z 2 . ? 2.0 0.0 0.0 1.0 10.0 2 Z 1
HETATM 3 NA . NA Z 3 . ? 3.0 0.0 0.0 1.0 10.0 3 Z 1
HETATM 4 CL . CL Z 4 . ? 4.0 0.0 0.0 1.0 10.0 4 Z 1
ATOM 5 CA . ALA Z 5 . ? 5.0 0.0 0.0 1.0 10.0 5 Z 1
CIF
	my $c = $i->{chains}{Z};
	is_deeply([ map { my $r = $c->{residues}{$_}; $r->{atoms}{ $r->{atom_order}[0] }{element} }
	            @{ $c->{residue_order} } ],
	          [ qw(Zn Mg Na Cl C) ],
	          'an ion named for its residue is that element, and a CA in ALA is a carbon');
}
{
	# A line of quotes that never close.  Each is the start of a bare word
	# (see cif_next()), and each sent the lexer to the end of its line to look
	# for the closing quote again: 40,000 of them took a second to read where
	# the same words without the quotes took a hundredth.  What they read as has
	# not changed.
	my $n = 20000;
	my $p = Chem::Structure::Parser::_parse_cif_string(
		"data_x\nloop_\n_a.x\n" . join(' ', map { "'a$_" } 1 .. $n) . "\n", {});
	my $rows = $p->{cif_loops}{_a};
	is(scalar @$rows, $n, 'a line of unclosed quotes is a line of words');
	is($rows->[0]{x}, "'a1", 'each starting with its quote');
	is($rows->[-1]{x}, "'a$n", 'to the last one');
}

# the same residue collision t/foreign.t reads from a PDB file, written as
# mmCIF: one reader's answer is the other's
{
	my $text = "data_X\nloop_\n$SITE_HEAD" . <<'CIF';
ATOM 1 N N . MET A 1 1 ? 1.0 2.0 3.0 1.0 10.0 1 A 1
ATOM 2 C CA . MET A 1 1 ? 2.0 2.0 3.0 1.0 10.0 1 A 1
ATOM 3 O O . MET A 1 1 ? 9.0 2.0 3.0 1.0 10.0 1 A 1
HETATM 4 O O . HOH A 2 . ? 20.0 20.0 20.0 1.0 10.0 1 A 1
HETATM 5 C C1 . LIG A 3 . ? 30.0 30.0 30.0 1.0 10.0 1 A 1
HETATM 6 O O1 . LIG A 3 . ? 31.0 30.0 30.0 1.0 10.0 1 A 1
CIF
	my $pdb = <<'PDB';
ATOM      1  N   MET A   1       1.000   2.000   3.000  1.00 10.00           N
ATOM      2  CA  MET A   1       2.000   2.000   3.000  1.00 10.00           C
ATOM      3  O   MET A   1       9.000   2.000   3.000  1.00 10.00           O
TER
HETATM    4  O   HOH A   1      20.000  20.000  20.000  1.00 10.00           O
HETATM    5  C1  LIG A   1      30.000  30.000  30.000  1.00 10.00           C
HETATM    6  O1  LIG A   1      31.000  30.000  30.000  1.00 10.00           O
PDB
	for my $atoms (1, 0) {
		my $c = structure_info_string($text, atoms => $atoms, features => 0);
		my $p = structure_info_string($pdb,  atoms => $atoms, features => 0);
		is_deeply($c->{chains}{A}{residue_order}, [ '1', '1(HOH)', '1(LIG)' ],
			"atoms => $atoms: a residue given a taken number is its own, in mmCIF too");
		is_deeply(coords($c), coords($p), "atoms => $atoms: and the two formats agree about it");
	}
}

# SITE, SEQADV, HETNAM and FORMUL, which the mmCIF reader reads out of
# _struct_site and _struct_site_gen, _struct_ref_seq_dif and _chem_comp.  site,
# hetnam and formul were keys a structure always had and nothing filled; seqadv
# was not a key of an mmCIF structure at all.  The PDB lines are mini.pdb's,
# and the SITE ones are in the wwPDB v3.3 columns, written here by sprintf so
# that no column is off by one.
{
	my $site = sub { sprintf "SITE   %3d %3s %2d %s\n", $_[0], $_[1], $_[2],
		join ' ', map { sprintf '%3s %1s%4d%1s', @$_ } @_[3 .. $#_] };
	my $pdb = "HEADER    TEST                                    01-JAN-20   9XYZ\n"
	        . "SEQADV 9XYZ MSE A    7  UNP  P12345    MET     7 MODIFIED RESIDUE\n"
	        . "HETNAM      ZN ZINC ION\n"
	        . "FORMUL   4   ZN    ZN 2+\n"
	        . $site->(1, 'AC1', 5, [ 'HIS', 'A', 94, '' ], [ 'HIS', 'A', 96, '' ],
	                               [ 'GLU', 'A', 106, 'A' ], [ 'HOH', 'A', 301, '' ])
	        . $site->(2, 'AC1', 5, [ 'ZN', 'A', 401, '' ])
	        . "ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C\n";
	my $cif = <<'CIF';
data_9XYZ
_entry.id 9XYZ
_struct_ref_seq_dif.mon_id                      MSE
_struct_ref_seq_dif.pdbx_pdb_strand_id          A
_struct_ref_seq_dif.pdbx_auth_seq_num           7
_struct_ref_seq_dif.pdbx_seq_db_name            UNP
_struct_ref_seq_dif.pdbx_seq_db_accession_code  P12345
_struct_ref_seq_dif.db_mon_id                   MET
_struct_ref_seq_dif.pdbx_seq_db_seq_num         7
_struct_ref_seq_dif.details                     'MODIFIED RESIDUE'
_chem_comp.id      ZN
_chem_comp.name    'ZINC ION'
_chem_comp.formula 'ZN 2+'
_struct_site.id                AC1
_struct_site.pdbx_num_residues 5
loop_
_struct_site_gen.id
_struct_site_gen.site_id
_struct_site_gen.auth_comp_id
_struct_site_gen.auth_asym_id
_struct_site_gen.auth_seq_id
_struct_site_gen.pdbx_auth_ins_code
1 AC1 HIS A 94  ?
2 AC1 HIS A 96  ?
3 AC1 GLU A 106 A
4 AC1 HOH A 301 ?
5 AC1 ZN  A 401 ?
loop_
_atom_site.group_PDB
_atom_site.id
_atom_site.type_symbol
_atom_site.auth_atom_id
_atom_site.auth_comp_id
_atom_site.auth_asym_id
_atom_site.auth_seq_id
_atom_site.Cartn_x
_atom_site.Cartn_y
_atom_site.Cartn_z
ATOM 1 C CA ALA A 1 10.000 10.000 10.000
CIF
	my $p = structure_info_string($pdb, features => 0);
	my $c = structure_info_string($cif, features => 0);
	is_deeply($p->{site}, [ { id => 'AC1', n_residues => 5, residues => [
		{ resname => 'HIS', chain => 'A', resseq => 94,  icode => '' },
		{ resname => 'HIS', chain => 'A', resseq => 96,  icode => '' },
		{ resname => 'GLU', chain => 'A', resseq => 106, icode => 'A' },
		{ resname => 'HOH', chain => 'A', resseq => 301, icode => '' },
		{ resname => 'ZN',  chain => 'A', resseq => 401, icode => '' } ] } ],
		'SITE: one site, its residues four to a line and the fifth on the next');
	is_deeply($c->{site}, $p->{site}, 'and the mmCIF categories say the same');
	is_deeply($c->{seqadv}, $p->{seqadv}, 'SEQADV and _struct_ref_seq_dif agree');
	is($c->{seqadv}[0]{db_res}, 'MET', 'about what the database has');
	is_deeply($p->{hetnam}, { ZN => 'ZINC ION' }, 'HETNAM fills hetnam');
	is_deeply($p->{formul}, { ZN => 'ZN 2+' }, 'and FORMUL fills formul');
	is_deeply([ $c->{hetnam}, $c->{formul} ], [ $p->{hetnam}, $p->{formul} ],
		'and _chem_comp fills both the same way');
	my $bare = structure_info_string("data_X\nloop_\n$SITE_HEAD"
		. "ATOM 1 C CA . GLY A 1 1 ? 1.0 0.0 0.0 1.0 10.0 1 A 1\n", features => 0);
	is_deeply([ @{$bare}{qw(seqadv site)} ], [ [], [] ],
		'a file with none of them has them as empty lists, as every list is');
}

# The text of a structure handed over as a string is its characters, not the
# way perl happens to be storing them: a string perl has upgraded to UTF-8
# reads as the same string not upgraded does.  An author's name with an
# accented letter came back a byte longer from the upgraded one, the letter as
# the two bytes of its UTF-8.
{
	my $text = "data_X\n_audit_author.name 'M\x{fc}ller, A.'\nloop_\n$SITE_HEAD"
	         . "ATOM 1 C CA . GLY A 1 1 ? 1.0 0.0 0.0 1.0 10.0 1 A 1\n";
	my $up = $text;
	utf8::upgrade($up);
	my $a = Chem::Structure::Parser::_parse_cif_string($text, {});
	my $b = Chem::Structure::Parser::_parse_cif_string($up, {});
	is($b->{cif}{'_audit_author.name'}, "M\x{fc}ller, A.", 'an upgraded string reads as its characters');
	is_deeply($b->{cif}, $a->{cif}, 'and as the same string not upgraded');
}

done_testing();
