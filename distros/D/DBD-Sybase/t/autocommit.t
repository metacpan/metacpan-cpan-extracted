#!/usr/bin/perl
#
# $Id: autocommit.t,v 1.6 2005/10/01 13:05:13 mpeppler Exp $

use lib 'blib/lib';
use lib 'blib/arch';

use lib 't';

use _test;

use strict;

use Test::More tests => 9;
#use Test::More qw(no_plan);

BEGIN { use_ok('DBI');
        use_ok('DBD::Sybase');}

use vars qw($Pwd $Uid $Srv $Db);


#DBI->trace(2);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

my $dbh = DBI->connect("dbi:Sybase:$Srv;database=$Db", $Uid, $Pwd, {PrintError => 0});

ok(defined($dbh), 'Connect');

if(!$dbh) {
    warn "No connection - did you set the user, password and server name correctly in PWD?\n";
    for (4 .. 11) {
	ok(0);
    }
    exit(0);
}

$dbh->do("create table #ttt (foo varchar(20), bar int)");
$dbh->{AutoCommit} = 0;

$dbh->do("insert #ttt values('a string', 1)");
$dbh->do("insert #ttt values('another string', 2)");
$dbh->do("insert #ttt values('foodiboo', 3)");
$dbh->do("insert #ttt values('a string', 4)");
$dbh->rollback;
my $sth = $dbh->prepare("select * from #ttt");
$sth->execute;
my $found = 0;
while(my $d = $sth->fetch) {
    print "@$d\n";
    ++$found;
}
ok(!$found, 'rollback');

$dbh->do("insert #ttt values('a string', 1)");
$dbh->do("insert #ttt values('another string', 2)");
$dbh->do("insert #ttt values('foodiboo', 3)");
$dbh->do("insert #ttt values('a string', 4)");
$dbh->commit;

$sth = $dbh->prepare("select * from #ttt");
$sth->execute;
$found = 0;
while(my $d = $sth->fetch) {
    print "@$d\n";
    ++$found;
}
ok($found == 4, 'Commit');

# Add some tests to validate the begin_work() functionality
$dbh->{AutoCommit} = 1;

$dbh->begin_work;
$dbh->do("insert #ttt values('a string', 1)");
$dbh->do("insert #ttt values('another string', 2)");
$dbh->do("insert #ttt values('foodiboo', 3)");
$dbh->do("insert #ttt values('a string', 4)");
$dbh->commit;
ok($dbh->{AutoCommit} == 1, "begin_work");

# Test to check for problems with non-chained mode.
$dbh->{syb_chained_txn} = 0;
$dbh->{AutoCommit} = 0;
$sth = $dbh->prepare("select 5");
ok($sth, "Non-chained prepare");
my $rc = $sth->finish;
ok($rc, "Finish");
$rc = $dbh->commit;
ok($rc, "commit");

$dbh->disconnect;


