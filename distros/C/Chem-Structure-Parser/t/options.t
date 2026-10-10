#!/usr/bin/env perl
# The options, which are what makes a 33 MB structure readable at all, and
# the checking of them, because an ignored typo is a wrong answer that
# arrives without a word.
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
my $file = "$data/mini.pdb";
my $full = structure_info($file);

#--------
# hydrogens
#--------
{
	my $i = structure_info($file, hydrogens => 0);
	is($i->{stats}{n_hydrogens}, 0, 'hydrogens => 0 removes the hydrogens');
	is($i->{stats}{n_atoms}, $full->{stats}{n_atoms} - 1, 'and only the hydrogens');
	is($i->{stats}{total_atoms}, $full->{stats}{total_atoms},
		'total_atoms counts what the file has, so an option cannot change it');
	ok(!exists $i->{chains}{A}{residues}{9}{atoms}{HB2}, 'the hydrogen is gone from its residue');
	ok( exists $i->{chains}{A}{residues}{9}{atoms}{CB},  'and the carbon beside it is not');
	is($i->{chains}{A}{sequence}, $full->{chains}{A}{sequence}, 'the sequence is unchanged');
}

#--------
# waters
#--------
{
	my $i = structure_info($file, waters => 0);
	is($i->{stats}{n_water_atoms}, 0, 'waters => 0 removes the waters');
	is($i->{chains}{A}{n_water}, 0, 'the chain has none left');
	is($i->{chains}{A}{n_residues}, $full->{chains}{A}{n_residues} - 2, 'two residues fewer');
	ok(exists $i->{chains}{A}{residues}{201}, 'the ligand is still there');
}

#--------
# hetatm -- which takes the modified residue with it, because MSE is a HETATM
# record, and that changes the sequence
#--------
{
	my $i = structure_info($file, hetatm => 0);
	is($i->{stats}{n_hetatm}, 0, 'hetatm => 0 removes every HETATM record');
	ok(!exists $i->{chains}{A}{residues}{201}, 'the ligand is gone');
	ok(!exists $i->{chains}{A}{residues}{7},   'and so is the selenomethionine');
	is($i->{chains}{A}{sequence}, 'MAGCHHSC',
		'which leaves an M out of the sequence: dropping HETATM drops modified residues too');
}

#--------
# chains
#--------
{
	my $i = structure_info($file, chains => ['B']);
	is_deeply($i->{chain_order}, ['B'], 'chains => [B] reads only chain B');
	is($i->{chains}{B}{sequence}, 'ACGT', 'and reads it properly');
	is($i->{stats}{n_atoms}, 12, 'chain A never became an SV');
	# the header still describes the whole file, which is the right answer:
	# it is the file's header, not the chain's
	is($i->{compound}{1}{molecule}, 'TEST PROTEIN', 'the header still describes the whole entry');
}
{
	my $i = structure_info($file, chains => [ 'A', 'B' ]);
	is_deeply($i->{chain_order}, [ 'A', 'B' ], 'both chains asked for, both read');
}
{
	my $i = structure_info($file, chains => ['Z']);
	is_deeply($i->{chain_order}, [], 'a chain that is not there gives no chains');
	is($i->{stats}{n_atoms}, 0, 'and no atoms');
}

#--------
# atoms => 0, the option that makes a very large structure fit in memory
#--------
{
	my $i = structure_info($file, atoms => 0);
	is($i->{chains}{A}{n_residues}, $full->{chains}{A}{n_residues}, 'atoms => 0 keeps every residue');
	is($i->{chains}{A}{sequence}, $full->{chains}{A}{sequence}, 'and the sequence');
	is($i->{chains}{A}{n_atoms}, $full->{chains}{A}{n_atoms}, 'and the atom counts');
	is_deeply($i->{chains}{A}{residues}{6}{atoms}, {}, 'but builds no atom hashes');
	is_deeply($i->{chains}{A}{residues}{6}{atom_order}, [], 'and no atom order');
	ok(defined $i->{chains}{A}{residues}{6}{center}, 'the residue centre is still worked out');
	is($i->{stats}{elements}{S}, 2, 'and the element tally');

	# Everything but the atoms is the same structure, in both formats.  The
	# parse builds three shapes -- the atom hashes, the full columns, and the
	# slim columns atoms => 0 asks for, which keep only an atom's name and
	# position -- and a residue's type, its place in the polymer and its
	# centre are worked out from whichever it was given.
	my $strip = sub {
		my ($s) = @_;
		for my $c (values %{ $s->{chains} }) {
			for my $r (values %{ $c->{residues} }) { $r->{atoms} = {}; $r->{atom_order} = [] }
		}
		return $s;
	};
	for my $f (map { ("$data/$_.pdb", "$data/$_.cif") } qw(mini rna bases nmr)) {
		is_deeply(structure_info($f, atoms => 0, features => 0),
		          $strip->(structure_info($f, atoms => 1, features => 0)),
			"$f: atoms => 0 is the same structure less the atoms");
	}
}

#--------
# altloc
#--------
{
	my $first   = structure_info($file, altloc => 'first');
	my $highest = structure_info($file, altloc => 'highest');
	is($first->{chains}{A}{residues}{2}{atoms}{CB}{altloc}, 'A',
		"altloc => 'first' keeps the conformer that comes first");
	is($highest->{chains}{A}{residues}{2}{atoms}{CB}{altloc}, 'B',
		"altloc => 'highest' keeps the one with the higher occupancy");
	is($highest->{chains}{A}{residues}{2}{atoms}{CB}{occupancy}, 0.6,
		'and its occupancy comes with it');
	is(scalar @{ $highest->{chains}{A}{residues}{2}{atoms}{CB}{altlocs} }, 2,
		'either way both conformers are recorded');
}

#--------
# anisou.  ANISOU records are skipped by default: they double the size of a
# file and almost nothing wants them.
#--------
{
	my $text = "ATOM      1  N   MET A   1      11.104  13.207  10.000  1.00 15.00           N\n"
	         . "ANISOU    1  N   MET A   1     2406   1892   1614    198    519   -328       N\n";
	my $off = structure_info_string($text);
	my $on  = structure_info_string($text, anisou => 1);
	is($off->{stats}{n_anisou}, 1, 'ANISOU records are counted even when skipped');
	ok(!exists $off->{records}{ANISOU}, 'and not kept');
	is($on->{records}{ANISOU}, 1, 'anisou => 1 keeps them');
	is($off->{stats}{n_atoms}, 1, 'an ANISOU record is not mistaken for an atom');
}

#--------
# total_atoms is the count every option above is measured against, so it holds
# whatever they are set to: what the file has is what was kept plus what was
# skipped, in both formats.
#--------
{
	my @sets = ({}, { hydrogens => 0 }, { waters => 0 }, { hetatm => 0 },
	            { chains => ['A'] }, { model => 'all' }, { model => 3 },
	            { hydrogens => 0, waters => 0, hetatm => 0 });
	for my $stem (qw(mini.pdb mini.cif nmr.pdb nmr.cif)) {
		for my $o (@sets) {
			my $s = structure_info("$data/$stem", %$o)->{stats};
			# spelled out rather than interpolated: an arrayref option would
			# otherwise put a different address in the test name every run
			my $how = join ', ', map {
				"$_ => " . (ref $o->{$_} eq 'ARRAY' ? '[' . join(',', @{ $o->{$_} }) . ']' : $o->{$_})
			} sort keys %$o;
			is($s->{total_atoms}, $s->{n_atoms} + $s->{n_skipped},
				"$stem: kept plus skipped is the whole file" . ($how ? " ($how)" : ''));
		}
	}
}

#--------
# a bad option is fatal, and says what the good ones are
#--------
throws_ok { structure_info($file, hydrogen => 0) } qr/unknown option 'hydrogen'/,
	'a misspelled option dies rather than being ignored';
throws_ok { structure_info($file, hydrogen => 0) } qr/hydrogens/,
	'and the message lists the options that do exist';
throws_ok { structure_info($file, altloc => 'lowest') } qr/altloc must be/,
	'an unknown altloc policy dies';
throws_ok { structure_info($file, chains => 'A') } qr/chains must be an array reference/,
	'chains must be an arrayref, not a string';
throws_ok { structure_info($file, chains => []) } qr/chains is empty/,
	'an empty chain list is a mistake';
throws_ok { structure_info($file, model => 'two') } qr/model must be/,
	'a model that is not a number dies';
# undef where a value is needed says so, in the words of the function called,
# rather than dying of an uninitialized value somewhere inside it
throws_ok { structure_info($file, model => undef) }
	qr/\Astructure_info: model is undef; leave it out for the default, '1'/,
	'model => undef names the function and the option';
throws_ok { structure_info_string("END\n", altloc => undef) }
	qr/\Astructure_info_string: altloc is undef; leave it out for the default, 'first'/,
	'and so does altloc => undef';
lives_ok { structure_info($file, hydrogens => undef, chains => undef, format => undef) }
	'undef is still off for a switch, and not given for an option whose default is undef';
# and off means off whichever half reads the switch: hydrogens and sasa are read
# by the XS, which took an undef for not given and so for its default, on
is(structure_info($file, features => 0, hydrogens => undef)->{stats}{n_atoms},
	structure_info($file, features => 0, hydrogens => 0)->{stats}{n_atoms},
	'hydrogens => undef leaves the hydrogens out');
ok(!exists structure_features(structure_info($file, features => 0),
	sasa => undef, interface => 0)->{sasa}, 'sasa => undef computes no surface');
# structure_features() takes sasa => 0 and the rest of them; structure_info()
# takes features => 0 and no more than that.  A hash of the first spelled into
# the second is a true value, so it would compute every feature, the surface
# included, and say nothing -- the ignored option the checks above exist for.
throws_ok { structure_info($file, features => { sasa => 0 }) } qr/features is 1 or 0/,
	'the per-feature options are not structure_info options';
throws_ok { structure_info($file, features => { sasa => 0 }) } qr/structure_features/,
	'and the message says where they do belong';
lives_ok  { structure_info($file, model => 'all') } "model => 'all' is allowed";

#--------
# a view asked for in second place, which is the one call form that is not a
# file and an option list.  The two cannot be confused: an option list has an
# odd number of elements after the file name, a view leaves an even one.
#--------
{
	my $d = structure_info($file, 'dssp');
	is(ref $d, 'HASH', "structure_info(\$file, 'dssp') returns the view itself");
	ok(!exists $d->{chains}, 'and not the structure it came out of');
	is_deeply($d, structure_info($file)->{features}{dssp},
		'and it is the same hash the features hold');
	is_deeply(structure_info($file, 'dssp', hydrogens => 0),
	          structure_info($file, hydrogens => 0)->{features}{dssp},
		'the options after a view are the reader\'s, and are obeyed');
	throws_ok { structure_info($file, 'nosuch') } qr/'nosuch' is not a view/,
		'a name that is not a view dies and says what the views are';
	throws_ok { structure_info($file, 'nosuch') } qr/dssp/,
		'... which today is dssp';
	throws_ok { structure_info($file, 'hydrogens') } qr/did you mean an option/,
		'and an option name in that place is told what it should have been';
	is_deeply(structure_info($file, 'dssp', features => 0), $d,
		'the dssp view of a file read without the features computes just that');
	throws_ok { structure_info($file, 'dssp', atoms => 0) }
		qr/\Astructure_info: dssp needs the atoms, and this read has atoms => 0/,
		'and one read without the atoms is refused, not empty';
	my $on = structure_info($file, dssp => 1);
	is($on->{dssp}, $on->{features}{dssp}, 'dssp => 1 leaves the view at {dssp}');
	my $alone = structure_info($file, dssp => 1, features => 0);
	is_deeply($alone->{dssp}, $on->{dssp},
		'dssp => 1 with features => 0 computes the same secondary structure on its own');
	ok(!exists $alone->{features}, 'and nothing else');
	throws_ok { structure_info($file, dssp => 1, atoms => 0) }
		qr/dssp needs the atoms/, 'dssp => 1 with atoms => 0 is refused';
	ok(!exists structure_info($file)->{dssp}, 'and without it there is no such key');
}

#--------
# the same views of a structure already in a string.  structure_info_string()
# read a view's name as the first half of an option pair, and died of perl's
# 'Odd number of elements in hash assignment' until 0.039.
#--------
{
	open my $fh, '<', $file or die "Can't open '$file' with mode '<': '$!'";
	my $text = do { local $/; <$fh> };
	close $fh or die "Can't close '$file': '$!'";
	is_deeply(structure_info_string($text, 'dssp'), structure_info($file, 'dssp'),
		"structure_info_string(\$text, 'dssp') is the view, as it is from the file");
	is_deeply(structure_info_string($text, 'torsions', hydrogens => 0),
	          structure_info($file, 'torsions', hydrogens => 0),
		'and the options after a view are the reader\'s there too');
	throws_ok { structure_info_string($text, 'nosuch') }
		qr/\Astructure_info_string: 'nosuch' is not a view/,
		'a name that is not a view dies, naming the function called';
	throws_ok { structure_info_string($text, 'hydrogens') }
		qr/structure_info_string\(\$text, hydrogens => 1\)/,
		'and an option name in that place is told how to write it';
}

#--------
# an option list that is not pairs.  It died where it was unpacked into a hash,
# of perl's 'Odd number of elements in hash assignment', which said neither
# which function was called nor what was wrong.
#--------
throws_ok { structure_info($file, { model => 1 }) }
	qr/\Astructure_info: the options come in name => value pairs/,
	'structure_info: an option list of odd length says so';
throws_ok { structure_features(structure_info($file, features => 0), 'sasa') }
	qr/\Astructure_features: the options after the first argument come in name => value pairs/,
	'and so does every function that takes options after a structure';

#--------
# a model number larger than the parse can hold.  '9223372036854775808' passed
# the pattern and wrapped to a negative IV on the way in, which is the parse's
# sentinel for every model: one model asked for, all of them handed back.  The
# largest IV is the last that is allowed, on any perl's IV.
#--------
{
	my $max = ~0 >> 1;
	(my $over = "$max") =~ s/7\z/8/;    # IV_MAX ends in 7 at 32 and at 64 bits
	throws_ok { structure_info($file, model => $over) }
		qr/\Astructure_info: model $over is larger than any model number this perl can hold/,
		'a model number one past the largest integer is refused';
	throws_ok { structure_info($file, model => '9223372036854775808') }
		qr/is larger than any model number/, 'and so is the one that came back as every model';
	lives_ok { structure_info($file, model => $max) } 'the largest integer is a model number';
	is(structure_info($file, model => "000$max")->{model}, 1,
		'and leading zeros pad it rather than overflow it');
}

#--------
# the torsions view: each chain's torsions hash, keyed by chain id, with the
# residue_order the arrays are parallel to.  A structure whose chains are of
# different kinds is the case it is for, and no fixture is one with real
# geometry on both sides -- mini.pdb's chains are synthetic, and give chain A
# an omega and chain B nothing -- so fold.pdb's protein chain A and aform.pdb's
# DNA chain B are joined into one file here, record for record.
#--------
{
	my $dir = tempdir(CLEANUP => 1);
	my $mixed = "$dir/mixed.pdb";
	open my $out, '>', $mixed or die "Can't open '$mixed' with mode '>': '$!'";
	for my $part ("$data/fold.pdb", "$data/aform.pdb") {
		open my $in, '<', $part or die "Can't open '$part' with mode '<': '$!'";
		print {$out} grep { /^(?:ATOM|HETATM)/ } <$in>;
		print {$out} "TER\n";
		close $in or die "Can't close '$part': '$!'";
	}
	print {$out} "END\n";
	close $out or die "Can't close '$mixed': '$!'";

	# what each chain is on its own, from the structure the view comes out of
	my $expect = sub {
		my ($f, $id) = @_;
		my $c = structure_info($f)->{chains}{$id};
		return { %{ $c->{torsions} }, residue_order => $c->{residue_order} };
	};
	my $t = structure_info($mixed, 'torsions');
	is_deeply([ sort keys %$t ], [ qw(A B) ], 'torsions view: keyed by chain id');
	is_deeply([ sort keys %{ $t->{A} } ], [ qw(chi omega phi psi residue_order) ],
		'the protein chain carries the amino acid torsions and nothing else');
	is_deeply([ sort keys %{ $t->{B} } ],
		[ qw(alpha beta chi delta epsilon gamma glycosidic nu pucker
		     pucker_amplitude pucker_phase residue_order zeta) ],
		'and the DNA chain beside it the nucleotide ones');
	is_deeply($t->{A}, $expect->("$data/fold.pdb", 'A'),
		'the protein chain is what it is in a file of its own');
	is_deeply($t->{B}, $expect->("$data/aform.pdb", 'B'),
		'and so is the DNA chain');
	for my $id (qw(A B)) {
		my $n = @{ $t->{$id}{residue_order} };
		ok(!grep({ $_ ne 'residue_order' && @{ $t->{$id}{$_} } != $n } keys %{ $t->{$id} }),
			"chain $id: every array is one element per residue of residue_order");
	}
	ok(!defined $t->{B}{alpha}[0] && defined $t->{B}{alpha}[1],
		'the first nucleotide has no alpha and holds an undef for it, the second has one');
	is_deeply(structure_info($mixed, 'torsion'), $t, "'torsion' is the same view");
	is_deeply(structure_info($mixed, 'torsions', hydrogens => 0),
	          structure_info($mixed, 'torsions'),
		'the options after it are the reader\'s');

	for my $f (qw(fold aform duplex)) {
		is_deeply(structure_info("$data/$f.cif", 'torsions'),
		          structure_info("$data/$f.pdb", 'torsions'),
			"torsions view: $f.cif and $f.pdb give the same answer");
	}

	ok(!exists structure_info($file, 'torsions')->{B},
		'a chain with no angle at all is left out rather than an empty hash');
	is_deeply(structure_info("$data/bare.pdb", 'torsions'), {},
		'and a structure with none anywhere is an empty hash');
	throws_ok { structure_info($mixed, 'torsions', features => 0) }
		qr/'torsions' needs the features/,
		'a torsions view of a file read without the features is refused';
	throws_ok { structure_info($file, 'nosuch') } qr/dssp, torsions/,
		'and the views a wrong name is told about include it';
}

done_testing();
