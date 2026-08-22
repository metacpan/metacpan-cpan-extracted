#!/usr/bin/env perl
# The XS parse itself: columns, numbers, residue boundaries, record grouping.
# These are the things a hand-written PDB reader gets wrong, so they are
# tested against the raw columnar result rather than through the assembled
# hash of hashes, where a mistake could be masked.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

my $p = Chem::Structure::Parser::_parse_string(<<'PDB', {});
HEADER    TEST                                    01-JAN-20   9ABC
ATOM      1  N   MET A   1      11.104  13.207  10.000  1.00 15.00           N
ATOM      2  CA AMET A   1     -12.500 111.000 -10.500  0.40 16.00           C
ATOM      3  CA BMET A   1      12.600 111.100 -10.600  0.60 17.00           C
HETATM    4 ZN    ZN A 202      45.000  22.000  22.000  1.00 20.00          ZN2+
TER       5      MET A   1
END
PDB

#--------
# every field, out of its own columns
#--------
is($p->{n_atoms}, 4, 'four coordinate records were kept');
is_deeply($p->{serial},  [ 1, 2, 3, 4 ],                'serial, columns 7-11');
is_deeply($p->{name},    [ 'N', 'CA', 'CA', 'ZN' ],     'atom name, columns 13-16');
is_deeply($p->{altloc},  [ '', 'A', 'B', '' ],          'altLoc, column 17');
is_deeply($p->{resname}, [ 'MET', 'MET', 'MET', 'ZN' ], 'residue name, columns 18-20');
is_deeply($p->{chain},   [ ('A') x 4 ],                 'chain id, column 22');
is_deeply($p->{resseq},  [ 1, 1, 1, 202 ],              'residue number, columns 23-26');
is_deeply($p->{icode},   [ ('') x 4 ],                  'insertion code, column 27');
is_deeply($p->{element}, [ 'N', 'C', 'C', 'Zn' ],       'element, columns 77-78');
is_deeply($p->{charge},  [ '', '', '', '2+' ],          'charge, columns 79-80');
is_deeply($p->{het},     [ 0, 0, 0, 1 ],                'ATOM and HETATM are told apart');
is_deeply($p->{model},   [ (1) x 4 ],                   'a file with no MODEL record is model 1');

#--------
# coordinates.  x, y and z are adjacent eight-column fields with no separator,
# so a parser that scans for a number rather than slicing the columns runs
# "-12.500 111.000" together, and a negative z touching the y before it is
# where that shows up.
#--------
is($p->{x}[0],  11.104, 'x is read from its own columns');
is($p->{y}[0],  13.207, 'y is read from its own columns');
is($p->{z}[0],  10.000, 'z is read from its own columns');
is($p->{x}[1], -12.500, 'a negative x that fills its field');
is($p->{y}[1], 111.000, 'a y wide enough to touch the field beside it');
is($p->{z}[1], -10.500, 'a negative z immediately after a wide y');
is($p->{occupancy}[1], 0.40, 'occupancy, columns 55-60');
is($p->{bfactor}[1],  16.00, 'B-factor, columns 61-66');

# the values are numbers, not the strings that were in the file
ok($p->{x}[0] + 1 == 12.104, 'coordinates come back as numbers');

#--------
# residue boundaries.  The three MET atoms are one residue, the zinc another.
#--------
is_deeply($p->{res_first}, [ 0, 3 ], 'res_first marks where each residue starts');
is_deeply($p->{res_last},  [ 2, 3 ], 'res_last marks where each residue ends');
is($p->{n_residues}, 2, 'two residues');

#--------
# non-coordinate records come back whole, grouped by record name
#--------
is(ref $p->{meta}, 'HASH', 'meta is keyed by record name');
is(scalar @{ $p->{meta}{HEADER} }, 1, 'the HEADER record is there');
like($p->{meta}{HEADER}[0], qr/9ABC/, 'and it is the whole line');
ok(!exists $p->{meta}{ATOM},   'coordinate records are not repeated in meta');
ok(!exists $p->{meta}{HETATM}, 'nor are HETATM records');
ok(!exists $p->{meta}{TER},    'TER is handled on its own');
is($p->{ter}[0]{chain}, 'A', 'TER records are collected');
is($p->{n_lines}, 7, 'every line was seen');

#--------
# a residue that changes only in one field is still a new residue
#--------
for my $case (
	[ 'residue number', 'ATOM      2  N   MET A   2      11.000  13.000  10.000' ],
	[ 'chain',          'ATOM      2  N   MET B   1      11.000  13.000  10.000' ],
	[ 'insertion code', 'ATOM      2  N   MET A   1A     11.000  13.000  10.000' ],
	[ 'residue name',   'ATOM      2  N   ALA A   1      11.000  13.000  10.000' ],
) {
	my ($what, $second) = @$case;
	my $q = Chem::Structure::Parser::_parse_string(
		"ATOM      1  N   MET A   1      10.000  10.000  10.000\n$second\n", {});
	is(scalar @{ $q->{res_first} }, 2, "a change of $what starts a new residue");
}

#--------
# lines the format allows that a strict reader would trip over
#--------
{
	# right-trimmed lines: the file stops before the B-factor and before the
	# element columns, which is legal and common in older files
	my $q = Chem::Structure::Parser::_parse_string(
		"ATOM      1  CA  ALA A   1      10.000  10.000  10.000\n", {});
	is($q->{n_atoms}, 1, 'a line that stops after the coordinates is still an atom');
	is($q->{occupancy}[0], undef, 'a missing occupancy is undef, not zero');
	is($q->{bfactor}[0],   undef, 'a missing B-factor is undef, not zero');
	is($q->{element}[0], 'C', 'a missing element is worked out from the atom name');
}
{
	# DOS line endings
	my $q = Chem::Structure::Parser::_parse_string(
		"ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C  \r\n", {});
	is($q->{element}[0], 'C', 'a CRLF line ending does not end up in the element');
	is($q->{n_atoms}, 1, 'a CRLF file parses');
}
{
	# a serial number that has overflowed its five columns
	my $q = Chem::Structure::Parser::_parse_string(
		"ATOM  ***** CA  ALA A   1      10.000  10.000  10.000\n", {});
	is($q->{n_atoms}, 1, 'an overflowed serial number does not lose the atom');
	is($q->{serial}[0], undef, 'and comes back undef rather than as a wrong number');
}
{
	my $q = Chem::Structure::Parser::_parse_string('', {});
	is($q->{n_atoms}, 0, 'an empty string parses to nothing');
	is($q->{n_lines}, 0, 'and no lines');
	is_deeply($q->{res_first}, [], 'and no residues');
}
{
	# a blank line in the middle, and a file with no trailing newline
	my $q = Chem::Structure::Parser::_parse_string(
		"ATOM      1  CA  ALA A   1      10.000  10.000  10.000\n\nEND", {});
	is($q->{n_atoms}, 1, 'blank lines and a missing final newline are fine');
}

#--------
# the element guess, for files written before the element columns existed.
# " CA " is a carbon alpha and "CA  " is a calcium: the difference is which
# column the name starts in, and getting it wrong turns hydrogens into mercury.
#--------
{
	my $q = Chem::Structure::Parser::_parse_string(join('', map { "$_\n" }
		'ATOM      1  CA  ALA A   1      10.000  10.000  10.000',
		'HETATM    2 CA    CA A   2      10.000  10.000  10.000',
		'ATOM      3 HG11 LEU A   3      10.000  10.000  10.000',
		'HETATM    4 FE    FE A   4      10.000  10.000  10.000',
		'ATOM      5  N   ALA A   1      10.000  10.000  10.000',
	), {});
	is_deeply($q->{element}, [ 'C', 'Ca', 'H', 'Fe', 'N' ],
		'the element is guessed from which column the atom name starts in');
}

#--------
# arguments
#--------
throws_ok { Chem::Structure::Parser::_parse_string(undef) } qr/undefined/,
	'_parse_string: undefined text dies';
throws_ok { Chem::Structure::Parser::_parse_file(undef) } qr/undefined/,
	'_parse_file: an undefined file name dies';
throws_ok { Chem::Structure::Parser::_parse_file('t/data/does.not.exist.pdb') } qr/cannot read/,
	'_parse_file: a missing file dies, and says so';
throws_ok { Chem::Structure::Parser::_parse_string('', 'not a hashref') } qr/hash reference/,
	'_parse_string: options must be a hash reference';

done_testing();
