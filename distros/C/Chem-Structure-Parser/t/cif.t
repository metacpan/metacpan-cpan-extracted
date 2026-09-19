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

done_testing();
