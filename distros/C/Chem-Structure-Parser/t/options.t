#!/usr/bin/env perl
# The options, which are what makes a 33 MB structure readable at all, and
# the checking of them, because an ignored typo is a wrong answer that
# arrives without a word.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
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
lives_ok  { structure_info($file, model => 'all') } "model => 'all' is allowed";

done_testing();
