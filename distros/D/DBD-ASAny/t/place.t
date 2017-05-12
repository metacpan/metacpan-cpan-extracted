#!/usr/local/bin/perl
#
# $Id: place.t,v 1.2 1998/05/20 22:39:01 mpeppler Exp $

use lib 'blib/lib';
use lib 'blib/arch';

BEGIN {print "1..13\n";}
END {print "not ok 1\n" unless $loaded;}
use DBI;
$loaded = 1;
print "ok 1\n";

#DBI->trace(2);

my $dbh = DBI->connect("DBI:ASAny:UID=dba;PWD=sql;ENG=asademo;DBF=asademo.db", '', '', {PrintError => 0});

die "Unable to connect to asademo: $DBI::errstr"
    unless $dbh;

my $rc;

$rc = $dbh->do("create table #t(string varchar(20), date_time datetime, val float, other_val numeric(9,3))");
$rc and print "ok 2\n"
    or print "not ok 2\n";

my $sth = $dbh->prepare("insert #t values(?, ?, ?, ?)");
$sth and print "ok 3\n"
    or print "not ok 3\n";

$rc = $sth->execute("test", "Jan 3 1998", 123.4, 222.3334);
$rc and print "ok 4\n"
    or print "not ok 4\n";

$rc = $sth->execute("other test", "Jan 25 1998", 4445123.4, 2);
$rc and print "ok 5\n"
    or print "not ok 5\n";

$rc = $sth->execute("test", "Feb 30 1998", 123.4, 222.3334);
$rc and print "not ok 6\n"
    or print "ok 6\n";

$sth = $dbh->prepare("select * from #t where date_time > ? and val > ?");
$sth and print "ok 7\n"
    or print "not ok 7\n";

$rc = $sth->execute('Jan 1 1998', 120);
$rc and print "ok 8\n"
    or print "not ok 8\n";
my $row;
my $count = 0;

while($row = $sth->fetch) {
    print "@$row\n";
    ++$count;
}

($count == 2) and print "ok 9\n"
    or print "not ok 9\n";

$sth->finish;
undef $sth;

$sth = $dbh->prepare("select * from #t where date_time > ? and val > ?");
$sth and print "ok 10\n"
    or print "not ok 10\n";

$rc = $sth->execute('Jan 1 1998', 140);
$rc and print "ok 11\n"
    or print "not ok 11\n";

print "rc: $rc\n";
#print STDERR ($DBI::err, ":\n", $sth->errstr);

$count = 0;

while($row = $sth->fetch) {
    print "@$row\n";
    ++$count;
}

($count == 1) and print "ok 12\n"
    or print "not ok 12\n";

$sth->finish;
undef $sth;

$rc = $dbh->do("drop table #t");
$rc and print "ok 13\n"
    or print "not ok 13\n";

$dbh->disconnect;

exit(0);
