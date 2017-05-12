#!/usr/bin/perl -w

use strict;

BEGIN   { $| = 1; print "1..9\n"; }
END     { print "not ok 1\n" unless $::XBaseloaded; }

$| = 1;

print "Load the module: use XBase\n";
use XBase;
$::XBaseloaded = 1;
print "ok 1\n";

my $dir = ( -d "t" ? "t" : "." );

$XBase::Base::DEBUG = 1;        # We want to see any problems

my @files = <$dir/rooms.sdbm*.*>;
if (@files) {
	print "Dropping: @files\n";
	unlink @files;
}

print "Open table $dir/rooms\n";
my $table = new XBase "$dir/rooms" or do
	{
	print XBase->errstr, "not ok 2\n";
	exit
	};
print "ok 2\n";

print "Create SDBM index room on ROOMNAME\n";
use XBase::Index;
use XBase::SDBM;
my $index = XBase::SDBM->create($table, 'room', 'ROOMNAME');
print "ok 3\n";


print "prepare_select_with_index on ROOMNAME\n";
my $cur = $table->prepare_select_with_index([ "$dir/rooms.pag", 'room' ]) or
	print $table->errstr, 'not ';
print "seems fine\n";


my $result = '';
print "Fetch all data\n";
while (my @data = $cur->fetch)
	{ $result .= "@data\n"; }

my $expected_result = '';
my $line;
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 4\n";


print "find_eq('Celco') and fetch\n";
$cur->find_eq('Celco');
$result = ''; $expected_result = '';
while (my @data = $cur->fetch())
	{ $result .= "@data\n"; }
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 5\n";

print "find_eq('Celca') and fetch (it doesn't exist, so the result should be the same)\n";
$cur->find_eq('Celca');
$result = '';
while (my @data = $cur->fetch())
	{ $result .= "@data\n"; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 6\n";


print "prepare_select_with_index on FACILITY\n";
$cur = $table->prepare_select_with_index([ "$dir/rooms.cdx", 'FACILITY' ],
		'FACILITY', 'ROOMNAME') or
	print $table->errstr, 'not ';
print "ok 7\n";

print "find_eq('Film') and fetch\n";
$cur->find_eq('Film');
$result = ''; $expected_result = '';
while (my @data = $cur->fetch())
	{ last if $data[0] ne 'Film'; $result .= "@data\n"; }
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 8\n";



print "find_eq('Main') and fetch\n";
$cur->find_eq('Main');
$result = ''; $expected_result = '';
while (my @data = $cur->fetch())
	{ last if $data[0] ne 'Main'; $result .= "@data\n"; }
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{ print "Expected:\n${expected_result}Got:\n${result}not "; }
print "ok 9\n";




__END__
 
 None 
ADR-Foley Audio
AVID Main
BAY 7 Main
Bay  1 Main
Bay  2 Main
Bay  3 Main
Bay  4 Main
Bay  5 Main
Bay  6 Main
Bay  8 Main
Bay 10 Main
Bay 11 Main
Bay 12 Main
Bay 14 Main
Bay 15 Main
Bay 16 Main
Bay 17 Main
Bay 18 Main
Bay 19 Main
BullPen Film
Celco Film
Dub Main
FILM 1 Film
FILM 2 Film
FILM 3 Film
Flambe Audio
Gigapix Main
MacGrfx Main
Mach Rm Audio
Mix A Audio
Mix B Audio
Mix C Audio
Mix D Audio
Mix E Audio
Mix F Audio
Mix G Audio
Mix H Audio
Mix J Audio
SCANNING Film
Transfer Audio
__END_DATA__
Celco Film
Dub Main
FILM 1 Film
FILM 2 Film
FILM 3 Film
Flambe Audio
Gigapix Main
MacGrfx Main
Mach Rm Audio
Mix A Audio
Mix B Audio
Mix C Audio
Mix D Audio
Mix E Audio
Mix F Audio
Mix G Audio
Mix H Audio
Mix J Audio
SCANNING Film
Transfer Audio
__END_DATA__
Film FILM 1
Film FILM 2
Film FILM 3
Film SCANNING
Film BullPen
Film Celco
__END_DATA__
Main Bay  1
Main Bay 14
Main Bay  2
Main Bay  5
Main Bay 11
Main Bay  6
Main Bay  3
Main Bay  4
Main Bay 10
Main Bay  8
Main Gigapix
Main Bay 12
Main Bay 15
Main Bay 16
Main Bay 17
Main Bay 18
Main Bay 19
Main Dub
Main MacGrfx
Main AVID
Main BAY 7
__END_DATA__
