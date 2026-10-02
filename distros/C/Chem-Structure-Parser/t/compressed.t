#!/usr/bin/env perl
# Compressed files, gzip and bzip2.  A directory of structures is usually kept
# compressed, and unpacking to a temporary file first is both slower and
# something the caller then has to clean up.
#
# Every case is run once per compressor, because the two are separate readers
# underneath (IO::Uncompress::Gunzip and IO::Uncompress::Bunzip2) and a case
# that holds for one says nothing about the other.  Each fixture is compressed
# here from t/data rather than shipped compressed, so the comparison is always
# with the file it was made from.  Each is skipped on its own where its
# IO::Compress module is missing -- core since 5.10.1, but some vendors package
# it apart from perl -- and the other is not skipped with it.
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

# The requires are spelled out, one eval to a line, because that is how
# test.all.perls.pl finds the modules a test loads only if they are there.
my @KIND = (
	{ name => 'gzip',  ext => 'gz',  verb => 'gunzip',  compress => 'IO::Compress::Gzip',
	  load => sub { eval { require IO::Compress::Gzip; require IO::Uncompress::Gunzip; 1 } } },
	{ name => 'bzip2', ext => 'bz2', verb => 'bunzip2', compress => 'IO::Compress::Bzip2',
	  load => sub { eval { require IO::Compress::Bzip2; require IO::Uncompress::Bunzip2; 1 } } },
);

sub slurp {
	my ($file) = @_;
	open my $fh, '<:raw', $file or die "Can't open '$file' with mode '<:raw': '$!'";
	my $text = do { local $/; <$fh> };
	close $fh or die "Can't close '$file': '$!'";
	return $text;
}

sub spew {
	my ($file, @text) = @_;
	open my $fh, '>:raw', $file or die "Can't open '$file' with mode '>:raw': '$!'";
	print {$fh} @text;
	close $fh or die "Can't close '$file': '$!'";
}

# the coordinate half of a structure, which is what has to be the same whatever
# the file was wrapped in; the file name is left out because it is the one
# thing that is meant to differ
sub coords {
	my ($i) = @_;
	return { map { $_ => $i->{$_} } grep { $_ ne 'file' } keys %$i };
}

for my $k (@KIND) {
	my ($name, $ext) = @{$k}{qw(name ext)};
	subtest $name => sub {
		$k->{load}->() or plan skip_all => "$k->{compress} is not installed";
		my $pack = do { no strict 'refs'; \&{"$k->{compress}::" . lc $k->{name}} };
		my $err  = sub { no strict 'refs'; ${"$k->{compress}::" . ucfirst($k->{name}) . 'Error'} };
		my $dir = tempdir(CLEANUP => 1);
		my $z = sub {
			my ($from, $to) = @_;
			$pack->($from => $to) or die "cannot $name '$from': " . $err->();
			return $to;
		};

		# ---- both formats, every field --------------------------------
		for my $f ('mini.pdb', 'mini.cif') {
			my $plain = structure_info("$data/$f");
			my $c     = structure_info($z->("$data/$f", "$dir/$f.$ext"));
			is($c->{format}, $plain->{format}, "$f.$ext is still read as $plain->{format}");
			is_deeply(coords($c), coords($plain),
				"$f.$ext reads the same as the file it was made from, header and all");
		}
		my $plain = structure_info("$data/mini.pdb");
		my $c     = structure_info("$dir/mini.pdb.$ext");
		is($c->{id}, '9XYZ', 'the header is read through the decompression too');

		# ---- every function that takes a file name --------------------
		# They all read it through structure_info(), so these are the
		# entry points rather than four more decompressors; what is asserted
		# is that none of them looks at the name on its own and trips over
		# the suffix.
		is_deeply(structure_info("$dir/mini.pdb.$ext", 'dssp'),
		          structure_info("$data/mini.pdb", 'dssp'),
			'a view of a compressed file is the view of the plain one');
		is_deeply(structure_info("$dir/mini.pdb.$ext", 'torsions'),
		          structure_info("$data/mini.pdb", 'torsions'),
			'the torsions view too');
		is_deeply(structure_sequences("$dir/mini.pdb.$ext"),
		          structure_sequences("$data/mini.pdb"),
			'structure_sequences() takes a compressed file name');
		is_deeply(structure_sequences("$dir/mini.pdb.$ext", waters => 0),
		          structure_sequences("$data/mini.pdb", waters => 0),
			'with options');
		is(structure_rmsd("$dir/mini.pdb.$ext", "$data/mini.pdb"), 0,
			'structure_rmsd() takes a compressed file and finds it identical to its source');
		is(structure_rmsd("$dir/mini.pdb.$ext", "$dir/mini.cif.$ext", select => 'ca'), 0,
			'and two compressed files, one of each format');
		is_deeply(structure_features(structure_info($z->("$data/stack.pdb", "$dir/stack.pdb.$ext"))),
		          structure_features(structure_info("$data/stack.pdb")),
			'the properties of a compressed file are those of the plain one');
		{
			my $e = $z->("$data/ensemble.pdb", "$dir/ensemble.pdb.$ext");
			is_deeply(coords(structure_info($e, model => 'all')),
			          coords(structure_info("$data/ensemble.pdb", model => 'all')),
				"model => 'all' over a compressed ensemble");
			is_deeply(coords(structure_info($e, model => 2)),
			          coords(structure_info("$data/ensemble.pdb", model => 2)),
				'and one model of it');
		}

		# ---- options --------------------------------------------------
		{
			my $i = structure_info("$dir/mini.pdb.$ext", waters => 0, chains => ['B']);
			is_deeply($i->{chain_order}, ['B'], 'options work on a compressed file');
			is_deeply(coords($i), coords(structure_info("$data/mini.pdb", waters => 0, chains => ['B'])),
				'and give what they give on the plain one');
		}

		# ---- the name ------------------------------------------------
		# the id falls back to the file name with both suffixes taken off
		{
			my $i = structure_info($z->("$data/bare.pdb", "$dir/1abc.ent.$ext"));
			is($i->{id}, '1ABC', "with no HEADER, the id comes from the name without .ent.$ext");
		}
		# a suffix in capitals is the same suffix
		{
			my $up = uc $ext;
			my $i = structure_info($z->("$data/mini.pdb", "$dir/upper.pdb.$up"));
			is_deeply(coords($i), coords($plain), "a .$up is unpacked as a .$ext is");
		}
		# a name that says nothing but that it is compressed: the format is
		# sniffed from the first records, which have to be unpacked to be read
		{
			my $i = structure_info($z->("$data/mini.cif", "$dir/noname.$ext"));
			is($i->{format}, 'mmcif', "a bare .$ext has its format sniffed from what is inside it");
			is_deeply(coords($i), coords(structure_info("$data/mini.cif")), 'and is read whole');
		}

		# ---- the reader underneath ------------------------------------
		# It takes a plain file as well as a compressed one, and either the
		# whole of it or the first so many bytes.  Both forms are used: the
		# whole file is how a compressed file is read, and the first 8 kB is
		# how a file whose name says nothing has its format sniffed.  Asked
		# directly because nothing else reaches the whole-file form on a
		# plain file, and a reader that quietly returned nothing there would
		# show up as an empty structure much later.
		{
			my $read  = \&Chem::Structure::Parser::_slurp_maybe_compressed;
			my $bytes = slurp("$data/mini.pdb");
			is($read->("$data/mini.pdb", undef), $bytes, 'a plain file with no limit is read whole');
			my $head = $read->("$data/mini.pdb", 64);
			is(length $head, 64, 'and with a limit it stops there');
			is($head, substr($bytes, 0, 64), 'having read the front of the file');
			is($read->("$dir/mini.pdb.$ext", undef), $bytes,
				'the compressed copy comes back byte for byte the same');
			is(substr($read->("$dir/mini.pdb.$ext", 64), 0, 64), substr($bytes, 0, 64),
				'a limited read of a compressed file stops at the first block past the limit');
		}

		# ---- what is not what it says it is ---------------------------
		# Something not compressed at all, named as though it were.
		# IO::Uncompress reads uncompressed input transparently, so this is
		# read rather than refused, which is the more useful of the two
		# answers: the file is still a structure.
		{
			spew("$dir/lying.pdb.$ext", "ATOM      1  CA  ALA A   1      10.000  10.000  10.000\n");
			my $i;
			lives_ok { $i = structure_info("$dir/lying.pdb.$ext") }
				"a plain file named .$ext is read anyway rather than refused";
			is($i->{chains}{A}{sequence}, 'A', 'and read correctly');
		}
		# A truncated stream, which is a real thing to find in a download
		# directory, is an error and not a short file.  read() returns a
		# negative number rather than undef for it, so the loop that reads
		# the archive used to take it for the 0 that means end of stream:
		# half of mini.pdb.gz came back as a structure with no atoms in it
		# and nothing said so.  Both decompressors call this 'unexpected end
		# of file', in IO-Compress 2.020 (perl 5.10.1) and 2.223 alike.
		{
			my $bytes = slurp("$dir/mini.pdb.$ext");
			spew("$dir/cut.pdb.$ext", substr($bytes, 0, int(length($bytes) / 2)));
			throws_ok { structure_info("$dir/cut.pdb.$ext") } qr/Can't read from .*cut\.pdb\.\Q$ext\E/,
				"a truncated $name file dies rather than coming back as a short file";
			throws_ok { structure_info("$dir/cut.pdb.$ext") } qr/unexpected end of file/,
				'and says what the decompressor said was wrong with it';
			# The first bytes of a header and nothing after them dies too.
			# Where it dies differs: Gunzip refuses four bytes at new() ('Header
			# Error: Minimum header size is 10 bytes') and Bunzip2 takes ten
			# and fails at the first read(), so what is asserted is that it
			# dies and names the file.
			spew("$dir/stub.pdb.$ext", $ext eq 'gz' ? "\x1f\x8b\x08\0" : "BZh91AY&SY");
			throws_ok { structure_info("$dir/stub.pdb.$ext") } qr/'[^']*stub\.pdb\.\Q$ext\E'/,
				'a stream that stops inside its own header dies too';
		}

		# ---- several streams in one file ------------------------------
		# A file of two members, which is what bgzip and pbzip2 write and
		# what `cat a.gz b.gz' makes, is one file: zcat and bzcat read every
		# member of it.  The readers stop at the end of the first unless told
		# otherwise, and mini.pdb split in two used to come back as 38 lines
		# and no atoms.
		{
			my $text = slurp("$data/mini.pdb");
			my $cut = index($text, "\nATOM") + 1;
			my ($head, $tail) = (substr($text, 0, $cut), substr($text, $cut));
			my ($one, $two) = ('', '');
			$pack->(\$head => \$one) or die $err->();
			$pack->(\$tail => \$two) or die $err->();
			spew("$dir/two.pdb.$ext", $one, $two);
			my $i = structure_info("$dir/two.pdb.$ext");
			is($i->{stats}{n_atoms}, $plain->{stats}{n_atoms},
				"a $name file of two members is read to the end of the second");
			is($i->{stats}{n_lines}, $plain->{stats}{n_lines}, 'every line of it');
		}

		# ---- a file that cannot be opened -----------------------------
		# Opened through IO::Uncompress rather than through the XS, so it has
		# a failure of its own to report.  A method's return value was never
		# autodie's job, which is why this one is checked by hand.
		SKIP: {
			my $f = "$dir/locked.pdb.$ext";
			spew($f, slurp("$dir/mini.pdb.$ext"));
			chmod 0000, $f;
			skip 'file is still readable', 2 if -r $f;
			throws_ok { structure_info($f) } qr/cannot \Q$k->{verb}\E/,
				"a $name file that cannot be opened dies";
			throws_ok { structure_info($f) } qr/locked\.pdb\.\Q$ext\E/, 'and names the file';
			chmod 0600, $f;
		}
	};
}

done_testing();
