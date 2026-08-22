#!/usr/bin/env perl
# The assembled hash of hashes: chains, residues, atoms, and the numbers that
# go with them, read from t/data/mini.pdb.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

my $data = dirname(abs_path(__FILE__)) . '/data';
my $info = structure_info("$data/mini.pdb");

#--------
# the top of the structure
#--------
is($info->{id},       '9XYZ', 'id comes from the HEADER record');
is($info->{format},   'pdb',  'the format is recorded');
is($info->{n_models}, 1,      'a file with no MODEL records has one model');
is($info->{model},    1,      'and the chains were built from it');
like($info->{file}, qr/mini\.pdb\z/, 'the file it was read from is kept');

#--------
# chains
#--------
is_deeply($info->{chain_order}, [ 'A', 'B' ], 'chains are in the order the file has them');
is($info->{chains}{A}{type}, 'protein', 'chain A is a protein');
is($info->{chains}{B}{type}, 'dna',     'chain B is DNA, not RNA: its residues are DA, DC, DG, DT');
is($info->{chains}{A}{molecule}, 'TEST PROTEIN', 'the chain knows what molecule it is, from COMPND');
is($info->{chains}{A}{organism}, 'HOMO SAPIENS', 'and what it came from, from SOURCE');
is($info->{chains}{A}{ec},       '3.4.21.5',     'and its EC number');
is($info->{chains}{A}{mol_id},   '1',            'and which COMPND entity it belongs to');
is($info->{chains}{B}{molecule}, 'TEST DNA',     'the second entity is mapped to its own chain');

#--------
# the sequence, which is the thing this was written for
#--------
is($info->{chains}{A}{sequence}, 'MAGCMHHSC',
	'chain A single-letter sequence: MSE counts as M, and the ligand, ion and waters are not in it');
is($info->{chains}{B}{sequence}, 'ACGT', 'chain B reads as DNA');
is($info->{chains}{A}{seqres}, 'MAGLKCMHHSC', 'SEQRES is the full sequence, including what was not modelled');
is($info->{chains}{A}{seqres_length}, 11, 'and its length');
is($info->{chains}{A}{n_missing},      2, 'two residues in SEQRES have no coordinates');
is($info->{chains}{B}{seqres}, 'ACGT', 'SEQRES for a DNA chain');

is_deeply(structure_sequences($info), { A => 'MAGCMHHSC', B => 'ACGT' },
	'structure_sequences: every chain that has a sequence');
is_deeply(structure_sequences("$data/mini.pdb"), { A => 'MAGCMHHSC', B => 'ACGT' },
	'structure_sequences: a file name is read on the spot');
is_deeply(structure_sequences("$data/mini.pdb", atoms => 0, meta => 0),
	{ A => 'MAGCMHHSC', B => 'ACGT' },
	'structure_sequences: and reads it with the options it was given');
throws_ok { structure_sequences("$data/no-such-file.pdb") } qr/does not exist/,
	'structure_sequences: a file name that is not a file says so';
throws_ok { structure_sequences($info, atoms => 0) } qr/options apply to reading a file/,
	'structure_sequences: options with an already-parsed structure would do nothing, so they are refused';
throws_ok { structure_sequences(undef) } qr/expected a file name/,
	'structure_sequences: and nothing at all is still an error';
is(chain_sequence($info, 'A'), 'MAGCMHHSC', 'chain_sequence: observed by default');
is(chain_sequence($info, 'A', 'seqres'), 'MAGLKCMHHSC', 'chain_sequence: seqres on request');

#--------
# gaps -- where the observed sequence and SEQRES part company
#--------
is($info->{chains}{A}{n_gaps}, 1, 'chain A has one gap');
is_deeply($info->{chains}{A}{gaps}, [ { after => '3', before => '6', missing => 2 } ],
	'the gap names the residues either side of it and how many are missing');
is($info->{chains}{B}{n_gaps}, 0, 'chain B is continuous');
is_deeply($info->{chains}{A}{missing_residues}, [ 4, 5 ],
	'missing_residues: the gap spelled out one residue number at a time');
is_deeply($info->{chains}{B}{missing_residues}, [],
	'missing_residues: a chain with no gaps still has the list, empty');

#--------
# Numbering that is not sequential.  An antibody numbered by the Kabat scheme
# runs 27, 1027, 2027, 28: the thousands are insertions after 27, not a
# 999-residue hole, and reading them literally makes 1a4k a 214-residue light
# chain missing five thousand residues.  Insertion codes are the other half of
# it -- a chain that spends its numbering on 149A..149E has less room for
# missing residues than its residue count suggests, and must still see the
# real gap further along.
#--------
{
	my $n = 0;
	my $ca = sub {
		my ($resname, $chain, $resseq, $icode) = @_;
		$n++;
		return sprintf('ATOM  %5d  CA  %-3s %s%4d%-1s   %8.3f%8.3f%8.3f  1.00  0.00           C',
			$n, $resname, $chain, $resseq, $icode // ' ', $n, 0, 0);
	};

	my $kabat = structure_info_string(join "\n",
		(map { $ca->('ALA', 'A', $_) } 25, 26, 27),
		(map { $ca->('GLY', 'A', $_) } 1027, 2027),      # insertions after 27
		(map { $ca->('SER', 'A', $_) } 28, 29, 30),
		'END', '');
	is($kabat->{chains}{A}{n_gaps}, 0,
		'a jump wider than the chain is a numbering scheme, not a gap');
	is_deeply($kabat->{chains}{A}{missing_residues}, [],
		'and so it contributes no missing residues');

	my $icodes = structure_info_string(join "\n",
		(map { $ca->('ALA', 'H', $_) } 146, 147, 148, 149),
		(map { $ca->('GLY', 'H', 149, $_) } 'A' .. 'E'), # 149A..149E
		(map { $ca->('SER', 'H', $_) } 150, 151, 152),
		(map { $ca->('SER', 'H', $_) } 155, 156),        # the real gap: 153, 154
		'END', '');
	is_deeply($icodes->{chains}{H}{missing_residues}, [ 153, 154 ],
		'insertion codes share a number, so the gap past them is still found');
	is_deeply($icodes->{chains}{H}{gaps},
		[ { after => '152', before => '155', missing => 2 } ],
		'and it is the one gap the chain has');
}

#--------
# counts
#--------
is($info->{chains}{A}{n_residues}, 13, 'chain A: 9 polymer residues, a ligand, an ion and two waters');
is($info->{chains}{A}{n_polymer},   9, 'nine of them are polymer');
is($info->{chains}{A}{n_water},     2, 'two are water');
is($info->{chains}{A}{n_ligand},    2, 'two are heterogens (the sugar and the zinc)');
is($info->{chains}{B}{n_residues},  4, 'chain B has four nucleotides');
is($info->{stats}{n_atoms}, 66, 'every coordinate record was counted');
is($info->{stats}{n_atoms},
	$info->{chains}{A}{n_atoms} + $info->{chains}{B}{n_atoms},
	'and the chains account for all of them');

#--------
# residues
#--------
my $r = $info->{chains}{A}{residues}{6};
is($r->{resname}, 'CYS', 'residue 6 is a cysteine');
is($r->{one},     'C',   'its single-letter code');
is($r->{type},    'amino_acid', 'its type');
is($r->{number},  6,   'its number');
is($r->{icode},   '',  'and no insertion code');
is($r->{hetero},  0,   'it was written as ATOM');
is($r->{standard}, 1,  'it is one of the twenty');
is($r->{modified}, 0,  'and not modified');
is($r->{n_atoms},  5,  'five atoms');
is_deeply($r->{atom_order}, [ qw(N CA C O SG) ], 'in the order the file has them');

# a modified residue is still part of the sequence
my $mse = $info->{chains}{A}{residues}{7};
is($mse->{resname},  'MSE',        'residue 7 is selenomethionine');
is($mse->{one},      'M',          'which reads as M');
is($mse->{type},     'amino_acid', 'and counts as an amino acid');
is($mse->{hetero},   1,            'even though it was written as HETATM');
is($mse->{modified}, 1,            'it is flagged as modified');
is($mse->{standard}, 0,            'and not standard');

# insertion codes: 8 and 8A are two residues, not one
ok(exists $info->{chains}{A}{residues}{'8'},  'residue 8 exists');
ok(exists $info->{chains}{A}{residues}{'8A'}, 'and residue 8A beside it');
is($info->{chains}{A}{residues}{'8A'}{icode},  'A', 'the insertion code is kept');
is($info->{chains}{A}{residues}{'8A'}{number},   8, 'and the number is still 8');
isnt($info->{chains}{A}{residues}{'8'}{atoms}{CA}{serial},
     $info->{chains}{A}{residues}{'8A'}{atoms}{CA}{serial},
     'the two residues hold different atoms');

# a ligand, an ion and water are told apart
is($info->{chains}{A}{residues}{201}{type}, 'ligand', 'NAG is a ligand');
is($info->{chains}{A}{residues}{202}{type}, 'ion',    'a lone ZN is an ion, not a ligand');
is($info->{chains}{A}{residues}{301}{type}, 'water',  'HOH is water');
is($info->{chains}{A}{residues}{201}{one},  '',       'a ligand has no single-letter code');

#--------
# atoms
#--------
my $ca = $info->{chains}{A}{residues}{6}{atoms}{CA};
is($ca->{name},    'CA', 'the atom knows its name');
is($ca->{element}, 'C',  'and its element');
is($ca->{hetero},  0,    'and which record it came from');
ok(!exists $ca->{altlocs}, 'an atom with one conformer carries no altloc list');
# The fixture writes the coordinates with %8.3f and the reader is exact for a
# fixed-point field, so the difference observed here is 0 -- on a double, a long
# double and a __float128 perl alike.  1e-9 is not room for the conversion to be
# wrong in; it is there so that a difference of the size a mis-read column gives
# (0.001 at the very least) still fails.
cmp_ok(abs($ca->{x} - 20.5), '<', 1e-9, 'x');
cmp_ok(abs($ca->{y} - 14.0), '<', 1e-9, 'y');
cmp_ok(abs($ca->{z} - 13.5), '<', 1e-9, 'z');

is($info->{chains}{A}{residues}{202}{atoms}{ZN}{element}, 'Zn',
	'a two-letter element is read as two letters, and cased as IUPAC writes it');

# a residue's centre and mean B-factor
my $c = $info->{chains}{A}{residues}{6}{center};
is(scalar @$c, 3, 'a residue has a centre');
ok(defined $info->{chains}{A}{residues}{6}{b_mean}, 'and a mean B-factor');

#--------
# alternate conformers.  Both are kept on the atom; which one supplies the
# coordinates is the altloc option's business, tested in options.t.
#--------
my $cb = $info->{chains}{A}{residues}{2}{atoms}{CB};
is($cb->{altloc}, 'A', 'the first conformer supplies the coordinates by default');
is(scalar @{ $cb->{altlocs} }, 2, 'but both conformers are recorded');
is_deeply([ map { $_->{altloc} } @{ $cb->{altlocs} } ], [ 'A', 'B' ], 'in file order');
is($cb->{altlocs}[1]{occupancy}, 0.6, 'with the occupancy of each');
is($info->{chains}{A}{residues}{2}{n_atoms}, 6,
	'the residue counts both conformer records');
is(scalar @{ $info->{chains}{A}{residues}{2}{atom_order} }, 5,
	'but has five distinct atom names');

#--------
# Microheterogeneity: one position modelled in two chemical states at once,
# written as complementary altloc groups.  A selenomethionine that only went
# halfway in is both MSE and MET at the same number -- 3zeu has ten of them,
# MSE in altlocs A and B and MET in C and D -- and 2ftm, 5nai, 5za2 and 6e4z
# do the same with IAS/ASP, CSD/CYS, SEP/SER and NEP/HIP.  A residue is a
# number and an insertion code, so this is one residue and not two: counting
# it twice would put a second M in the sequence of a protein that has one.
# The two states stay apart on the atoms that tell them apart.
#--------
{
	my $n = 0;
	my $atom = sub {
		my ($name, $alt, $resname, $elem, $occ) = @_;
		$n++;
		return sprintf('%-6s%5d %-4s%1s%-3s %s%4d%-1s   %8.3f%8.3f%8.3f%6.2f%6.2f          %2s',
			($resname eq 'MSE' ? 'HETATM' : 'ATOM'), $n, " $name", $alt, $resname,
			'A', 41, ' ', $n, 0, 0, $occ, 0, $elem);
	};
	my $s = structure_info_string(join "\n",
		(map { $atom->($_->[0], 'A', 'MSE', $_->[1], 0.30) }
			[ N => 'N' ], [ CA => 'C' ], [ C => 'C' ], [ O => 'O' ], [ SE => 'SE' ]),
		(map { $atom->($_->[0], 'B', 'MET', $_->[1], 0.70) }
			[ N => 'N' ], [ CA => 'C' ], [ C => 'C' ], [ O => 'O' ], [ SD => 'S' ]),
		'END', '');

	is_deeply([ @{ $s->{chains}{A}{residue_order} } ], [ '41' ],
		'two chemical states at one number are one residue, not two');
	is($s->{chains}{A}{sequence}, 'M', 'and contribute one letter to the sequence');
	my $r = $s->{chains}{A}{residues}{41};
	is($r->{resname}, 'MSE', 'the residue takes the name written first');
	is($r->{n_atoms}, 10,    'every record of both states is counted');
	is_deeply([ map { $_->{altloc} } @{ $r->{atoms}{N}{altlocs} } ], [ 'A', 'B' ],
		'a backbone atom carries a conformer from each state');
	is_deeply([ sort @{ $r->{atom_order} } ], [ qw(C CA N O SD SE) ],
		'and the atoms unique to each state are both kept');
}

#--------
# whole-structure statistics
#--------
is($info->{stats}{n_hetatm}, 13, 'HETATM records are counted: MSE, NAG, ZN and two waters');
is($info->{stats}{total_atoms}, 66, 'total_atoms is every coordinate record the file has');
is($info->{stats}{total_atoms}, $info->{stats}{n_atoms},
	'and equals n_atoms when nothing was filtered out');
is($info->{stats}{total_atoms},
	$info->{stats}{n_atom_records} + $info->{stats}{n_hetatm_records},
	'it is the two record counts added up');
is($info->{stats}{n_water_atoms}, 2, 'water atoms are counted');
is($info->{stats}{n_hydrogens},   1, 'so are hydrogens');
is($info->{stats}{elements}{S},   2, 'elements are tallied');
is($info->{stats}{elements}{Se},  1, 'including two-letter ones');
is($info->{stats}{elements}{Zn},  1, 'and the zinc written ZN is filed under Zn');
ok(!exists $info->{stats}{elements}{ZN}, 'with nothing left under the shouted spelling');
{
	# the tally counts coordinate records, which is what n_atoms counts, so the
	# two have to add up -- for the structure and for each chain of it
	my $sum = 0;
	$sum += $_ for values %{ $info->{stats}{elements} };
	is($sum, $info->{stats}{n_atoms}, 'the element counts add up to n_atoms');
	for my $cid (@{ $info->{chain_order} }) {
		my $c = $info->{chains}{$cid};
		my $n = 0;
		$n += $_ for values %{ $c->{elements} };
		is($n, $c->{n_atoms}, "chain $cid: its element counts add up to its n_atoms");
	}
	# every count is a non-negative whole number, not a string that looks like one
	my @bad = grep { !/\A[0-9]+\z/ } values %{ $info->{stats}{elements} };
	is_deeply(\@bad, [], 'every count is an unsigned integer');
	is($info->{chains}{A}{elements}{Zn}, 1, 'the zinc is tallied against the chain it sits in');
	ok(!exists $info->{chains}{B}{elements}{Zn}, 'and against no other chain');
	is_deeply([ sort keys %{ $info->{chains}{B}{elements} } ], [ qw(C O P) ],
		'a chain tallies only the elements it holds');
}
ok($info->{stats}{bfactor}{min} <= $info->{stats}{bfactor}{mean}, 'B-factor min <= mean');
ok($info->{stats}{bfactor}{mean} <= $info->{stats}{bfactor}{max}, 'B-factor mean <= max');
ok($info->{stats}{bbox}{xmin} < $info->{stats}{bbox}{xmax}, 'the bounding box has a width');
is(scalar @{ $info->{stats}{center} }, 3, 'and a centre');

#--------
# a file with nothing but coordinates in it
#--------
{
	my $bare = structure_info("$data/bare.pdb");
	is($bare->{id}, 'BARE', 'with no HEADER, the id falls back to the file name');
	is($bare->{chains}{A}{sequence}, 'VK', 'and the sequence is still read');
	is($bare->{chains}{A}{seqres}, undef, 'a file with no SEQRES has no seqres sequence');
	is($bare->{chains}{A}{residues}{1}{atoms}{CA}{element}, 'C',
		'and the elements are worked out from the atom names');
	is($bare->{title}, undef, 'a missing TITLE is undef rather than missing');
	is_deeply($bare->{keywords}, [], 'and a missing KEYWDS is an empty list');
}

#--------
# an empty file
#--------
{
	my $empty = structure_info("$data/empty.pdb");
	is_deeply($empty->{chain_order}, [], 'an empty file has no chains');
	is($empty->{stats}{n_atoms}, 0, 'and no atoms');
	lives_ok { structure_summary($empty) } 'and can still be summarised';
	is_deeply(structure_sequences($empty), {}, 'and has no sequences');
}

#--------
# the same file through a string
#--------
{
	open my $fh, '<', "$data/mini.pdb" or die $!;
	my $text = do { local $/; <$fh> };
	close $fh;
	my $s = structure_info_string($text);
	is($s->{id}, '9XYZ', 'structure_info_string: reads a structure from a string');
	is($s->{chains}{A}{sequence}, $info->{chains}{A}{sequence},
		'and gets the same sequence as reading the file');
	is($s->{file}, undef, 'with no file name to record');
}

#--------
# pdb_info() is structure_info() with the format settled
#--------
is_deeply(pdb_info("$data/mini.pdb"), $info, 'pdb_info: the same answer as structure_info');

done_testing();
