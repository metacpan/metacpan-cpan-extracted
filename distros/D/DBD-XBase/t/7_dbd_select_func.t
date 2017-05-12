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
	print "1..31\n";
	print "DBI loaded\n";
	}

END	{ print "not ok 1\n" unless $::DBIloaded; }



### DBI->trace(2);
$::DBIloaded = 1;
print "ok 1\n";

my $dir = ( -d './t' ? 't' : '.' );

print "Connect to dbi:XBase:$dir\n";
my $dbh = DBI->connect("dbi:XBase:$dir", undef, undef, {'PrintError' => 1}) or do
	{
	print $DBI::errstr;
	print "not ok 2\n";
	exit;
	};
print "ok 2\n";

my $command;
my $sth;
my ($result, $expected_result);


sub compare_result {
	my ($result, $testnum) = @_;
	my $expected_result = '';
	while (<DATA>)
		{ last if /^__END_DATA__$/; $expected_result .= $_; }

	if (not $result =~ /\n$/) { $result .= "\n"; }
	if (not $expected_result =~ /\n$/) { $expected_result .= "\n"; }

	if ($result ne $expected_result)
		{ print "Expected:\n${expected_result}Got:\n${result}not "; }
	print "ok $testnum\n";
	}


$command = "select ID, MSG from test";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or print $dbh->errstr(), 'not ';
print "ok 3\n";


print "Test the NAME attribute of the sth\n";
compare_result("@{$sth->{'NAME'}}", 4);


print "Execute the command\n";
$sth->execute() or print $sth->errstr(), 'not ';
print "ok 5\n";


print "Read the data and test them\n";

$result = '';
while (my @data = $sth->fetchrow_array) { $result .= "@data\n"; }
compare_result($result, 6);


$command = "select ID cislo, ID + 1, ID - ? from test";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or print $dbh->errstr(), 'not ';
print "ok 7\n";


print "Test the NAME attribute of the sth\n";
compare_result("@{$sth->{'NAME'}}", 8);


print "Execute the command with value 5\n";
$sth->execute(5) or print $sth->errstr(), 'not ';
print "ok 9\n";


print "Read the data and test them\n";
$result = '';
while (my @data = $sth->fetchrow_array) { $result .= "@data\n"; }
compare_result($result, 10);


$command = "select 1 jedna, id, ? parametr from test where id = ?";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or print $dbh->errstr(), 'not ';
print "ok 11\n";


print "Test the NAME attribute of the sth\n";
compare_result("@{$sth->{'NAME'}}", 12);


print "Execute the command with values 8, 3\n";
$sth->execute(8, 3) or print $sth->errstr(), 'not ';
print "ok 13\n";


print "Read the data and test them\n";
$result = '';
while (my @data = $sth->fetchrow_array) { $result .= "@data\n"; }
compare_result($result, 14);


### $ENV{'SQL_DUMPER'} = 1;

$command = "select id, length(msg), msg txt from test where id < ?";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or print $dbh->errstr(), 'not ';
print "ok 15\n";


print "Test the NAME attribute of the sth\n";
compare_result("@{$sth->{'NAME'}}", 16);


print "Execute the command with value 4\n";
$sth->execute(4) or print $sth->errstr(), 'not ';
print "ok 17\n";


print "Read the data and test them\n";
$result = '';
while (my @data = $sth->fetchrow_array) { $result .= "@data\n"; }
compare_result($result, 18);


print "Execute the command with value 16\n";
$sth->execute(16) or print $sth->errstr(), 'not ';
print "ok 19\n";


print "Read the data and test them (note that with bind params, it's string)\n";
$result = '';
while (my @data = $sth->fetchrow_array) { $result .= "@data\n"; }
compare_result($result, 20);




$command = "select (id + 5) || msg str, msg || ' datum ' || dates from test";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or print $dbh->errstr(), 'not ';
print "ok 21\n";


print "Test the NAME attribute of the sth\n";
compare_result("@{$sth->{'NAME'}}", 22);


print "Execute the command\n";
$sth->execute() or print $sth->errstr(), 'not ';
print "ok 23\n";


print "Read the data and test them\n";
$result = '';
while (my @data = $sth->fetchrow_array) { $result .= "@data\n"; }
compare_result($result, 24);


$command = "select concat(45, ' jezek', '-krtek') from test where id = 1";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or print $dbh->errstr(), 'not ';
print "ok 25\n";


print "Execute the command\n";
$sth->execute() or print $sth->errstr(), 'not ';
print "ok 26\n";


print "Read the data and test them\n";
$result = '';
while (my @data = $sth->fetchrow_array) { $result .= "@data\n"; }
compare_result($result, 27);


$command = "select substr('jezek leze', 3, 7) cast,
	substring(trim('   krtek '), 0, 3) from test where id = 1";
print "Prepare command `$command'\n";
$sth = $dbh->prepare($command) or print $dbh->errstr(), 'not ';
print "ok 28\n";


print "Test the NAME attribute of the sth\n";
compare_result("@{$sth->{'NAME'}}", 29);


print "Execute the command\n";
$sth->execute() or print $sth->errstr(), 'not ';
print "ok 30\n";


print "Read the data and test them\n";
$result = '';
while (my @data = $sth->fetchrow_array) { $result .= "@data\n"; }
compare_result($result, 31);


$sth->finish();
$dbh->disconnect();

1;

__DATA__
ID MSG
__END_DATA__
1 Record no 1
3 Message no 3
__END_DATA__
cislo ID+1 ID-?
__END_DATA__
1 2 -4
3 4 -2
__END_DATA__
jedna ID parametr
__END_DATA__
1 3 8
__END_DATA__
ID LENGTH(MSG) txt
__END_DATA__
1 11 Record no 1
3 12 Message no 3
__END_DATA__
1 11 Record no 1
__END_DATA__
str MSG||' DATUM '||DATES
__END_DATA__
6Record no 1 Record no 1 datum 19960813
8Message no 3 Message no 3 datum 19960102
__END_DATA__
45 jezek-krtek
__END_DATA__
cast SUBSTRING(TRIM('   KRTEK '),0,3)
__END_DATA__
zek lez krt
__END_DATA__


