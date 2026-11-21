#!/usr/bin/env perl
# convert() -- a structure written out in the other format, and in its own.
#
# The claim is the one t/cif.t makes of the readers, run the other way: a
# structure written out by convert() reads back as the structure it was read
# as, is_deeply over the whole coordinate half and not merely in the fields
# that were thought of.  So the first thing below is every structure in t/data
# through every path -- PDB to mmCIF, mmCIF to PDB, each to itself, and there
# and back -- with the same coords() t/cif.t compares the two readers with.
#
# What another reader makes of the converted files is t/oracle.t's question,
# which reads them against gemmi.  What is here besides the round trips is the
# writing itself, held to the documents that define it:
#
#   * the column of every field of ATOM, HETATM, ANISOU, TER, MODEL, SEQRES,
#     HELIX, SHEET, SSBOND, LINK and CRYST1, from the wwPDB's "Atomic
#     Coordinate Entry Format Description" v3.3 (the column numbers below are
#     its one-based ones);
#   * the column an atom name starts in, which is Biopython 1.85's rule
#     (Bio/PDB/PDBIO.py, _get_atom_line(): a name shorter than four
#     characters that starts with a letter and whose element is one letter
#     starts in column 14) -- the rule the PDB reader's element guess reads;
#   * hybrid-36 past the decimal columns, from Grosse-Kunstleve's hybrid_36
#     reference (https://cci.lbl.gov/hybrid_36/): 'A0000' is serial 100000
#     and 'A000' residue 10000, which is how t/data/numbering.pdb writes them;
#   * mmCIF quoting, from CIF 1.1's grammar: a value with a blank in it, or
#     one that starts with _ # $ ' " [ ] ;, is quoted, and a quote is closed
#     only by one followed by a blank.
#
# The ANISOU records come out of strings built here, by column, because no
# fixture in t/data has any: the six factors are made up, and what is tested
# is that they go across as the same numbers, which does not care what they
# are.
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
my $tmp  = tempdir(CLEANUP => 1);

# coords() -- the half of a parsed structure the coordinates decide, as t/cif.t
# takes it: every chain, residue and atom, every model, and the counts over
# them, less the line count and what _chain_stats() folds in from the header
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

# the text a conversion writes, and what it returned
sub text_of {
	my ($in, %opt) = @_;
	my $text;
	my $r = convert($in, \$text, %opt);
	return wantarray ? ($text, $r) : $text;
}

# the record lines of a PDB text that start with $rec
sub records {
	my ($text, $rec) = @_;
	return grep { substr($_, 0, length $rec) eq $rec } split /\n/, $text;
}

opendir(my $dh, $data) or die "Can't opendir '$data': '$!'";
my @fixtures = sort grep { /\.(?:pdb|ent|cif)\z/ } readdir $dh;
closedir $dh or die "Can't closedir '$data': '$!'";

#--------------------------------------------------------------------
# every structure, every way
#--------------------------------------------------------------------
for my $f (@fixtures) {
	my $orig = structure_info("$data/$f", model => 'all', features => 0);
	for my $path ([ 'pdb' ], [ 'mmcif' ], [ 'pdb', 'mmcif' ], [ 'mmcif', 'pdb' ]) {
		my $in = "$data/$f";
		my $text;
		for my $to (@$path) {
			$text = text_of($in, to => $to);
			my $copy = $text;
			$in = \$copy;
		}
		my $back = structure_info_string($text, model => 'all', features => 0, format => $path->[-1]);
		is($back->{format}, $path->[-1], "$f, to @$path: it is read as what it was written as");
		is_deeply(coords($back), coords($orig),
			"$f, to @$path: every chain, residue, atom, model and count reads back the same");
	}
}

# and through the file forms of both ends, which are where the format is
# worked out from the names
for my $pair ([ 'mini.pdb', 'mini.cif' ], [ 'nmr.cif', 'nmr.pdb' ], [ 'numbering.pdb', 'numbering.cif' ]) {
	my ($from, $to) = @$pair;
	my $out = "$tmp/converted.$to";
	my $r = convert("$data/$from", $out);
	is($r->{to}, (structure_info($out, features => 0)->{format}),
		"$from to a file named $to: the format is the name's");
	is_deeply(coords(structure_info($out, model => 'all', features => 0)),
	          coords(structure_info("$data/$from", model => 'all', features => 0)),
		"$from to a file named $to: and it reads back as $from does");
}

#--------------------------------------------------------------------
# the header
#--------------------------------------------------------------------
# The facts convert() carries, as the readers file them.  A fact the file does
# not have is undef in one reader's spelling and '' in the other's, which are
# the same absence, so both are compared as ''.  The date is compared in the
# one spelling, mmCIF's, because each reader hands it back in its own format's.
sub header {
	my ($i) = @_;
	my $s = sub { my $v = shift; defined $v ? "$v" : '' };
	my %h = (
		title      => $s->($i->{title}),
		keywords   => $i->{keywords},
		experiment => $i->{experiment},
		resolution => $s->($i->{resolution}),
		class      => $s->($i->{header}{classification}),
		id         => $s->($i->{header}{id_code}),
		date       => $s->(Chem::Structure::Parser::_cif_date($i->{header}{deposit_date})),
		cryst1     => { map { $_ => $s->($i->{cryst1}{$_}) } qw(a b c alpha beta gamma sgroup z) },
		seqres     => { map { $_ => join(' ', @{ $i->{seqres}{$_}{residues} }) } keys %{ $i->{seqres} } },
		molecule   => { map { $_ => $s->($i->{entity_of_chain}{$_}{molecule}) }
		                grep { defined $i->{entity_of_chain}{$_}{molecule} } keys %{ $i->{entity_of_chain} } },
	);
	for my $k (qw(helix sheet ssbond link)) {
		$h{$k} = [ map { my $r = $_; +{ map { $_ => $s->($r->{$_}) } keys %$r } } @{ $i->{$k} } ];
	}
	return \%h;
}

for my $f (qw(mini.pdb mini.cif nmr.pdb nmr.cif ensemble.pdb pdb1gdr.ent)) {
	my $orig = header(structure_info("$data/$f", features => 0));
	for my $to (qw(pdb mmcif)) {
		my ($text, $r) = text_of("$data/$f", to => $to);
		my $back = header(structure_info_string($text, features => 0, format => $to));
		# pdb1gdr's one chain has no id, which SEQRES can write and mmCIF's
		# pdbx_strand_id cannot name; the notes say so, and that is tested below
		delete @{$_}{qw(seqres molecule)} for $f eq 'pdb1gdr.ent' && $to eq 'mmcif' ? ($orig, $back) : ();
		is_deeply($back, $orig, "$f to $to: the header facts convert() carries read back the same");
	}
}
{
	my $m = structure_info_string(scalar text_of("$data/mini.pdb", to => 'mmcif'), features => 0);
	is($m->{chains}{A}{molecule}, 'TEST PROTEIN', 'COMPND becomes the entity a chain is');
	is($m->{chains}{A}{sequence}, structure_info("$data/mini.pdb", features => 0)->{chains}{A}{sequence},
		'and SEQRES its sequence');
	is($m->{chains}{A}{n_missing}, 2, 'so the residues SEQRES has and the coordinates do not are still missing');
	is($m->{cryst1}{sgroup}, 'P 1 21 1', 'the space group, which has blanks in it to quote');
	my ($text, $r) = text_of("$data/pdb1gdr.ent", to => 'mmcif');
	like($r->{notes}[0], qr/\ASEQRES: the chain with no id is left out of entity 1/,
		'a chain mmCIF has no name for is left out of the entities, and the notes say so');
	my $p = text_of("$data/pdb1gdr.ent", to => 'pdb');
	is(scalar(() = records($p, 'SEQRES')), 11, 'where SEQRES writes it with a blank, as the file did');
	is(substr((records($p, 'SEQRES'))[0], 11, 1), ' ', 'in column 12');
}
{
	# the entry id the file name gives, for a structure with no HEADER, is the
	# data block's name and nothing more: _entry.id is a fact of the header
	my $c = text_of("$data/bare.pdb", to => 'mmcif');
	like($c, qr/\Adata_BARE\n/, 'a file with no HEADER names its data block after the file');
	unlike($c, qr/_entry\.id/, 'and is not given an _entry.id the file never had');
	like(text_of(\"ATOM      1  CA  GLY A   1       1.000   2.000   3.000  1.00 10.00           C\n",
	             to => 'mmcif'),
	     qr/\Adata_converted\n/, 'and a string, with no file name either, gets a name of its own');
	is(text_of("$data/mini.pdb", to => 'mmcif', header => 0) =~ /\A(data_\w+)\n#\nloop_\n_atom_site/ ? $1 : '',
	   'data_MINI', 'header => 0 writes a data block named for the file, and the atoms, and nothing between');
	my $p = text_of("$data/mini.cif", to => 'pdb', header => 0);
	like($p, qr/\AATOM  /, 'and a PDB file that starts with its first atom');
	like($p, qr/^END {77}\n\z/m, 'and ends with END');
}
{
	# the date, which each format writes its own way
	is(Chem::Structure::Parser::_cif_date('01-JAN-20'), '2020-01-01', 'a HEADER date in mmCIF');
	is(Chem::Structure::Parser::_cif_date('31-AUG-93'), '1993-08-31', 'from the century before');
	is(Chem::Structure::Parser::_pdb_date('1993-08-31'), '31-AUG-93', 'and back');
	is(Chem::Structure::Parser::_pdb_date('2020-13-01'), '', 'a month that is not one is no date');
	is(Chem::Structure::Parser::_cif_date('.'), undef, 'nor is a full stop');
	my ($text, $r) = text_of("$data/quirks.cif", to => 'pdb');
	is_deeply($r->{notes}, [ "HEADER: the deposition date '.' is not a date, and is left out" ],
		"quirks.cif's quoted '.' for a date is left out, and the notes say so");
}
{
	# _wrap(), against _joined(), which is what reads it back: a line that ends
	# in a hyphen is joined to the next with nothing between, and any other
	# with a blank
	my $atom = sprintf "%-80s\n", 'ATOM      1  CA  GLY A   1       1.000   2.000   3.000  1.00 10.00           C';
	for my $text (join(' ', map { "WORD$_" } 1 .. 40), 'A ' . ('ALPHA-' x 30) . 'HELIX',
	              'HYPHEN- THEN A BLANK ' x 8) {
		my @notes;
		my $hdr = Chem::Structure::Parser::_pdb_header({ title => $text }, [], \@notes);
		my $back = structure_info_string($hdr . $atom, features => 0);
		(my $want = $text) =~ s/\s+\z//;
		is($back->{title}, $want, 'a title over several lines reads back as itself: '
		                        . substr($text, 0, 24) . '...');
		ok(scalar(() = $hdr =~ /^TITLE/mg) > 1, 'and it is over several lines');
		ok(!grep({ length($_) != 80 } split /\n/, $hdr), 'each of them 80 columns');
		is_deeply(\@notes, [], 'with nothing to say about it');
	}
	my @notes;
	my $hdr = Chem::Structure::Parser::_pdb_header({ title => 'X' x 150 }, [], \@notes);
	like($notes[0], qr/^TITLE: a word with no blank or hyphen to break at was broken/,
		'a word too long for a line, with no hyphen in it, is broken and the notes say so');
}

#--------------------------------------------------------------------
# the PDB record, column by column
#--------------------------------------------------------------------
{
	my $p = text_of("$data/mini.cif", to => 'pdb');
	my @lines = split /\n/, $p;
	ok(!grep({ length($_) != 80 } @lines), 'every record is padded to 80 columns');
	my ($ca) = grep { /^ATOM / && substr($_, 12, 4) eq ' CA ' } @lines;
	ok($ca, "a carbon alpha is ' CA ', from column 14, as a one-letter element's name is");
	is(substr($ca, 0, 6), 'ATOM  ', 'columns 1-6: the record name');
	is(substr($ca, 6, 5), '    2', 'columns 7-11: the serial, right-justified');
	is(substr($ca, 17, 3), 'MET', 'columns 18-20: the residue name');
	is(substr($ca, 21, 1), 'A', 'column 22: the chain');
	is(substr($ca, 22, 4), '   1', 'columns 23-26: the residue number');
	is(substr($ca, 30, 24), '  11.500  11.000  10.500', 'columns 31-54: x, y and z as written');
	is(substr($ca, 54, 12), '  1.00 16.00', 'columns 55-66: occupancy and B');
	is(substr($ca, 76, 2), ' C', 'columns 77-78: the element, right-justified');

	my ($zn) = grep { /^HETATM/ && substr($_, 17, 3) eq ' ZN' } @lines;
	is(substr($zn, 12, 4), 'ZN  ', "a zinc is 'ZN  ', from column 13, as a two-letter element's is");
	is(substr($zn, 76, 4), 'ZN  ', 'with its element in 77-78');
	my ($charged) = grep { substr($_, 17, 3) eq ' ZN' } records(scalar text_of("$data/quirks.cif", to => 'pdb'), 'HETATM');
	is(substr($charged, 76, 4), 'ZN2+', 'and its charge, where it has one, in 79-80, magnitude then sign');
	my ($cb) = grep { /^ATOM / && substr($_, 16, 4) eq 'AALA' } @lines;
	ok($cb, 'the altloc is column 17');
	my ($ins) = grep { substr($_, 22, 5) eq '   8A' } @lines;
	ok($ins, 'and the insertion code column 27');
	my ($dna) = grep { /^ATOM / && substr($_, 17, 3) eq ' DA' } @lines;
	ok($dna, 'a two-letter residue name is right-justified, as the archive writes DA');
	my ($c1) = grep { /^ATOM / && substr($_, 12, 4) eq " C1'" } @lines;
	ok($c1, "C1' is a carbon's name and starts in column 14");

	# from mmCIF, where a name has no columns, the column is the rule's
	my $cif = "data_X\nloop_\n" . join('', map { "_atom_site.$_\n" } qw(group_PDB id
		type_symbol label_atom_id label_comp_id label_asym_id label_seq_id Cartn_x
		Cartn_y Cartn_z auth_seq_id)) . <<'CIF';
ATOM 1 H 1HB ALA A 1 1.0 1.0 1.0 1
ATOM 2 H HG11 VAL A 2 1.0 1.0 1.0 2
HETATM 3 CA CA CA C 1 1.0 1.0 1.0 3
ATOM 4 C CA ALA A 1 1.0 1.0 1.0 1
CIF
	my @n = map { substr($_, 12, 4) } records(scalar text_of(\$cif, to => 'pdb'), 'ATOM'),
	                                  records(scalar text_of(\$cif, to => 'pdb'), 'HETATM');
	is_deeply([ sort @n ], [ sort(' CA ', '1HB ', 'HG11', 'CA  ') ],
		'a name that starts with a digit, a four-letter name and a calcium start in column 13; a carbon alpha in 14');

	# from PDB, the name goes back where the file had it
	my $odd = sprintf "%-80s\n", 'ATOM      1 CA   GLY A   1       1.000   2.000   3.000  1.00 10.00           C';
	is(substr((records(scalar text_of(\$odd, to => 'pdb'), 'ATOM'))[0], 12, 4), 'CA  ',
		'a name a PDB file put in column 13 stays there');
}
{
	# TER after the last atom of a polymer, and not inside one
	my $p = text_of("$data/mini.pdb", to => 'pdb');
	my @l = split /\n/, $p;
	my @at = grep { $l[$_] =~ /^TER/ } 0 .. $#l;
	is(scalar @at, 2, 'one TER after each of the two polymer chains');
	is(substr($l[ $at[0] - 1 ], 17, 9), 'CYS A  10', 'the first after the last residue of the protein');
	is(substr($l[ $at[0] + 1 ], 0, 20), 'HETATM   49  C1  NAG', 'and before its ligands, which are not polymer');
	is(substr($l[ $at[0] ], 6, 5), '   48', 'with the serial after its atom, as the archive numbers it');
	is(substr($l[ $at[0] ], 17, 10), 'CYS A  10 ', 'and its residue in the atom columns');
	ok(!grep({ $l[$_] =~ /^TER/ && $l[ $_ + 1 ] =~ /MSE/ } 0 .. $#l - 1),
		'a selenomethionine HETATM inside the chain is inside it');
	like($l[ $at[1] - 1 ], qr/ DT B   4/, 'and the second after the DNA');
	is(scalar(() = records(scalar text_of("$data/numbering.pdb", to => 'pdb'), 'TER')), 0,
		'a structure of waters has none');
}
{
	# MODEL and ENDMDL: around every model of an ensemble, around the one model
	# of a file whose one model is not model 1, and nowhere else
	my $nmr = text_of("$data/nmr.cif", to => 'pdb');
	is_deeply([ map { substr($_, 10, 4) } records($nmr, 'MODEL') ], [ '   1', '   2', '   3' ],
		'every model of an ensemble, its number in columns 11-14');
	is(scalar(() = records($nmr, 'ENDMDL')), 3, 'and an ENDMDL after each');
	is(scalar(() = records(scalar text_of("$data/mini.cif", to => 'pdb'), 'MODEL')), 0,
		'a structure of one model 1 has none');
	my $two = text_of("$data/nmr.cif", to => 'pdb', model => 2);
	is_deeply([ map { substr($_, 10, 4) } records($two, 'MODEL') ], [ '   2' ],
		'one model that is not model 1 keeps its number');
	is(structure_info_string($two, features => 0)->{model}, 2, 'which reads back as the model it was');

	# rows of an mmCIF file need not be in model order, and records of a PDB
	# file have to be; the same four atoms as t/cif.t's
	my $cif = "data_X\nloop_\n" . join('', map { "_atom_site.$_\n" } qw(group_PDB id
		type_symbol label_atom_id label_alt_id label_comp_id label_asym_id
		label_entity_id label_seq_id pdbx_PDB_ins_code Cartn_x Cartn_y Cartn_z occupancy
		B_iso_or_equiv auth_seq_id auth_asym_id pdbx_PDB_model_num)) . <<'CIF';
ATOM 1 C CA . GLY A 1 1 ? 1.0 0.0 0.0 1.0 10.0 1 A 1
ATOM 2 C CA . GLY A 1 1 ? 1.5 0.0 0.0 1.0 10.0 1 A 2
ATOM 3 C CA . ALA B 1 1 ? 5.0 0.0 0.0 1.0 10.0 1 B 1
ATOM 4 C CA . ALA B 1 1 ? 5.5 0.0 0.0 1.0 10.0 1 B 2
CIF
	my ($pdb, $r) = text_of(\$cif, to => 'pdb');
	is_deeply($r->{models}, [ 1, 2 ], 'models written in the order the file first gives them');
	my @serials = map { /^ATOM/ ? substr($_, 6, 5) + 0 : /^MODEL/ ? 'M' : () } split /\n/, $pdb;
	is_deeply(\@serials, [ 'M', 1, 3, 'M', 2, 4 ], 'each model\'s atoms written inside it');
	is_deeply(coords(structure_info_string($pdb, model => 'all', features => 0)),
	          coords(structure_info_string($cif, model => 'all', features => 0)),
		'and the structure is the same one');
}
{
	# hybrid-36, past the decimal columns, and decimal up to them
	my $p = text_of("$data/numbering.cif", to => 'pdb');
	my @l = records($p, 'HETATM');
	is_deeply([ map { substr($_, 6, 5) } @l ], [ '99998', '99999', 'A0000', '    6', '    7' ],
		'a serial past 99999 is hybrid-36');
	is_deeply([ map { substr($_, 22, 4) } @l ], [ '9999', 'A000', 'A001', '   0', '    ' ],
		'and so is a residue number past 9999; a residue with no number has a blank one');
	is(Chem::Structure::Parser::_convert_string(
		join('', map { sprintf "%-80s\n", $_ } "HETATM$_  O   HOH W   1       0.000   0.000   0.000  1.00 20.00           O")
		, 0, 1, {})->{coordinates} =~ /^HETATM(.{5})/ ? $1 : '', $_,
		"serial $_ goes back as it came") for qw(zzzzz ZZZZZ a0000);
}

#--------------------------------------------------------------------
# numbers
#--------------------------------------------------------------------
{
	# A number goes across as the characters it was written in, and an mmCIF
	# one too long for its column is written to the column's decimals and
	# counted.  1.23456 has room for itself in eight columns; -123.45678 does
	# not, and is -123.457.
	my $cif = "data_X\nloop_\n" . join('', map { "_atom_site.$_\n" } qw(group_PDB id
		type_symbol label_atom_id label_comp_id label_asym_id Cartn_x Cartn_y Cartn_z
		occupancy B_iso_or_equiv auth_seq_id)) . <<'CIF';
ATOM 1 C CA GLY A 1.23456 -123.45678 1e1 0.333333 12.3456(7) 1
ATOM 2 C CA GLY A 1.000 2.000 3.000 1.00 999.99 2
CIF
	my ($pdb, $r) = text_of(\$cif, to => 'pdb');
	my ($one, $two) = records($pdb, 'ATOM');
	is(substr($one, 30, 8), ' 1.23456', 'a coordinate that fits goes across as written, decimals and all');
	is(substr($one, 38, 8), '-123.457', 'one that does not is written to three decimals');
	is(substr($one, 46, 8), '  10.000', 'an exponent is not something a column takes, and is written out');
	is(substr($one, 54, 6), '  0.33', 'an occupancy to two');
	is(substr($one, 60, 6), ' 12.35', "and a B written with its uncertainty, 12.3456(7), to two as well");
	is($r->{rounded}, 3, 'three of those are no longer the number they were, and are counted; 1e1 is still 10');
	is(substr($two, 60, 6), '999.99', 'a B-factor that only just fits goes as it is');
	my $back = structure_info_string($pdb, features => 0)->{chains}{A}{residues}{1}{atoms}{CA};
	is($back->{x}, 1.23456, 'so x reads back as itself');
	is($back->{y}, -123.457, 'and y as its rounding');
	my ($cif2, $r2) = text_of(\$cif, to => 'mmcif');
	is($r2->{rounded}, 0, 'mmCIF has room for every one of them');
	is_deeply(coords(structure_info_string($cif2, features => 0)), coords(structure_info_string($cif, features => 0)),
		'and they read back exactly');

	# nan and inf have no decimals to round to: as written, where they fit
	my $nan = sprintf "%-80s\n", 'ATOM      1  CA  GLY A   1         nan   2.000   3.000  1.00 10.00           C';
	my $c = text_of(\$nan, to => 'mmcif');
	like($c, qr/^ATOM 1 C CA \. GLY A \? \? \? nan 2\.000 3\.000 /m, 'a nan coordinate goes to mmCIF as nan');
	is(substr((records(scalar text_of(\$c, to => 'pdb'), 'ATOM'))[0], 30, 16), '     nan   2.000', 'and back');
}

#--------------------------------------------------------------------
# ANISOU
#--------------------------------------------------------------------
# stack.pdb's first five atoms with an ANISOU after each, the factors made up:
# what is tested is that they cross as the same numbers.  The ANISOU record
# repeats columns 7-27 and 77-80 of its atom, and holds U11 U22 U33 U12 U13 U23
# in 29-35, 36-42, ... 64-70, in units of 10**-4 A**2.
my @U = ([ 1234, 2345, 3456, -12, 34, -567 ], [ 10, 20, 30, 0, -1, 1 ],
         [ 99999, 123456, 7, -999999, 5, 6 ], [ 4000, 4100, 4200, 10, 20, 30 ],
         [ 1, 2, 3, 4, 5, 6 ]);
my $aniso_pdb = do {
	open my $fh, '<', "$data/stack.pdb" or die "Can't open '$data/stack.pdb' with mode '<': '$!'";
	my @atoms = grep { /^ATOM/ } <$fh>;
	close $fh or die "Can't close '$data/stack.pdb': '$!'";
	my $t = '';
	for my $i (0 .. 4) {
		(my $a = $atoms[$i]) =~ s/\s+\z//;
		$a = sprintf '%-80s', $a;
		$t .= "$a\n" . 'ANISOU' . substr($a, 6, 22) . join('', map { sprintf '%7d', $_ } @{ $U[$i] })
		    . (' ' x 6) . substr($a, 76, 4) . "\n";
	}
	$t;
};
{
	my ($cif, $r) = text_of(\$aniso_pdb, to => 'mmcif');
	is($r->{anisou}, 5, 'an ANISOU record per atom goes to mmCIF');
	like($cif, qr/^loop_\n_atom_site_anisotrop\.id\n/m, 'as an _atom_site_anisotrop loop');
	like($cif, qr/^1 N 0\.1234 0\.2345 0\.3456 -0\.0012 0\.0034 -0\.0567$/m,
		'each factor the decimal it stands for, exactly, by the atom id');
	like($cif, qr/^3 C 9\.9999 12\.3456 0\.0007 -99\.9999 0\.0005 0\.0006$/m,
		'the widest of them as well');
	is(structure_info_string($cif, features => 0)->{stats}{n_anisou}, 5, 'which the mmCIF reader counts');

	my ($pdb, $r2) = text_of(\$cif, to => 'pdb');
	is($r2->{anisou}, 5, 'and they come back');
	is($r2->{rounded}, 0, 'as the same numbers');
	is_deeply([ records($pdb, 'ANISOU') ], [ records($aniso_pdb, 'ANISOU') ],
		'byte for byte what the PDB file had');
	my @l = split /\n/, $pdb;
	ok(!grep({ $l[$_] =~ /^ANISOU/ && substr($l[$_], 6, 21) ne substr($l[ $_ - 1 ], 6, 21) } 1 .. $#l),
		'each after its own atom');
	is_deeply([ records(scalar text_of(\$aniso_pdb, to => 'pdb'), 'ANISOU') ], [ records($aniso_pdb, 'ANISOU') ],
		'and PDB to PDB leaves them as they were');

	is(text_of(\$aniso_pdb, to => 'mmcif', anisou => 0) =~ /anisotrop/ ? 1 : 0, 0,
		'anisou => 0 leaves them out');
	is(scalar(() = records(scalar text_of(\$aniso_pdb, to => 'pdb', anisou => 0), 'ANISOU')), 0, 'of either format');
	# atom 3 and its ANISOU moved to chain B, column 22
	(my $b3 = $aniso_pdb) =~ s/^((?:ATOM  |ANISOU)    3 .{9})A/$1B/mg;
	my ($h, $rh) = text_of(\$b3, to => 'pdb', chains => [ 'A' ]);
	is($rh->{anisou}, 4, 'an ANISOU goes where its atom goes, and is left out with it');
	ok(!grep({ substr($_, 6, 5) eq '    3' } records($h, 'ANISOU')), 'atom 3\'s is not written');
	is((text_of(\$b3, to => 'mmcif', chains => [ 'A' ]))[1]{anisou}, 4, 'to mmCIF as well');

	# an mmCIF factor with more places than four goes to the nearest 10**-4
	(my $fine = $cif) =~ s/^1 N 0\.1234 /1 N 0.12344 /m;
	my ($p3, $r3) = text_of(\$fine, to => 'pdb');
	is((records($p3, 'ANISOU'))[0] =~ /^.{28}(.{7})/ ? $1 + 0 : undef, 1234,
		'a factor with five places goes to the nearest 10**-4');
	is($r3->{rounded}, 1, 'and is counted');
	# and one that goes to mmCIF again, as written
	my $c3 = text_of(\$fine, to => 'mmcif');
	like($c3, qr/^1 N 0\.12344 /m, 'mmCIF to mmCIF keeps it as written');

	# atom 3 moved to chain B: an option that leaves it out leaves its row out
	my $moved = join "\n", map {
		my @f = split / /;
		@f[6, 18] = ('B', 'B') if /^ATOM 3 /;
		join ' ', @f;
	} split /\n/, $cif;
	my ($m1, $rm1) = text_of(\$moved, to => 'mmcif', chains => [ 'A' ]);
	is($rm1->{anisou}, 4, 'mmCIF to mmCIF writes the _atom_site_anisotrop rows of the atoms it wrote');
	unlike($m1, qr/^3 C /m, 'and not the row of the one it did not');
	my ($m2, $rm2) = text_of(\$moved, to => 'pdb', chains => [ 'A' ]);
	is(scalar(() = records($m2, 'ANISOU')), 4, 'mmCIF to PDB likewise');
}

#--------------------------------------------------------------------
# options
#--------------------------------------------------------------------
for my $f (qw(mini.pdb mini.cif nmr.pdb nmr.cif iface.pdb)) {
	for my $o ([ model => 2 ], [ chains => [ 'B' ] ], [ hydrogens => 0 ], [ waters => 0 ],
	           [ hetatm => 0 ], [ waters => 0, hydrogens => 0, chains => [ 'A' ] ]) {
		my $label = join ' => ', map { ref $_ ? "[@$_]" : $_ } @$o;
		my %opt = @$o;
		my $want = eval { structure_info("$data/$f", features => 0, %opt) } or next;
		next unless $want->{stats}{n_atoms};
		# structure_info() reads model 1 of a file that has no model 2; convert()
		# writes the file's model 2, of which there is none, and says so below
		next if exists $opt{model} && $want->{model} ne $opt{model};
		for my $to (qw(pdb mmcif)) {
			my $got = structure_info_string(scalar text_of("$data/$f", to => $to, %opt),
			                                features => 0, model => 'all');
			# What was left out was never written, so the counts of what the
			# file had are of a different file; the chains are what is compared.
			is_deeply([ coords($got)->{chains}, $got->{chain_order} ],
			          [ coords($want)->{chains}, $want->{chain_order} ],
				"$f to $to with $label: the structure structure_info() reads with it");
		}
	}
}
{
	my ($t, $r) = text_of("$data/nmr.pdb", to => 'pdb');
	is_deeply($r->{models}, [ 1, 2, 3 ], "model => 'all' is the default: every model");
	is($r->{atoms}, 36, 'and every atom');
	is(text_of("$data/mini.pdb", to => 'cif'), text_of("$data/mini.pdb", to => 'mmcif'),
		"to => 'cif' is mmCIF");
	is(text_of("$data/mini.cif", to => 'ent'), text_of("$data/mini.cif", to => 'pdb'), "to => 'ent' is PDB");
	is(text_of("$data/mini.cif", from => 'cif', to => 'pdb'), text_of("$data/mini.cif", to => 'pdb'),
		'from names the input format');
	throws_ok { convert("$data/nmr.pdb", \my $x, to => 'pdb', model => 7) }
		qr/^convert: the options leave none of the 36 atoms of '[^']*nmr\.pdb' to write; its models are 1, 2, 3 at /,
		'a model the file does not have is not an empty file, and the message says which it has';
	throws_ok { convert("$data/mini.pdb", \my $x, to => 'pdb', chains => [ 'Q' ]) }
		qr/^convert: the options leave none of the 66 atoms of '[^']*mini\.pdb' to write at /,
		'nor is a chain it does not have';
	my $nameless = "$tmp/structure";
	open my $fh, '>', $nameless or die "Can't open '$nameless' with mode '>': '$!'";
	print {$fh} scalar text_of("$data/mini.cif", to => 'mmcif') or die "Can't write to '$nameless': '$!'";
	close $fh or die "Can't close '$nameless': '$!'";
	is(convert($nameless, \my $x, to => 'pdb')->{from}, 'mmcif',
		'and a file whose name says nothing is known by its first records');
}

#--------------------------------------------------------------------
# where it comes from and where it goes
#--------------------------------------------------------------------
{
	my $want = text_of("$data/mini.pdb", to => 'mmcif');
	open my $fh, '<', "$data/mini.pdb" or die "Can't open '$data/mini.pdb' with mode '<': '$!'";
	my $text = do { local $/; <$fh> };
	close $fh or die "Can't close '$data/mini.pdb': '$!'";
	# the data block is named for the file, and text has none
	(my $from_text = text_of(\$text, to => 'mmcif')) =~ s/\Adata_\w+/data_X/;
	(my $named = $want) =~ s/\Adata_\w+/data_X/;
	is($from_text, $named,
		'a reference to the text converts as the file does');

	my %can = map {
		(my $pm = "$_.pm") =~ s{::}{/}g;
		($_ => (eval { require $pm; 1 } ? 1 : 0));
	} qw(IO::Compress::Gzip IO::Compress::Bzip2 IO::Uncompress::Gunzip IO::Uncompress::Bunzip2);
	SKIP: {
		skip 'IO::Compress is not installed', 4
			unless $can{'IO::Compress::Gzip'} && $can{'IO::Uncompress::Gunzip'};
		convert("$data/mini.pdb", "$tmp/mini.cif.gz");
		my $u;
		IO::Uncompress::Gunzip::gunzip("$tmp/mini.cif.gz" => \$u)
			or die "Can't gunzip '$tmp/mini.cif.gz': '$IO::Uncompress::Gunzip::GunzipError'";
		is($u, $want, 'an output named .gz is gzipped');
		my $p;
		is(convert("$tmp/mini.cif.gz", \$p, to => 'pdb')->{from}, 'mmcif', 'and a .gz is read as its inner name says');
		is_deeply(coords(structure_info_string($p, model => 'all', features => 0)),
		          coords(structure_info("$data/mini.pdb", model => 'all', features => 0)),
			'and comes back to the structure it was');
		skip 'IO::Compress::Bzip2 is not installed', 1 unless $can{'IO::Compress::Bzip2'};
		convert("$data/nmr.cif", "$tmp/nmr.pdb.bz2");
		is_deeply(coords(structure_info("$tmp/nmr.pdb.bz2", model => 'all', features => 0)),
		          coords(structure_info("$data/nmr.cif", model => 'all', features => 0)),
			'an output named .bz2 is compressed with bzip2');
	}

	my $file = "$tmp/handle.pdb";
	open my $out, '>', $file or die "Can't open '$file' with mode '>': '$!'";
	convert("$data/mini.cif", $out, to => 'pdb');
	close $out or die "Can't close '$file': '$!'";
	open my $in, '<', $file or die "Can't open '$file' with mode '<': '$!'";
	my $got = do { local $/; <$in> };
	close $in or die "Can't close '$file': '$!'";
	is($got, text_of("$data/mini.cif", to => 'pdb'), 'a file handle is written to');
	require IO::File;
	my $io = IO::File->new($file, '>') or die "Can't open '$file' with mode '>': '$!'";
	convert("$data/mini.cif", $io, to => 'pdb');
	$io->close or die "Can't close '$file': '$!'";
	# Read back through the same layers it was written with, not measured with
	# -s: both handles are text mode, so on Windows each newline is two bytes
	# on disk and one in $got.  0.040 compared the sizes and failed there.
	open $in, '<', $file or die "Can't open '$file' with mode '<': '$!'";
	my $again = do { local $/; <$in> };
	close $in or die "Can't close '$file': '$!'";
	is($again, $got, 'and so is an IO::File');
}
{
	my ($text, $r) = text_of("$data/mini.cif", to => 'pdb');
	is_deeply([ sort keys %$r ], [ sort qw(from to atoms anisou models rounded notes) ],
		'convert() hands back what it did');
	is($r->{from}, 'mmcif', 'the format it read');
	is($r->{to}, 'pdb', 'the format it wrote');
	is($r->{atoms}, 66, 'how many atoms');
	is_deeply($r->{models}, [ 1 ], 'which models');
	is($r->{rounded}, 0, 'how many numbers lost places');
	is_deeply($r->{notes}, [], 'and what of the header it could not write');
}

#--------------------------------------------------------------------
# what a PDB record has no room for
#--------------------------------------------------------------------
# An atom with a field the format has no columns for ends the conversion, and
# the message names the atom.  The alternatives are a record whose every later
# column is out by one, or a chain id made up for it.
{
	my $head = "data_X\nloop_\n" . join('', map { "_atom_site.$_\n" } qw(group_PDB id
		type_symbol label_atom_id label_alt_id label_comp_id label_asym_id label_seq_id
		Cartn_x Cartn_y Cartn_z auth_seq_id pdbx_PDB_model_num));
	my %bad = (
		'a two-character chain id'   => [ 'ATOM 7 C CA . GLY AB 1 1.0 2.0 3.0 1 1',
		                                  qr/^convert: the chain id 'AB' has no PDB spelling: a PDB record has one column for it \(atom 7, 'CA' of GLY 1 in chain 'AB', model 1\)/ ],
		'a five-letter residue name' => [ 'HETATM 1 C C1 . A1AAA A 1 1.0 2.0 3.0 1 1',
		                                  qr/^convert: the residue name 'A1AAA' has no PDB spelling: a PDB record has three columns for it/ ],
		'a five-letter atom name'    => [ 'ATOM 1 C CALPH . GLY A 1 1.0 2.0 3.0 1 1',
		                                  qr/^convert: the atom name 'CALPH' has no PDB spelling/ ],
		'a two-letter altloc'        => [ 'ATOM 1 C CA AB GLY A 1 1.0 2.0 3.0 1 1',
		                                  qr/^convert: the alternate location 'AB' has no PDB spelling/ ],
		'a coordinate past 9999.999' => [ 'ATOM 1 C CA . GLY A 1 12345.678 2.0 3.0 1 1',
		                                  qr/^convert: the x coordinate '12345\.678' does not fit the 8 columns a PDB record has for it/ ],
		'a negative coordinate past -999.999' => [ 'ATOM 1 C CA . GLY A 1 1.0 -1000.000 3.0 1 1',
		                                  qr/^convert: the y coordinate '-1000\.000' does not fit/ ],
		'a residue number below -999' => [ 'ATOM 1 C CA . GLY A 1 1.0 2.0 3.0 -1000 1',
		                                  qr/^convert: the residue number -1000 is outside what the four columns/ ],
		'a residue number past hybrid-36' => [ 'ATOM 1 C CA . GLY A 1 1.0 2.0 3.0 2436112 1',
		                                  qr/^convert: the residue number 2436112 is outside/ ],
		'a serial past hybrid-36'    => [ 'ATOM 87440032 C CA . GLY A 1 1.0 2.0 3.0 1 1',
		                                  qr/^convert: the serial number 87440032 is past what the five columns/ ],
		'a model number past four columns' => [ "ATOM 1 C CA . GLY A 1 1.0 2.0 3.0 1 1\nATOM 2 C CA . GLY A 1 1.0 2.0 3.0 1 10000",
		                                  qr/^convert: model 10000 has no PDB spelling: a MODEL record has four columns for its number/ ],
	);
	for my $what (sort keys %bad) {
		my ($row, $re) = @{ $bad{$what} };
		my $cif = "$head$row\n";
		throws_ok { convert(\$cif, \my $t, to => 'pdb') } $re, "$what ends the conversion, and says which atom";
		lives_ok { convert(\$cif, \my $t, to => 'mmcif') } "and is no trouble to mmCIF";
	}
	# the widest each field takes
	my $cif = $head . join "\n", 'ATOM 87440031 C CA . GLY A 1 9999.999 -999.999 1.0 2436111 9999',
	                             'ATOM 2 C CA . GLY A 1 1.0 2.0 3.0 -999 -999', '';
	my $p = text_of(\$cif, to => 'pdb');
	my @l = records($p, 'ATOM');
	is(substr($l[0], 6, 5), 'zzzzz', 'serial 87,440,031 is the last hybrid-36 has');
	is(substr($l[0], 22, 4), 'zzzz', 'residue 2,436,111 likewise');
	is(substr($l[0], 30, 16), '9999.999-999.999', 'and eight columns hold 9999.999 and -999.999');
	is_deeply([ map { substr($_, 10, 4) } records($p, 'MODEL') ], [ '9999', '-999' ],
		'a model number goes from -999 to 9999');
	is_deeply(coords(structure_info_string($p, model => 'all', features => 0)),
	          coords(structure_info_string($cif, model => 'all', features => 0)),
		'all of which reads back');
}
{
	# a value mmCIF has to quote
	my $cif = "data_X\nloop_\n" . join('', map { "_atom_site.$_\n" } qw(group_PDB id
		type_symbol label_atom_id label_comp_id label_asym_id Cartn_x Cartn_y Cartn_z
		auth_seq_id)) . <<'CIF';
HETATM 1 C 'C 1' LIG "X'Y" 1.0 2.0 3.0 1
HETATM 2 C "O' 2" LIG '_A' 1.0 2.0 3.0 2
HETATM 3 C . LIG '.' 1.0 2.0 3.0 3
HETATM 4 C 'data_x' LIG '#A' 1.0 2.0 3.0 4
HETATM 5 C "'Q" LIG 'loop_' 1.0 2.0 3.0 5
CIF
	my $out = text_of(\$cif, to => 'mmcif');
	like($out, qr/^HETATM 1 C 'C 1' \. LIG X'Y /m,
		"a blank is quoted, and a quote inside a value is not, which is how O5' is written");
	like($out, qr/^HETATM 2 C "O' 2" \. LIG '_A' /m, "a ' followed by a blank is quoted with \"; a leading _ is quoted");
	like($out, qr/^HETATM 3 C \? \. LIG '\.' /m, 'a full stop that is a value is quoted, and a missing name is ?');
	like($out, qr/^HETATM 4 C 'data_x' \. LIG '#A' /m, 'and so are a reserved word and a comment character');
	like($out, qr/^HETATM 5 C ''Q' \. LIG 'loop_' /m, 'and a leading quote, which a blank after the value closes');
	is_deeply(coords(structure_info_string($out, features => 0)), coords(structure_info_string($cif, features => 0)),
		'and they all read back as what they were');
	throws_ok { convert(\$cif, \my $t, to => 'pdb') } qr/^convert: the chain id 'X'Y' has no PDB spelling/,
		'none of which is a PDB chain id';
}

done_testing();
