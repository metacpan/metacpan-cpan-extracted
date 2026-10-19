#!/usr/bin/env perl
# file2string(): slurp a whole file into one scalar.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Spec;
use File::Temp qw(tempfile tempdir);
use Cn::Util;

my ($fh, $path) = tempfile( UNLINK => 1 );
print $fh "line1\nline2\nno-final-newline-either";
close $fh;

my $content = file2string($path);
is( $content, "line1\nline2\nno-final-newline-either",
	'slurps the entire file including embedded newlines' );

# Empty file slurps to an empty string.
my ($efh, $epath) = tempfile( UNLINK => 1 );
close $efh;
is( file2string($epath), '', 'empty file yields empty string' );

# A missing file is fatal: file2string() checks its own open.
my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'missing.txt');
throws_ok { file2string($missing) }
	qr/can't read \Q$missing\E/, 'missing file is fatal, and named';

done_testing;
