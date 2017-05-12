#!/usr/bin/perl -w

use strict;

BEGIN	{
	$| = 1;
	eval 'use DBI 1.00';
	if ($@ ne '')
		{
		print "1..0 # SKIP No DBI module\n";
		print "DBI couldn't be loaded, aborting test\n";
		print "Error returned from eval was:\n", $@;
		exit;
		}
	print "1..9\n";
	print "DBI loaded\n";
	}

END	{ print "not ok 1\n" unless $::DBIloaded; }



### DBI->trace(2);
$::DBIloaded = 1;
print "ok 1\n";

my $dir = ( -d './t' ? 't' : '.' );

print "Unlinking write.dbf write.dbt\n";

if (-f "$dir/write.dbf")
	{ unlink "$dir/write.dbf"
		or print "Error unlinking $dir/write.dbf: $!\n"; }

print "We will make a copy of database files rooms.dbf\n";

eval "use File::Copy;";
if ($@)
	{
	print "Look's like you do not have File::Copy, we will do cp\n";
	system("cp", "$dir/rooms.dbf", "$dir/write.dbf");
	}
else
	{
	print "Will use File::Copy\n";
	copy("$dir/rooms.dbf", "$dir/write.dbf");
	}

unless (-f "$dir/write.dbf")
	{ print "not ok 2\n"; exit; }	# Does not make sense to continue

print "ok 2\n";

print "Connect to dbi:XBase:$dir\n";
my $dbh = DBI->connect("dbi:XBase:$dir") or do
	{
	print $DBI::errstr;
	print "not ok 3\n";
	exit;
	};
print "ok 3\n";

my $command = 'insert into write values ("new room", "new facility")';
print "Prepare command `$command'\n";
my $sth = $dbh->prepare($command) or do
	{
	print $dbh->errstr();
	print "not ok 4\n";
	exit;
	};
print "ok 4\n";

print "Execute it\n";
$sth->execute() or do
	{
	print $sth->errstr();
	print "not ok 5\n";
	exit;
	};
print "ok 5\n";


$command = 'insert into write ( facility ) values ("Lights")';
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or do
	{
	print $dbh->errstr();
	print "not ok 6\n";
	exit;
	};
print "ok 6\n";

print "Execute it\n";
$sth->execute() or do
	{
	print $sth->errstr();
	print "not ok 7\n";
	exit;
	};
print "ok 7\n";

print "And now we should check if it worked\n";
my $selcom = 'select * from write';
print "Prepare and execute '$selcom'\n";

my $select = $dbh->prepare($selcom) or do
	{
	print $dbh->errstr();
	print "not ok 8\n";
	exit;
	};
$select->execute() or do
	{
	print $select->errstr();
	print "not ok 8\n";
	exit;
	};
print "ok 8\n";

my $result = '';

my @data;
while (@data = $select->fetchrow_array())
	{ $result .= "@data\n"; }


my $expected_result = join '', <DATA>;

if ($result ne $expected_result)
	{
	print "Expected:\n$expected_result";
	print "Got:\n$result";
	print "not ";
	}
print "ok 9\n";

$sth->finish();

$command = 'insert into write(facility,roomname) values (?,?)';
print "Preparing $command\n";
$sth = $dbh->prepare($command) or do {
	print $dbh->errstr();
	print "not ok 10\n";
	exit;
};
$sth->execute('krtek', 'jezek') or do {
	print $sth->errstr();
	print "not ok 11\n";
	exit;
};

my @row = $dbh->selectrow_array("select roomname,facility from write where facility = 'krtek'");
if ("@row" ne 'jezek krtek') {
	print "Expected 'jezek krtek', got '@row'\nnot ok 12\n";
}

$dbh->disconnect();

1;

__DATA__
 None 
Bay  1 Main
Bay 14 Main
Bay  2 Main
Bay  5 Main
Bay 11 Main
Bay  6 Main
Bay  3 Main
Bay  4 Main
Bay 10 Main
Bay  8 Main
Gigapix Main
Bay 12 Main
Bay 15 Main
Bay 16 Main
Bay 17 Main
Bay 18 Main
Mix A Audio
Mix B Audio
Mix C Audio
Mix D Audio
Mix E Audio
ADR-Foley Audio
Mach Rm Audio
Transfer Audio
Bay 19 Main
Dub Main
Flambe Audio
FILM 1 Film
FILM 2 Film
FILM 3 Film
SCANNING Film
Mix F Audio
Mix G Audio
Mix H Audio
BullPen Film
Celco Film
MacGrfx Main
Mix J Audio
AVID Main
BAY 7 Main
 
new room new facili
 Lights
