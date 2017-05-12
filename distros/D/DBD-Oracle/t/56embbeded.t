#!perl -w

use DBI;
use DBD::Oracle qw(ORA_RSET SQLCS_NCHAR);
use strict;

use Test::More;
unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

## ----------------------------------------------------------------------------
## 56embbeded.t
## By John Scoles, The Pythian Group
## ----------------------------------------------------------------------------
##  Just a few checks to see if I can select embedded objectes with Oracle::DBD
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
    plan tests => 4;
} else {
    plan skip_all => "Unable to connect to Oracle";
}


# check that our db handle is good
isa_ok($dbh, "DBI::db");

my $table = "table_embed";
my $type = $table.'a_type';

#do not warn if already there
eval { 
  local $dbh->{PrintError} = 0;
  $dbh->do(qq{drop TABLE $table }); 
};
eval { 
  local $dbh->{PrintError} = 0;
  $dbh->do(qq{drop TYPE  $type }); 
};
$dbh->do(qq{CREATE or replace TYPE  $type as varray(10) of varchar(30) }); 

$dbh->do(qq{
	CREATE TABLE $table
	         ( aa_type		$type)
	   });
    
$dbh->do("insert into  $table  values ($type('1','2','3','4','5'))");



# simple execute
my $sth;
ok ($sth = $dbh->prepare("select * from $table"), '... Prepare should return true');
my $problems;
ok ($sth->execute(), '... Select should return true');

while (my ($a)=$sth->fetchrow()){
	$problems= scalar(@$a);
}

cmp_ok(scalar($problems), '==',5, '... we should have 5 items');


$dbh->do("drop table $table");

$dbh->do("drop type $type");

$dbh->disconnect;

1;

