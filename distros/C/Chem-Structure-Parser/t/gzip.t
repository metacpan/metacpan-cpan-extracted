#!/usr/bin/env perl
# Gzipped files.  A directory of structures is usually kept compressed, and
# gunzipping to a temporary file first is both slower and something the
# caller then has to clean up.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Temp 'tempdir';
use Chem::Structure::Parser;
use Test::Exception;
use Test::More;

BEGIN {
	eval { require IO::Compress::Gzip; require IO::Uncompress::Gunzip; 1 }
		or plan skip_all => 'IO::Compress is not installed';
}

my $data = dirname(abs_path(__FILE__)) . '/data';
my $dir  = tempdir(CLEANUP => 1);

IO::Compress::Gzip::gzip("$data/mini.pdb" => "$dir/mini.pdb.gz")
	or plan skip_all => "cannot gzip the fixture: $IO::Compress::Gzip::GzipError";

my $plain = structure_info("$data/mini.pdb");
my $gz    = structure_info("$dir/mini.pdb.gz");

is($gz->{chains}{A}{sequence}, $plain->{chains}{A}{sequence},
	'a gzipped file gives the same sequence as the file it was made from');
is($gz->{stats}{n_atoms}, $plain->{stats}{n_atoms}, 'and the same atoms');
is_deeply($gz->{chains}{A}{residues}{6}, $plain->{chains}{A}{residues}{6},
	'and residues identical down to the atoms');
is($gz->{id}, '9XYZ', 'the header is read through the decompression too');
is($gz->{title}, $plain->{title}, 'including the title');

# The reader underneath, which takes a plain file as well as a gzipped one and
# either the whole of it or the first so many bytes.  Both forms are used: the
# whole file is how a .gz is read, and the first 8 kB is how a file whose name
# says nothing has its format sniffed.  Asked directly because nothing else
# reaches the whole-file form on a file that is not gzipped, and a reader that
# quietly returned nothing there would show up as an empty structure much later.
{
	my $whole = Chem::Structure::Parser::_slurp_maybe_gzipped("$data/mini.pdb", undef);
	my $head  = Chem::Structure::Parser::_slurp_maybe_gzipped("$data/mini.pdb", 64);
	my $bytes = do { open my $fh, '<:raw', "$data/mini.pdb" or die $!; local $/; <$fh> };
	is($whole, $bytes, 'a plain file with no limit is read whole');
	is(length $head, 64, 'and with a limit it stops there');
	is($head, substr($bytes, 0, 64), 'having read the front of the file');
	is(Chem::Structure::Parser::_slurp_maybe_gzipped("$dir/mini.pdb.gz", undef), $bytes,
		'and the gzipped copy of it comes back byte for byte the same');
	my $gzhead = Chem::Structure::Parser::_slurp_maybe_gzipped("$dir/mini.pdb.gz", 64);
	is(substr($gzhead, 0, 64), substr($bytes, 0, 64),
		'a limited read of a gzipped file stops at the first block past the limit');
}

# the id falls back to the file name with both suffixes taken off
{
	IO::Compress::Gzip::gzip("$data/bare.pdb" => "$dir/1abc.ent.gz") or die;
	my $i = structure_info("$dir/1abc.ent.gz");
	is($i->{id}, '1ABC', 'with no HEADER, the id comes from the name without .ent.gz');
}

# and options still apply
{
	my $i = structure_info("$dir/mini.pdb.gz", waters => 0, chains => ['B']);
	is_deeply($i->{chain_order}, ['B'], 'options work on a gzipped file');
}

# something that is not gzip at all, named as though it were.  IO::Uncompress
# reads uncompressed input transparently, so this is read rather than refused,
# which is the more useful of the two answers: the file is still a structure.
{
	open my $fh, '>', "$dir/lying.pdb.gz" or die $!;
	print {$fh} "ATOM      1  CA  ALA A   1      10.000  10.000  10.000\n";
	close $fh;
	my $i;
	lives_ok { $i = structure_info("$dir/lying.pdb.gz") }
		'a plain file named .gz is read anyway rather than refused';
	is($i->{chains}{A}{sequence}, 'A', 'and read correctly');
}

# A truncated gzip stream, which is a real thing to find in a download
# directory, is an error and not a short file.  IO::Uncompress::Gunzip's read()
# returns a negative number rather than undef for it, so the loop that reads the
# archive used to take it for the 0 that means end of stream: half of
# mini.pdb.gz came back as a structure with no atoms in it and nothing said so.
{
	open my $in, '<:raw', "$dir/mini.pdb.gz" or die $!;
	my $bytes = do { local $/; <$in> };
	close $in;
	open my $out, '>:raw', "$dir/cut.pdb.gz" or die $!;
	print {$out} substr($bytes, 0, int(length($bytes) / 2));
	close $out;
	throws_ok { structure_info("$dir/cut.pdb.gz") } qr/Can't read from .*cut\.pdb\.gz/,
		'a truncated gzip dies rather than coming back as a short file';
	throws_ok { structure_info("$dir/cut.pdb.gz") } qr/unexpected end of file/,
		'and says what the decompressor said was wrong with it';
}

done_testing();
