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
	print "1..10\n";
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
unless ($@) 
	{
	print "Will use File::Copy\n";
	copy("$dir/rooms.dbf", "$dir/write.dbf");
	}
else
	{
	print "Look's like you do not have File::Copy, we will do cp\n";
	system("cp", "$dir/rooms.dbf", "$dir/write.dbf");
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

my $command = 'update write set roomname = "ABC" where facility != "Audio"';
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
$sth->finish();
print "ok 5\n";

print "And now we should check if it worked\n";
my $selcom = 'select * from write';
print "Prepare and execute '$selcom'\n";

my $select = $dbh->prepare($selcom) or do
	{
	print $dbh->errstr();
	print "not ok 6\n";
	exit;
	};
$select->execute() or do
	{
	print $select->errstr();
	print "not ok 6\n";
	exit;
	};
print "ok 6\n";

my $result = '';

my @data;
while (@data = $select->fetchrow_array())
	{ $result .= "@data\n"; }


my $expected_result = '';
my $line;
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result ne $expected_result)
	{
	print "Expected:\n$expected_result";
	print "Got:\n$result";
	print "not ";
	}
print "ok 7\n";


my $bindupdate = 'update write set roomname = ?, facility = ? where facility = ? and roomname = ?';
print "Now prepare update with bind parameters\nCommand: $bindupdate\n";
my $sth2 = $dbh->prepare($bindupdate) or print $dbh->errstr(), 'not ';
print "ok 8\n";

print "Execute it with 'Jezek', 'Krtek', 'Film', 'ABC'\n";
$sth2->execute('Jezek', 'Krtek', 'Film', 'ABC') or print $sth2->errstr(), 'not ';
print "ok 9\n";


print "Now check the result back\n";
my $select2 = $dbh->prepare('select * from write');
$select2->execute();
my $result2 = join '', map { "@$_\n" } @{ $select2->fetchall_arrayref };

$expected_result = '';
while (defined($line = <DATA>))
	{ last if $line eq "__END_DATA__\n"; $expected_result .= $line; }

if ($result2 ne $expected_result)
	{
	print "Expected:\n$expected_result";
	print "Got:\n$result2";
	print "not ";
	}
print "ok 10\n";

$dbh->disconnect();

1;

__DATA__
ABC 
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
Mix A Audio
Mix B Audio
Mix C Audio
Mix D Audio
Mix E Audio
ADR-Foley Audio
Mach Rm Audio
Transfer Audio
ABC Main
ABC Main
Flambe Audio
ABC Film
ABC Film
ABC Film
ABC Film
Mix F Audio
Mix G Audio
Mix H Audio
ABC Film
ABC Film
ABC Main
Mix J Audio
ABC Main
ABC Main
ABC 
__END_DATA__
ABC 
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
ABC Main
Mix A Audio
Mix B Audio
Mix C Audio
Mix D Audio
Mix E Audio
ADR-Foley Audio
Mach Rm Audio
Transfer Audio
ABC Main
ABC Main
Flambe Audio
Jezek Krtek
Jezek Krtek
Jezek Krtek
Jezek Krtek
Mix F Audio
Mix G Audio
Mix H Audio
Jezek Krtek
Jezek Krtek
ABC Main
Mix J Audio
ABC Main
ABC Main
ABC 
