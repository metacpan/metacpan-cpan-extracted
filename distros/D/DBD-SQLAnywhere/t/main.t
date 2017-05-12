#!/usr/local/bin/perl
#
# $Id: main.t,v 1.4 1998/05/20 22:38:54 mpeppler Exp $

# Base DBD Driver Test

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

my $switch = DBI->internal;
#DBI->trace(2); # 2=detailed handle trace
note( "Switch: $switch->{'Attribution'}, $switch->{'Version'}\n" );
note( "Available Drivers: ",join(", ",DBI->available_drivers()),"\n" );

my $dbh;
eval {
    $dbh = DBI->connect("DBI:SQLAnywhere:UID=dba;PWD=sql;ENG=demo;DBF=demo.db", '', '', {PrintError => 0});
};
if( $@ ) {
    plan( skip_all => 'SQL Anywhere dbcapi library is not installed' );
    exit( 0 );
}
if( !$dbh ) {
    plan( skip_all => 'demo.db is not accessible' );
    exit( 0 );
}

plan( tests => 10 );

ok( $dbh, 'connect' );

my $sth;

$sth = $dbh->prepare( "select * from sysusers" );
ok( $sth, 'prepare' );
ok( $sth->execute() );

my @dat;
note( "Fields: $sth->{NUM_OF_FIELDS}\n" );
note( "Names: @{$sth->{NAME}}\n" );
#note( "Null:  @{$sth->{NULLABLE}}\n" );
my $rows = 0;
while(@dat = $sth->fetchrow) {
    ++$rows;
    foreach (@dat) {
	$_ = '' unless $_;
    }
    note( "@dat\n" );
}
ok( ($rows == $sth->rows || $sth->rows < 0 ), 'rowcount' );
undef $sth;


$sth = $dbh->prepare( "select * from sys_users" );
ok( !$sth, 'prepare' );
ok( $DBI::err == -141, 'expected error code' );

$sth = $dbh->prepare( "select * from sysusers" );
ok( $sth, 'prepare' );
ok( $sth->execute(), 'execute' );

my @fields = @{$sth->{NAME}};
$rows = 0;
my $d;
my $ok = 1;

while( $d = $sth->fetchrow_hashref() ) {
    ++$rows;
    my $rstr = '';
    foreach ( @fields ) {
	if( !exists( $d->{$_} ) ) {
	    $ok = 0;
	}
	my $t = $d->{$_} || '';
	$rstr = $rstr . "$t ";
    }
    note( $rstr );
}
ok( $ok, 'reference fields by name' );
ok( ($rows == $sth->rows || $sth->rows < 0), 'rowcount' );
#    $sth->finish;
undef $sth;

$dbh->disconnect();


