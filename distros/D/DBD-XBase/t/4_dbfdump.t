#!/usr/bin/perl -w

use strict;

BEGIN	{ $| = 1; print "1..2\n"; }

my $dir = ( -d "t" ? "." : ".." );

use ExtUtils::testlib;
my $libs = join " -I", '', @INC;

my $dbfdump = "$dir/blib/script/dbfdump";

my $expected = join '', <DATA>;
my $result = '';

my $command = qq!$^X $libs $dbfdump "$dir/t/rooms.dbf"!;
print "Running dbfdump rooms.dbf: $command\n";
$result = `$command`;

if ($result ne $expected)
	{ print "Got\n$result\nExpected\n$expected\nwhich is not OK\nnot "; }
print "ok 1\n";

$command = qq!$^X $libs $dbfdump -- - < "$dir/t/rooms.dbf"!;
print "Running stdin dbfdump < rooms.dbf: $command\n";
$result = `$command`;

if ($result ne $expected)
	{ print "Got\n$result\nwhich is not OK\nnot "; }
print "ok 2\n";


1;

__DATA__
 None:
Bay  1:Main
Bay 14:Main
Bay  2:Main
Bay  5:Main
Bay 11:Main
Bay  6:Main
Bay  3:Main
Bay  4:Main
Bay 10:Main
Bay  8:Main
Gigapix:Main
Bay 12:Main
Bay 15:Main
Bay 16:Main
Bay 17:Main
Bay 18:Main
Mix A:Audio
Mix B:Audio
Mix C:Audio
Mix D:Audio
Mix E:Audio
ADR-Foley:Audio
Mach Rm:Audio
Transfer:Audio
Bay 19:Main
Dub:Main
Flambe:Audio
FILM 1:Film
FILM 2:Film
FILM 3:Film
SCANNING:Film
Mix F:Audio
Mix G:Audio
Mix H:Audio
BullPen:Film
Celco:Film
MacGrfx:Main
Mix J:Audio
AVID:Main
BAY 7:Main
:
