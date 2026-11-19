#!/usr/bin/env perl
# file2string(): slurp a whole file into one scalar.
require 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Spec;
use File::Temp qw(tempfile tempdir);

# NetBSD's read(2) on a directory succeeds and returns its raw entries, where
# Linux fails it with EISDIR.  This override, which must be installed before
# Cn::Util is compiled, makes readline on a directory handle behave as NetBSD's
# does, so the last test below checks what CPAN Testers report
# 52217fbc-dd66-11f1-9541-8d78add113b8 (0.0241, perl 5.42.3,
# amd64-netbsd-thread-multi) saw, on every platform.  Any other handle reads
# through CORE::readline in the caller's context.
my $dir_reads = 0;
BEGIN {
	*CORE::GLOBAL::readline = sub {
		return CORE::readline($_[0]) unless -d $_[0];
		$dir_reads++;
		return "\0netbsd-dirent-bytes";
	};
}
use Cn::Util;

my ($fh, $path) = tempfile( UNLINK => 1 );
print $fh "line1\nline2\nno-final-newline-either";
close $fh;

my $content = file2string($path);
is( $content, "line1\nline2\nno-final-newline-either",
	'slurps the entire file including embedded newlines' );

# No layer translates line endings: on Windows the default layers include
# :crlf, which up to 0.0242 turned "\r\n" into "\n".
my ($cfh, $cpath) = tempfile( UNLINK => 1 );
binmode $cfh;
print $cfh "a\r\nb\r\n\x{ff}";
close $cfh;
is( file2string($cpath), "a\r\nb\r\n\x{ff}", 'bytes come back exactly, "\r\n" included' );

# Empty file slurps to an empty string.
my ($efh, $epath) = tempfile( UNLINK => 1 );
close $efh;
is( file2string($epath), '', 'empty file yields empty string' );

# A missing file is fatal: file2string() checks its own open.
my $missing = File::Spec->catfile(tempdir(CLEANUP => 1), 'missing.txt');
throws_ok { file2string($missing) }
	qr/can't read \Q$missing\E/, 'missing file is fatal, and named';

# open() succeeds on a directory on POSIX systems; 0.024 returned undef for
# it, and 0.0241 returned the directory's bytes on NetBSD.  On Windows the open
# itself fails.  file2string must refuse it before reading.
my $adir = tempdir(CLEANUP => 1);
throws_ok { file2string($adir) }
	qr/can't read \Q$adir\E/, 'a directory is fatal, and named';
is( $dir_reads, 0, 'a directory is refused before it is read' );

done_testing;
