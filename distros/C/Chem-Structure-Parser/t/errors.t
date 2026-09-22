#!/usr/bin/env perl
# What happens when the caller is wrong, and what happens when the file is.
#
# The rule throughout is that a mistake is fatal and says what it was.  A
# reader that quietly returns an empty structure for a missing file turns a
# typo in a path into an afternoon of wondering why every protein came back
# with no chains.
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

#--------
# the file
#--------
throws_ok { structure_info() } qr/no file name/, 'no file name dies';
throws_ok { structure_info(undef) } qr/no file name/, 'an undefined file name dies';
throws_ok { structure_info('') } qr/no file name/, 'an empty file name dies';
throws_ok { structure_info("$data/no.such.file.pdb") } qr/does not exist/,
	'a file that is not there dies, and says which one';
throws_ok { structure_info($data) } qr/is a directory/, 'a directory dies';

#--------
# formats
#--------
{
	my $dir = tempdir(CLEANUP => 1);
	# a format that is recognised and not written yet says so, and says what
	# can be read instead
	open my $fh, '>', "$dir/x.mol2" or die $!;
	print {$fh} "\@<TRIPOS>MOLECULE\n";
	close $fh;
	throws_ok { structure_info("$dir/x.mol2") } qr/MOL2.*not implemented/,
		'a format that is recognised but not written yet says so';
	throws_ok { structure_info("$dir/x.mol2") } qr/formats read today: mmcif, pdb/,
		'and says what can be read instead';

	# something that is not a structure at all
	open my $g, '>', "$dir/x.txt" or die $!;
	print {$g} "this is not a structure file\n";
	close $g;
	throws_ok { structure_info("$dir/x.txt") } qr/unrecognized format/,
		'a file that is not a structure dies';

	# ... but a PDB by any other name is still read, because the records say so
	open my $h, '>', "$dir/coords.txt" or die $!;
	print {$h} "ATOM      1  CA  ALA A   1      10.000  10.000  10.000  1.00 20.00           C\n";
	close $h;
	lives_ok { structure_info("$dir/coords.txt") }
		'a PDB with an unhelpful name is recognised by its records';
	is(structure_info("$dir/coords.txt")->{chains}{A}{sequence}, 'A',
		'and read properly');

	# the other format that is recognised and not written yet, and the two ways
	# a format is recognised: by the name, and by what is in the file
	open my $s, '>', "$dir/x.sdf" or die $!;
	print {$s} "  Mrv1234\n\n\n  0  0  0  0  0  0            999 V2000\nM  END\n";
	close $s;
	throws_ok { structure_info("$dir/x.sdf") } qr/SDF.*not implemented/,
		'an SDF is recognised by its name and is not implemented yet';
	rename "$dir/x.sdf", "$dir/x.dat" or die $!;
	throws_ok { structure_info("$dir/x.dat") } qr/SDF.*not implemented/,
		'and by its M  END line when the name says nothing';
	open my $m, '>', "$dir/y.dat" or die $!;
	print {$m} "\@<TRIPOS>MOLECULE\nthing\n";
	close $m;
	throws_ok { structure_info("$dir/y.dat") } qr/MOL2.*not implemented/,
		'a MOL2 likewise, by its TRIPOS record';
	# and from a string, where there is no name to go on at all
	throws_ok { structure_info_string("\@<TRIPOS>MOLECULE\nthing\n") }
		qr/MOL2.*not implemented/, 'and the same from a string';
	# text that looks like nothing in particular is read as PDB from a string,
	# because the caller has already said it is a structure
	lives_ok { structure_info_string("this is not a structure file\n") }
		'while text that looks like nothing is read as PDB rather than refused';

	# and the format can be forced past the detection
	lives_ok { structure_info("$dir/x.txt", format => 'pdb') }
		'format => pdb overrides the detection';
	throws_ok { structure_info("$dir/x.txt", format => 'nonsense') } qr/unrecognized format/,
		'a format that does not exist dies';
}

#--------
# a file that is a PDB but a damaged one.  Damage is not the caller-s fault
# and must not be fatal: half a structure is usually still worth having, and
# the counts say what was in it.
#--------
{
	my $truncated = "HEADER    TEST                                    01-JAN-20   9ABC\n"
	              . "ATOM      1  N   MET A   1      11.104  13.207  10.000  1.00 15.00           N\n"
	              . "ATOM      2  CA  MET A   1";     # cut off before the coordinates
	my $i;
	lives_ok { $i = structure_info_string($truncated) } 'a file cut off mid-record does not die';
	is($i->{stats}{n_atoms}, 2, 'the half record is still an atom');
	is($i->{chains}{A}{residues}{1}{atoms}{CA}{name}, 'CA', 'with the fields it did have');
	is($i->{chains}{A}{residues}{1}{atoms}{CA}{x}, undef, 'and the ones it lost undef');
	is($i->{chains}{A}{residues}{1}{atoms}{CA}{y}, undef, 'all of them');
	is($i->{chains}{A}{residues}{1}{atoms}{N}{x}, 11.104, 'and the whole records unharmed');
	ok(defined $i->{stats}{bbox}, 'the atom that did have coordinates is still in the bounding box');
}
{
	# a record cut off in the middle of a coordinate, which is the nastier
	# case: x has a number in it and y has nothing
	my $i;
	lives_ok { $i = structure_info_string(
		"ATOM      1  N   MET A   1      11.104  13.2") }
		'a record cut off mid-coordinate does not die either';
	is($i->{chains}{A}{residues}{1}{atoms}{N}{z}, undef, 'the coordinate that is gone is undef');
	ok(!defined $i->{chains}{A}{residues}{1}{center},
		'and a residue with an incomplete coordinate has no centre rather than a wrong one');
}
{
	# a record whose numeric fields are not numbers
	my $junk = "ATOM      1  CA  ALA A   1         abc     def     ghi  1.00 20.00           C\n";
	my $i;
	lives_ok { $i = structure_info_string($junk) } 'unreadable coordinates do not die';
	is($i->{chains}{A}{residues}{1}{atoms}{CA}{x}, undef, 'they come back undef');
	ok(!defined $i->{stats}{bbox}, 'and there is no bounding box to speak of');
}
{
	# an atom with no chain id, which is legal and common in ligand-only files
	my $i = structure_info_string(
		"HETATM    1  C1  LIG     1      10.000  10.000  10.000  1.00 20.00           C\n");
	is_deeply($i->{chain_order}, [''], 'an atom with no chain id lands in a chain named the empty string');
	is($i->{chains}{''}{type}, 'hetero', 'and the chain is a heterogen chain');
}

#--------
# structure_info_string
#--------
throws_ok { structure_info_string(undef) } qr/undefined/, 'undefined text dies';
lives_ok  { structure_info_string('') } 'empty text does not die';
is(structure_info_string('')->{stats}{n_atoms}, 0, 'and reads as nothing');

#--------
# the XS entry points, asked directly.
#
# structure_info() checks its arguments before the parse ever sees them, so
# these croaks are the ones underneath -- what a caller reaching past the front
# door hits, and the last thing between a wrong argument and a segmentation
# fault.  They are tested here because nothing else can reach them.
#--------
{
	my %parse = (
		_parse_file       => "$data/mini.pdb",
		_parse_string     => "ATOM      1  CA  ALA A   1      1.0 2.0 3.0\n",
		_parse_cif_file   => "$data/mini.cif",
		_parse_cif_string => "data_x\n",
	);
	for my $fn (sort keys %parse) {
		no strict 'refs';
		my $f = \&{"Chem::Structure::Parser::$fn"};
		throws_ok { $f->(undef, {}) } qr/is undefined/,
			"$fn: an undefined argument dies";
		throws_ok { $f->($parse{$fn}, []) } qr/options must be a hash reference/,
			"$fn: options that are not a hash reference die";
		throws_ok { $f->($parse{$fn}, 'no') } qr/options must be a hash reference/,
			"$fn: and so does a plain string";
		lives_ok { $f->($parse{$fn}) } "$fn: and the options may be left out entirely";
	}
	# a directory, which is the path every caller eventually mistypes.  It is
	# refused before the open rather than left to the read, because reading one
	# is three different things: glibc opens it and fails the first read with
	# EISDIR, Windows will not open it at all, and NetBSD hands back the raw
	# directory blocks, which parse as a structure with nothing in it.  0.031
	# asked for the glibc answer here and two smokers said so -- Strawberry
	# 5.42.0 on Win2012 ('Permission denied' from the open) and perl 5.42.3 on
	# NetBSD 11 ('normal exit', an empty structure for a directory).
	for my $fn (qw(_parse_file _parse_cif_file)) {
		no strict 'refs';
		throws_ok { &{"Chem::Structure::Parser::$fn"}($data, {}) } qr/is a directory/,
			"$fn: a directory dies, on every system";
	}
}

#--------
# is_single_ion, which takes two shapes of argument and has to tell them apart
#--------
{
	my $i = structure_info("$data/mini.pdb");
	throws_ok { is_single_ion({ chains => 'not a hash' }, 'A') }
		qr/expected the hash reference from structure_info/,
		'a structure whose chains are not chains dies';
	throws_ok { is_single_ion({ chains => {} }, 'Z') } qr/no chain 'Z'/,
		'and a chain that is not in it names the chain';
	throws_ok { is_single_ion($i, undef) } qr/no chain given/,
		'two arguments with no chain in the second is a missing chain, not a chain hash';
	throws_ok { is_single_ion($i->{chains}{A}{residues}{6}) } qr/that is a residue/,
		'a residue says it is a residue';
	throws_ok { is_single_ion($i) } qr/that is the whole structure/,
		'and the whole structure says so as well';
	throws_ok { is_single_ion('A') } qr/expected the chain hash reference/,
		'something that is not a reference at all dies';
}

#--------
# unreadable files
#--------
SKIP: {
	skip 'running as root, which can read anything', 2 if $> == 0;
	my $dir = tempdir(CLEANUP => 1);
	open my $fh, '>', "$dir/locked.pdb" or die $!;
	print {$fh} "ATOM      1  CA  ALA A   1      10.000  10.000  10.000\n";
	close $fh;
	chmod 0000, "$dir/locked.pdb";
	skip 'file is still readable', 2 if -r "$dir/locked.pdb";
	throws_ok { structure_info("$dir/locked.pdb") } qr/cannot read/,
		'a file that cannot be opened dies';
	throws_ok { structure_info("$dir/locked.pdb") } qr/locked\.pdb/,
		'and names the file';
	chmod 0600, "$dir/locked.pdb";

	# the same thing on the gzip path, which opens the file through
	# IO::Uncompress::Gunzip rather than through the XS and so has a failure of
	# its own to report.  A method's return value was never autodie's job, which
	# is why this one is checked by hand.
	SKIP: {
		eval { require IO::Compress::Gzip; 1 } or skip 'IO::Compress is not installed', 2;
		IO::Compress::Gzip::gzip("$dir/locked.pdb" => "$dir/locked.pdb.gz")
			or skip 'cannot gzip the fixture: '
			        . do { no warnings 'once'; $IO::Compress::Gzip::GzipError }, 2;
		chmod 0000, "$dir/locked.pdb.gz";
		skip 'file is still readable', 2 if -r "$dir/locked.pdb.gz";
		throws_ok { structure_info("$dir/locked.pdb.gz") } qr/cannot gunzip/,
			'a gzipped file that cannot be opened dies too';
		throws_ok { structure_info("$dir/locked.pdb.gz") } qr/locked\.pdb\.gz/,
			'and names that file as well';
		chmod 0600, "$dir/locked.pdb.gz";
	}
}

done_testing();
