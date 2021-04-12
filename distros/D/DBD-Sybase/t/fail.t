#!/usr/local/bin/perl
#
# $Id: fail.t,v 1.9 2005/10/01 13:05:13 mpeppler Exp $

use lib 'blib/lib';
use lib 'blib/arch';

use strict;

use lib 't';
use _test;

use Test::More tests=>12; #qw(no_plan);

BEGIN { use_ok('DBI');
        use_ok('DBD::Sybase');}

use vars qw($Pwd $Uid $Srv $Db);

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

my $dbh = DBI->connect("dbi:Sybase:$Srv;database=$Db", $Uid, $Pwd, {PrintError => 0, syb_flush_finish => 1});

ok(defined($dbh), 'Connect');

if(!$dbh) {
  warn "No connection - did you set the user, password and server name correctly in PWD?\n";
  for (4 .. 12) {
	  ok(0);
  }
  exit(0);
}


my $rc;
my $sth;
#DBI->trace(4);
# This test only works with Sybase - apparently MS-SQL will not compile the whole batch (the 3 sql statements)
# in one go, and therefore won't flag the error until the second SELECT is executed.
# Sybase compiles the batch in one go, and will return the error immediately.
SKIP: {
  skip 1, "Test does not work with MS-SQL" if $dbh->{syb_server_version} eq 'Unknown' || $dbh->{syb_server_version} eq 'MS-SQL';
  my $sth = $dbh->prepare("
select * from sysusers
select * from no_such_table
select * from master..sysdatabases
");
  $rc = $sth->execute;

  ok(!defined($rc), 'Missing table');
}

$sth = $dbh->prepare("select * from sysusers\n");
$rc = $sth->execute;
ok(defined($rc), 'Sysusers');

while(my $d = $sth->fetch) {
  ;
}

$rc = $dbh->do("create table #test(one int not null primary key, two int not null, three int not null, check(two != three))");

ok(defined($rc), 'Create table');

SKIP: {
    skip '? placeholders not supported', 3 unless $dbh->{syb_dynamic_supported};

    $sth = $dbh->prepare("insert #test (one, two, three) values(?,?,?)");
    $rc = $sth->execute(3, 4, 5);
    ok(defined($rc), 'prepare w/placeholder');

    $rc = $sth->execute(3, 4, 5);
    ok(!defined($rc), 'execute w/placeholder');

    $rc = $sth->execute(5, 3, 3);
    ok(!defined($rc), 'execute w/placeholder');
}

$sth = $dbh->prepare("
insert #test(one, two, three) values (1, 2, 3)
insert #test(one, two, three) values (4, 5, 6)
insert #test(one, two, three) values (1, 2, 3)
insert #test(one, two, three) values (8, 9, 10)
");
$rc = $sth->execute;
ok(!defined($rc), 'prepare');

$sth = $dbh->prepare("select * from #test");
$rc = $sth->execute;
ok(defined($rc), 'select');

while(my $d = $sth->fetch) {
  print "@$d\n";
}
#print "ok 11\n";


$sth = $dbh->prepare("
insert #test(one, two, three) values (11, 12, 13)
select * from #test
insert #test(one, two, three) values (11, 12, 13)
");
$rc = $sth->execute;
ok(defined($rc), 'prepare/execute multi');
do {
  while(my $d = $sth->fetch) {
    print "@$d\n";
  }
} while($sth->{syb_more_results});

$dbh->do("drop table #test");



