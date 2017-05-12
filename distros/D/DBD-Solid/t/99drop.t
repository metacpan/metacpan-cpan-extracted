#!/usr/bin/perl -I./t

require DBI;
use testenv;

$| = 1;
print "1..$tests\n";

my ($dbh, $dsn, $user, $pass);

($dsn, $user, $pass) = soluser();

$dbh = DBI->connect($dsn, $user, $pass, {PrintError => 0})
    or exit(0);
print "ok 1\n";

my $t = 2;
foreach (qw(perl_dbd_test blob_test perl_chartest))
    {
    unless ($dbh->do("DROP TABLE $_"))
    	{
        #unless ($dbh->state eq "S0002")
        unless( $dbh->state eq '42S02' )
	    {
	    print "not ";
	    warn($dbh->errstr);
	    }
	}
    print "ok $t\n";
    ++$t;
    }
$dbh->commit() 
    or print "not ";
print "ok $t\n";

$dbh->disconnect();

BEGIN { $tests = 5; }
