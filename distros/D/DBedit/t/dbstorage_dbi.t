#!/usr/bin/perl -w

use lib "/var/www/lib";
use DBI;
use DBstorage::DBI;
use Test::Simple tests=>4;
use strict;

`createdb testDBI`;

my ($dbh) = DBstorage::DBI->new('dbi:Pg:dbname=testDBI');

$dbh->create("testtable", {"id"=>"int4", "result"=>"text"});
$dbh->append("testtable", {"id"=>"1", "result"=>"roo"});
$dbh->append("testtable", {"id"=>"2", "result"=>"voo"});
my (%found) = ();
$dbh->find("testtable", {"id"=>"1"}, \%found);
ok ($found{'result'} eq "roo");
$dbh->find("testtable", {"result"=>"roo"}, \%found);
ok ($found{'id'} eq "1");

$dbh->find("select * from testtable", {"result"=>"roo"}, \%found);
ok ($found{'id'} eq "1");


$dbh->replace("testtable", {"id"=>"1"}, {"result"=>"foo"});
$dbh->find("testtable", {"id"=>"1"}, \%found);
ok ($found{'result'} eq "foo"); 

undef($dbh);

`dropdb testDBI`;
