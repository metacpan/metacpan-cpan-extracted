#!/usr/bin/perl -I. -I./t
$| = 1;
print "1..$tests\n";

require DBI;
use testenv;

my ($dsn, $user, $pass) = soluser();

print "ok 1\n";

print " Test 2: connecting to the database\n";
my $dbh = DBI->connect($dsn, $user, $pass);
unless($dbh)
    {
    warn($DBI::errstr);
    exit(0);
    }
print "ok 2\n";


#### testing a simple select

print " Test 3: check existance of test table\n";
my $rc = tab_exists($dbh);
print "not " unless($rc >= 0);
print "ok 3\n";

print " Test 4: create or delete test table\n";
unless($rc)
    {
    $rc = tab_create($dbh);
    }
else
    {
    $rc = tab_delete($dbh);
    }

print "not " unless($rc);
print "ok 4\n";

print " Test 5: insert test data\n";
my @data = 
    ( [ 1, 'foo', 'foo varchar' ],
      [ 2, 'bar', 'bar varchar' ],
    );
$rc = tab_insert($dbh, \@data);
print "not " unless($rc);
print "ok 5\n";

print " Test 6: select test data\n";
$rc = tab_select($dbh, \@data);
print "not " unless($rc);
print "ok 6\n";

BEGIN {$tests = 6;}
exit(0);

sub tab_select
    {
    my $dbh = shift;
    my $dref = shift;
    my @data = @{$dref};
    my @row;

    my $sth = $dbh->prepare("SELECT * FROM perl_dbd_test")
    	or return undef;
    $sth->execute();
    while (@row = $sth->fetchrow())
    	{
	print "$row[0]|$row[1]|$row[2]|\n";
	}
    $sth->finish();
    return 1;
    }

sub tab_insert {
    my $dbh = shift;
    my $dref = shift;
    my @data = @{$dref};
    my $sth = $dbh->prepare(<<"/");
INSERT INTO perl_dbd_test(a, b, c)
VALUES (:1, :2, :3)
/
    unless ($sth)
    	{
	print STDERR $DBI::errstr, "\n";
	return 0;
	}

    foreach (@data)
        {
	unless ($sth->execute(@{$_}))
	    {
	    print STDERR $DBI::errstr, "\n";
	    return 0;
	    }
	$sth->finish();
	}
    unless ($dbh->commit())
        {
	print STDERR $DBI::errstr, "\n";
	return 0;
	}
1;
}

sub tab_create {
    $dbh->do(<<"/");
CREATE TABLE perl_dbd_test (
    A INTEGER,
    B CHAR(20),
    C VARCHAR(100))
/
    }
sub tab_delete {
    $dbh->do(<<"/");
DELETE FROM perl_dbd_test
/
    }

sub tab_exists {
    my $dbh = shift;
    my (@rows, @row, $rc);

    $rc = 0;

    my $sth = $dbh->prepare(<<"/");
SELECT 1
  FROM tables
 WHERE table_name = 'PERL_DBD_TEST'
/
    unless($sth) {
	print STDERR $DBI::errstr, "\n";
	return -1;
	}
    unless($sth->execute()) { 
	print STDERR $DBI::errstr, "\n";
    	$sth->finish(); 
	return -1; 
	}
    if (@row = $sth->fetchrow())
    	{
	$rc = $row[0];
	}
    if ($dbh->err) {
	print ' $dbh->err:', $dbh->err, "\n";
	print ' $dbh->errstr:', $dbh->errstr, "\n";
	print ' $dbh->state:', $dbh->state, "\n";
	if ($sth->err < 0)
	    {
    	    $sth->finish(); 
	    return -1;
	    }
	}
    unless ($sth->finish()) {
	print STDERR $DBI::errstr, "\n";
	return -1;
	}
    print " tab_exists() returns '$rc'\n";
    $rc;
    }
__END__

if ($sth && $sth->execute())
    {
    @row = $sth->execute();
    
    while (@row = $sth->execute())
	{
	push(@rows, [ @row ]);
	}
    print "not ok 3" if ($DBI::errstr);
    $sth->finish() || print "not ok 3";
    }
else
    {
    print "not ok 3\n";
    }

my $sth = $dbh->prepare(<<"/");
CREATE TABLE perl_dbd_test(
	A integer,
	B char(20),
	C timestamp)
/
print STDERR $DBI::errstr unless($sth);


BEGIN {$tests = 3;}
exit(0);

__END__
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):




$DBI::dbi_debug = 2;
my $dbh = DBI->connect('', 'system', 'manager', 'Solid');
print STDERR $DBI::errstr, "\n" unless $dbh;
print "not " unless $dbh;
print "ok 2\n";


my $sth = $dbh->prepare('select table_name, table_type from tables');
print STDERR $DBI::errstr, "\n" unless $sth;
print "not " unless $sth;
print "ok 3\n";

my $h = $sth->execute();
print STDERR $DBI::errstr, "\n" unless $h;
print "not " unless $h;
print "ok 4\n";

my @row;
my $rc = 0;
while ((@row = $sth->fetchrow()) && $rc < 3)
    {
    print $DBI::errstr, "\n" if ($DBI::errstr); 
    print $row[0], " ", $row[1], "\n";
    $rc++;
    }

$sth->finish();

$sth = $dbh->prepare(<<"/");
select table_name from tables
where table_type = :1
  and table_schema = :2
/
print $DBI::errstr, "\n" unless($sth);

$rc = $sth->execute('BASE TABLE', 'TOM');
print $DBI::errstr, "\n" unless($rc);

while (@row = $sth->fetchrow())
    {
    print $row[0], " ", $row[1], "\n";
    }
print $DBI::errstr, "\n" if ($DBI::errstr); 
$sth->finish();
$dbh->disconnect();

$dbh=DBI->connect('', 'tom', 'pinga', 'Solid');

print "TESTING integer parameter\n";

$sth = $dbh->prepare('select a,b from nix where a = :1');
print $DBI::errstr, "\n" unless($sth);

$rc = $sth->execute('1');
print $DBI::errstr, "\n" unless($rc);

while (@row = $sth->fetchrow())
    {
    print $row[0], " ", $row[1], "\n";
    }
print $DBI::errstr, "\n" if ($DBI::errstr); 
$sth->finish();


$dbh->disconnect();
