#!/usr/local/bin/perl
#
# $Id: place.t,v 1.2 1998/05/20 22:39:01 mpeppler Exp $

# This sample program contains a hard-coded userid and password
# to connect to the demo database. This is done to simplify the
# sample program. The use of hard-coded passwords is strongly
# discouraged in production code.  A best practice for production
# code would be to prompt the user for the userid and password.

use lib 'blib/lib';
use lib 'blib/arch';
use strict;
use DBI;
use Test::More;

#DBI->trace(2);

my $dbh;
eval {
    $dbh = DBI->connect( "DBI:SQLAnywhere:UID=dba;PWD=sql;ENG=demo;DBF=demo.db", '', '', {PrintError => 0});
};
if( $@ ) {
    plan( skip_all => 'SQL Anywhere dbcapi library is not installed' );
    exit( 0 );
}
if( !$dbh ) {
    plan( skip_all => 'demo.db is not accessible' );
    exit( 0 );
}

plan( tests => 12 );
my $sth;
ok( $dbh->do( "create table #t(string varchar(20), date_time datetime, val float, other_val numeric(9,3))"), 'do( create table )' );
ok( $sth = $dbh->prepare( "insert #t values(?, ?, ?, ?)" ), 'prepare insert' );
ok( $sth->execute( "test", "Jan 3 1998", 123.4, 222.3334 ), 'execute1' );
ok( $sth->execute( "other test", "Jan 25 1998", 4445123.4, 2 ), 'execute2' );
ok( !$sth->execute( "test", "Feb 30 1998", 123.4, 222.3334 ), 'execute3' );

ok( $sth = $dbh->prepare( "select * from #t where date_time > ? and val > ?"), 'prepare select with hostvars' );
ok( $sth->execute( 'Jan 1 1998', 120 ), 'execute' );

my $row;
my $count = 0;

while( $row = $sth->fetch ) {
    note( "@$row\n" );
    ++$count;
}

ok( ($count == 2), 'rowcount' );

$sth->finish;
undef $sth;

ok( $sth = $dbh->prepare( "select * from #t where date_time > ? and val > ?" ), 'prepare select with hostvars' );;
ok( $sth->execute( 'Jan 1 1998', 140 ), 'execute' );

$count = 0;
while($row = $sth->fetch) {
    note( "@$row\n" );
    ++$count;
}
ok( ($count == 1), 'rowcount' );

$sth->finish;
undef $sth;

ok( $dbh->do( "drop table #t" ), 'drop table' );

$dbh->disconnect();

exit( 0 );
