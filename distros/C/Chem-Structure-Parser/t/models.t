#!/usr/bin/env perl
# MODEL records.  An NMR ensemble is twenty or sixty copies of the same
# molecule, and reading all of them when one was wanted is the difference
# between a structure that fits in memory and one that does not -- so the
# default is one model, and the rest are there on request.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

my $data = dirname(abs_path(__FILE__)) . '/data';
my $file = "$data/nmr.pdb";

#--------
# by default, model 1
#--------
{
	my $i = structure_info($file);
	is($i->{n_models}, 3, 'all three models are counted');
	is($i->{model}, 1, 'but the chains are built from the first');
	is($i->{stats}{n_atoms}, 12, 'only one model of atoms was kept');
	is($i->{stats}{n_atom_records}, 36, 'though the file has three models of them');
	is($i->{stats}{total_atoms}, 36, 'total_atoms counts every model, not the selected one');
	is($i->{stats}{total_atoms}, $i->{stats}{n_atoms} + $i->{stats}{n_skipped},
		'and the ones it did not keep are the ones it skipped');
	is($i->{chains}{A}{sequence}, 'GSW', 'the sequence is read once, not three times');
	ok(!exists $i->{models}, 'and there is no per-model breakdown unless it is asked for');
}

#--------
# a named model
#--------
{
	my $one   = structure_info($file, model => 1);
	my $three = structure_info($file, model => 3);
	is($three->{model}, 3, 'model => 3 reads the third model');
	is($three->{chains}{A}{sequence}, 'GSW', 'which is the same molecule');
	isnt($three->{chains}{A}{residues}{1}{atoms}{N}{x},
	     $one->{chains}{A}{residues}{1}{atoms}{N}{x},
	     'but not the same coordinates');
}

#--------
# every model at once
#--------
{
	my $i = structure_info($file, model => 'all');
	is($i->{stats}{n_atoms}, 36, "model => 'all' keeps every model");
	is_deeply([ sort { $a <=> $b } keys %{ $i->{models} } ], [ 1, 2, 3 ],
		'and each one is under models');
	is($i->{model}, 1, 'chains still points at the first model');
	is($i->{chains}{A}{sequence}, 'GSW', 'which is a whole molecule, not three interleaved');
	is($i->{models}{2}{chains}{A}{n_residues}, 3, 'every model has its own chains');
	is($i->{models}{3}{chains}{A}{sequence}, 'GSW', 'and its own sequence');
	isnt($i->{models}{1}{chains}{A}{residues}{1}{atoms}{N}{x},
	     $i->{models}{2}{chains}{A}{residues}{1}{atoms}{N}{x},
	     'and its own coordinates');
}

#--------
# a model that is not there.  Asking for model 9 of a three model file should
# not quietly hand back an empty structure.
#--------
{
	my $i = structure_info($file, model => 9);
	is($i->{stats}{n_atoms}, 12, 'asking for a model that is not there falls back to the first one');
	is($i->{model}, 1, 'and says which model it actually read');
}

#--------
# models numbered from something other than 1.  An ensemble whose models are
# numbered 0 and 5 has no model 1, and the default must not come back empty.
#--------
{
	my $text = '';
	for my $m (0, 5) {
		$text .= sprintf("MODEL     %4d\n", $m);
		$text .= "ATOM      1  CA  ALA A   1      1$m.000  10.000  10.000  1.00 20.00           C\n";
		$text .= "ENDMDL\n";
	}
	my $s = structure_info_string($text);
	is($s->{n_models}, 2, 'two models, numbered 0 and 5');
	is($s->{stats}{n_atoms}, 1, 'the default model number is not there, so the first one is read');
	is($s->{model}, 0, 'and it says which one that was');
	is($s->{chains}{A}{residues}{1}{atoms}{CA}{x}, 10, 'the coordinates are model 0-s');
}

#--------
# a file with no MODEL records at all is model 1, which is what makes the
# default work for the crystal structures that are most of the PDB
#--------
{
	my $i = structure_info("$data/mini.pdb");
	is($i->{n_models}, 1, 'a file with no MODEL records has one model');
	ok($i->{stats}{n_atoms} > 0, 'and its atoms are read under the default');
}

done_testing();
