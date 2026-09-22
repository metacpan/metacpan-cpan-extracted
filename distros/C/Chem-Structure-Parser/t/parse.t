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
# The two shapes the parse hands back, which have to say the same thing.
#
# With atom_hashes the per-atom fields are a hash per atom and the residue's
# identity is one entry per residue; without it they are one array per field,
# one entry per atom.  Everything above reads the columnar shape, which is what
# a caller of the low-level parse gets; the module itself always asks for the
# hashes, so the two are checked against each other here -- read at the index a
# residue begins on, they are the same residue in both.
#--------
for my $stem (qw(mini.pdb nmr.pdb quirks.cif mini.cif)) {
	my $file = "t/data/$stem";
	my $read = $stem =~ /\.cif\z/
		? \&Chem::Structure::Parser::_parse_cif_file
		: \&Chem::Structure::Parser::_parse_file;
	my $cols = $read->($file, {});
	my $hash = $read->($file, { atom_hashes => 1 });
	is($hash->{n_atoms}, $cols->{n_atoms}, "$stem: both shapes keep the same atoms");
	is_deeply($hash->{res_first}, $cols->{res_first}, "$stem: and mark the same residues");
	is_deeply($hash->{res_last},  $cols->{res_last},  "$stem: at the same atoms");
	my (@from_hash, @from_cols);
	for my $r (0 .. $#{ $cols->{res_first} }) {
		my $i0 = $cols->{res_first}[$r];
		for my $f (qw(resname chain resseq icode het model)) {
			push @from_hash, $hash->{$f}[$r];
			push @from_cols, $cols->{$f}[$i0];
		}
	}
	is_deeply(\@from_hash, \@from_cols,
		"$stem: every residue's identity reads the same out of either shape");
	is(scalar @{ $hash->{resname} }, scalar @{ $hash->{res_first} },
		"$stem: the hash shape has one identity per residue");
	is(scalar @{ $cols->{resname} }, $cols->{n_atoms},
		"$stem: and the columnar shape one per atom");
	# the atoms themselves: the hash carries what the columns do
	for my $i (0 .. ($cols->{n_atoms} > 3 ? 3 : $cols->{n_atoms} - 1)) {
		is_deeply([ map { $hash->{atoms}[$i]{$_} } qw(name altloc x y z element charge) ],
		          [ map { $cols->{$_}[$i] } qw(name altloc x y z element charge) ],
			"$stem: atom $i is the same atom in both shapes");
	}
}

#--------
# the charge columns, 79-80, which in a file old enough to keep its entry id in
# columns 73-80 hold the tail of that id instead.  A field that is not a digit
# and a sign is not a charge, and reads as the empty field a blank column would
# have given -- pdb1gdr.ent ends its records '1GDR 109', where '09' is two
# digits and not a charge either.
#--------
{
	# columns 1-66 are the record up to the B-factor, 67-76 are blank, 77-78 are
	# the element and 79-80 the charge
	my $head = 'ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00';
	is(length $head, 66, 'the record prefix ends where the B-factor does');
	my $rec = sub { $head . (' ' x 10) . sprintf('%2s%2s', @_) };
	is(length $rec->(' C', 'DR'), 80, 'and the whole record runs to column 80');
	my $q = Chem::Structure::Parser::_parse_string($rec->(' C', 'DR') . "\n", {});
	is($q->{charge}[0], '', 'letters in the charge columns are not a charge');
	is($q->{element}[0], 'C', 'and the element beside them is still read');
	my $r = Chem::Structure::Parser::_parse_string($rec->(' C', '1+') . "\n", {});
	is($r->{charge}[0], '1+', 'a digit and a sign is');
	my $s = Chem::Structure::Parser::_parse_string($rec->(' C', '09') . "\n", {});
	is($s->{charge}[0], '', 'and two digits, as pdb1gdr.ent writes its line numbers, are not');
}

#--------
# a residue number that is not a number.  Four columns hold at most 9999, and a
# file written by something that overflowed them puts '****' there, the same
# way an overflowed serial number becomes '*****'.  It has to read as undef --
# the file does not say which residue this is -- rather than as a zero that
# would merge every such residue with a real residue 0.
#--------
{
	# built with sprintf rather than typed: the fields either side of this one
	# are one character wide and a hand-typed record slides them
	my $rec = sprintf('ATOM  %5s %-4s%1s%3s %1s%4s%1s   %8s%8s%8s  1.00 20.00           C',
		1, ' CA ', '', 'ALA', 'A', '****', '', 10, 10, 10);
	is(length $rec, 78, 'the record is as long as a record with an element column');
	my $q = Chem::Structure::Parser::_parse_string("$rec\n", {});
	is($q->{resseq}[0], undef, 'a residue number of **** is undef, not zero');
	is($q->{icode}[0], '', 'and it has not been read as an insertion code');
	is($q->{resname}[0], 'ALA', 'the fields around it are unharmed');
	is($q->{x}[0], 10, 'including the coordinates');

	my $i = structure_info_string("$rec\n");
	is_deeply($i->{chains}{A}{residue_order}, [ '' ],
		'the residue it builds is keyed by the insertion code alone');
	is($i->{chains}{A}{residues}{''}{number}, undef, 'and has no number to give');
	is($i->{chains}{A}{n_gaps}, 0, 'a chain whose residues have no numbers has no gaps');
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

#--------
# the answer does not depend on the locale.
#
# perl calls setlocale(LC_ALL, "") at startup on any USE_LOCALE build, so
# LC_CTYPE in an XS module is whatever the caller's environment says -- the
# NetBSD smoker that reported 0.031 ran under en_US.UTF-8.  Everything this
# reader classifies is ASCII by definition (an element symbol, a residue name,
# a CIF keyword), so the answer must not move when the locale does: isalpha()
# in a Latin-1 locale calls an accented byte a letter, and tolower('I') in a
# Turkish one is not 'i', which would stop an mmCIF file written in capitals
# from being recognised at all.  Parser.xs uses perl's ASCII-only toUPPER(),
# toLOWER(), isALPHA() and isDIGIT() rather than <ctype.h> for exactly that.
#
# Which locales exist is the machine's business, so the loop asks for a spread
# and tests the ones it gets; "C" is always one of them, so this never becomes
# a test that runs nowhere.
#--------
SKIP: {
	eval { require POSIX; 1 } or skip 'POSIX is not available', 1;
	my $lc = POSIX::setlocale(POSIX::LC_CTYPE());
	my $pdb = <<'PDB';
ATOM      1  N   MET A   1      11.104  13.207  10.000  1.00 15.00           N
HETATM    2 ZN    ZN A 202      45.000  22.000  22.000  1.00 20.00          ZN
ATOM      3  HG11ILE A   2      11.000  13.000  10.000  1.00 15.00
PDB
	# uppercase tags and keywords: legal mmCIF, and what a case-insensitive
	# compare through tolower() gets wrong in a Turkish locale
	my @tag = qw(group_PDB id type_symbol auth_atom_id auth_comp_id
	             auth_asym_id auth_seq_id Cartn_x Cartn_y Cartn_z);
	my $cif = "DATA_X\nLOOP_\n"
	        . join('', map { "_ATOM_SITE.$_\n" } @tag)
	        . "ATOM 1 N N MET A 1 11.104 13.207 10.000\n";
	my $want_pdb = structure_info_string($pdb);
	my $want_cif = structure_info_string($cif, format => 'mmcif');
	my $tried = 0;
	for my $loc (qw(C tr_TR.ISO8859-9 tr_TR.iso88599 tr_TR.UTF-8 tr_TR.utf8
	                tr_TR de_DE.ISO-8859-1 de_DE.ISO8859-1 en_US.UTF-8)) {
		next unless defined POSIX::setlocale(POSIX::LC_CTYPE(), $loc);
		$tried++;
		is_deeply(structure_info_string($pdb), $want_pdb, "PDB reads the same under $loc");
		is_deeply(structure_info_string($cif, format => 'mmcif'), $want_cif,
			"mmCIF reads the same under $loc");
	}
	POSIX::setlocale(POSIX::LC_CTYPE(), $lc) if defined $lc;
	ok($tried, "the locale spread found $tried to test");
}

done_testing();
