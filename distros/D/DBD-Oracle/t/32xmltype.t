#!/usr/bin/perl

use strict;
use Test::More;
use DBD::Oracle qw(:ora_types);
use DBI;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

## ----------------------------------------------------------------------------
## 03xmlype.t
## By John Scoles, The Pythian Group
## ----------------------------------------------------------------------------
##  Just a few checks to see if one can insert small and large xml files
##  Nothing fancy.
## ----------------------------------------------------------------------------

# create a database handle
my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my $dbh;

eval {$dbh = DBI->connect($dsn, $dbuser, '', { RaiseError=>1,
                                               AutoCommit=>1,
                                               PrintError => 0 })};

if ($dbh) {
    plan skip_all => "XMLTYPE new in Oracle 9"
        if $dbh->func('ora_server_version')->[0] < 9;
    plan tests => 3;
} else {
    plan skip_all => "Unable to connect to Oracle"
}
# check that our db handle is good
isa_ok($dbh, "DBI::db");



my $table = table();
eval { $dbh->do("DROP TABLE $table") };

$dbh->do(qq{
	CREATE TABLE $table (
	    id INTEGER NOT NULL,
	    XML_DATA	XMLTYPE
	)
    });

my ($stmt, $sth);
my $small_xml="<books>";
my $large_xml="<books>";
my $i=0;

for ($i=0;$i<=10;$i++){
  $small_xml=$small_xml."<book id='".$i."'><title>the book ".$i." title</title></book>";
}

$small_xml=$small_xml."</books>";

for ($i=0;$i<=10000;$i++){
  $large_xml=$large_xml."<book id='".$i."'><title>the book ".$i." title</title></book>";
}

$large_xml=$large_xml."</books>";

$stmt = "INSERT INTO ".$table." VALUES (1,?)";

$sth =$dbh-> prepare($stmt);

$sth-> bind_param(1, $small_xml, { ora_type => ORA_XMLTYPE });

ok ($sth->execute(), '... execute for small XML return true');

$sth-> bind_param(1, $large_xml, { ora_type => ORA_XMLTYPE });

ok ($sth->execute(), '... execute for large XML return true');


drop_table($dbh);

$dbh->disconnect;

1;

