#!/usr/bin/perl -I./t

$| = 1;
print "1..$::tests\n";

use DBI;
use strict;

my @row;

print "ok 1\n";

my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";
print "ok 2\n";

#### testing Tim's early draft DBI methods

my $r1 = $DBI::rows;
$dbh->{AutoCommit} = 0;
my $sth;
$sth = $dbh->prepare("DELETE FROM perl_dbd_test");
$sth->execute();
print "not " unless($sth->rows >= 0 
		    && $DBI::rows == $sth->rows);
$sth->finish();
$dbh->rollback();
print "ok 3\n";

$sth = $dbh->prepare('SELECT * FROM perl_dbd_test WHERE 1 = 0');
$sth->execute();
@row = $sth->fetchrow();
if ($sth->err)
    {
    print ' $sth->err: ', $sth->err, "\n";
    print ' $sth->errstr: ', $sth->errstr, "\n";
    print ' $sth->state: ', $sth->state, "\n";
    }
$sth->finish();
print "ok 4\n";

my ($a, $b);
$sth = $dbh->prepare('SELECT A,B FROM perl_dbd_test');
$sth->execute();
while (@row = $sth->fetchrow())
    {
    print " \@row     a,b:", $row[0], ",", $row[1], "\n";
    }
$sth->finish();

$sth->execute();
$sth->bind_col(1, \$a);
$sth->bind_col(2, \$b);
while ($sth->fetch())
    {
    print " bind_col a,b:", $a, ",", $b, "\n";
    unless (defined($a) && defined($b))
    	{
	print "not ";
	last;
	}
    }
print "ok 5\n";
$sth->finish();

($a, $b) = (undef, undef);
$sth->execute();
$sth->bind_columns(undef, \$b, \$a);
while ($sth->fetch())
    {
    print " bind_columns a,b:", $b, ",", $a, "\n";
    unless (defined($a) && defined($b))
    	{
	print "not ";
	last;
	}
    }
print "ok 6\n";

$sth->finish();

# turn off error warnings.  We expect one here (invalid transaction state)
$dbh->{RaiseError} = 0;
$dbh->{PrintError} = 0;
my $errExpected = ($dbh->{ImplementorClass} ne "DBD::Adabas::db");
$dbh->disconnect();

# make sure there is an invalid transaction state error at the end here.
# (XXX not reliable, iodbc-2.12 with "INTERSOLV dBase IV ODBC Driver" == -1)
#print "# DBI::err=$DBI::err\nnot " if $DBI::err ne "25000";
#print "ok 7\n"; 

BEGIN { $::tests = 6; }
