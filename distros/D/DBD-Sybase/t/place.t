#!perl
#
# $Id: place.t,v 1.10 2008/08/31 08:46:22 mpeppler Exp $

use lib 't';
use _test;

use strict;

use Test::More tests => 18;

BEGIN { use_ok('DBI');
        use_ok('DBD::Sybase');}


my ($Uid, $Pwd, $Srv, $Db) = _test::get_info();

my $dbh = DBI->connect("dbi:Sybase:server=$Srv;database=$Db", $Uid, $Pwd, {PrintError => 1});

plan skip_all => "No connection - did you set the user, password and server name correctly in PWD?\n"
    unless $dbh;

#plan tests => 16;

SKIP: {
    skip "?-style placeholders aren't supported with this SQL Server", 10 unless $dbh->{syb_dynamic_supported};

    my $rc;

    $rc = $dbh->do("create table #t(string varchar(20), date datetime, val float, other_val numeric(9,3))");
    ok($rc, 'Create table');

    my $sth = $dbh->prepare("insert #t values(?, ?, ?, ?)");
    ok($sth, 'prepare');
    
    $rc = $sth->execute("test", "Jan 3 1998", 123.4, 222.3334);
    ok($rc, 'insert 1');

    ok $sth->bind_param(1, "other test");
    ok $sth->bind_param(2, "Jan 25 1998");
    # the order of these two bind_param's is swapped on purpose
    ok $sth->bind_param(4, 2);
    ok $sth->bind_param(3, 4445123.4);
    $rc = $sth->execute();
    ok($rc, 'insert 2');

    do {
        local $sth->{PrintError} = 0;
        $rc = $sth->execute("test", "Feb 30 1998", 123.4, 222.3334);
    };
    ok(!$rc, 'insert 3 (fail)');

    $sth = $dbh->prepare("select * from #t where date > ? and val > ?");
    ok($sth, 'prepare 2');

    $rc = $sth->execute('Jan 1 1998', 120);
    ok($rc, 'select');

    my $rows = $sth->fetchall_arrayref;
    is(@$rows, 2, 'fetch count');
    is_deeply [
        [ 'test', 'Jan  3 1998 12:00AM', '123.4', '222.333' ],
        [ 'other test', 'Jan 25 1998 12:00AM', '4445123.4', '2.000' ]
    ], $rows;


    ok $sth->execute('Jan 1 1998', 140);
    $rows = $sth->fetchall_arrayref;
    is(@$rows, 1, 'fetch 2');
    is_deeply [
        [ 'other test', 'Jan 25 1998 12:00AM', '4445123.4', '2.000' ]
    ], $rows;

}
$dbh->disconnect;

exit(0);
