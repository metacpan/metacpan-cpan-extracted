#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O ne 'MSWin32' and $ENV{ADAMK_RELEASE} ) {
		# Special magic to get past ADAMK's release automation
		plan( skip_all => "Skipping on ADAMK's release automation" );
	} else {
		plan( tests => 15 );
	}
}
use File::Spec::Functions ':ALL';
use File::Remove          'clear';
use Alien::Win32::LZMA    ();

my $input = catfile('t', '02_main.t');
my $small = catfile('t', 'small');
my $big   = catfile('t', 'big');
clear($small, $big);
ok(   -f $input, 'Input file exists'                );
ok( ! -f $small, 'Compressed file does not exist'   );
ok( ! -f $big,   'Decompressed file does not exist' );





#####################################################################
# Basic Functions

# Find the lzma.exe program
my $bin = Alien::Win32::LZMA->lzma_exe;
ok( -f $bin, 'Found lzma.exe' );
is(
	Alien::Win32::LZMA::lzma_exe(),
	$bin,
	'Can call lzma_exe as a function'
);

# Confirm it runs
my $stdout = '';
my $stderr = '';
my $result = IPC::Run3::run3(
	[ $bin ],
	\undef,
	\$stdout,
	\$stderr,
);
ok( $result, 'Ran lzma.exe ok' );
is( $stdout, '', 'STDOUT was empty' );
my $header = quotemeta('LZMA 4.65 : Igor Pavlov : Public domain : 2009-02-03');
like( $stderr, qr/$header/, 'lzma.exe output and version match expected values' );

# Check the lzma_version function
my $version = Alien::Win32::LZMA->lzma_version;
is( $version, 4.65, 'Found LZMA version 4.65 as expected' );





#####################################################################
# Test Compression and Decompression

ok(
	Alien::Win32::LZMA::lzma_compress( $input => $small ),
	'lzma_compress ok'
);
ok( -f $small, "lzma_compress created $small" );
ok(
	(stat($input))[7] > (stat($small))[7],
	'Compressed file is smaller',
);
ok(
	Alien::Win32::LZMA::lzma_decompress( $small => $big ),
	'lzma_decompress ok',
);
ok( -f $big, "lzma_decompress created $big" );
is(
	(stat($input))[7],
	(stat($big))[7],
	'Decompressed file matches input file',
);
