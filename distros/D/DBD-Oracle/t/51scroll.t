#!/usr/bin/perl

use strict;
use Test::More;
use DBD::Oracle qw(:ora_types :ora_fetch_orient :ora_exe_modes);
use DBI;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

## ----------------------------------------------------------------------------
## 51scroll.t
## By John Scoles, The Pythian Group
## ----------------------------------------------------------------------------
##  Just a few checks to see if one can use a scrolling cursor
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
    plan skip_all => "Scrollable cursors new in Oracle 9"
        if $dbh->func('ora_server_version')->[0] < 9;
    plan tests => 37;
} else {
    plan skip_all => "Unable to connect to Oracle";
}
ok ($dbh->{RowCacheSize} = 10);

# check that our db handle is good
isa_ok($dbh, "DBI::db");

my $table = table();


$dbh->do(qq{
	CREATE TABLE $table (
	    id INTEGER )
    });


my ($sql, $sth,$value);
my $i=0;
$sql = "INSERT INTO ".$table." VALUES (?)";

$sth =$dbh-> prepare($sql);

$sth->execute($_) foreach (1..10);

$sql="select * from ".$table;
ok($sth=$dbh->prepare($sql,
                      {ora_exe_mode=>OCI_STMT_SCROLLABLE_READONLY,
                       ora_prefetch_memory=>200}));
ok ($sth->execute());

#first loop all the way forward with OCI_FETCH_NEXT
foreach (1..10) {
   $value =  $sth->ora_fetch_scroll(OCI_FETCH_NEXT,0);
   is($value->[0], $_, '... we should get the next record');
}
$value =  $sth->ora_fetch_scroll(OCI_FETCH_CURRENT,0);
cmp_ok($value->[0], '==', 10, '... we should get the 10th record');

# fetch off the end of the result-set
$value = $sth->ora_fetch_scroll(OCI_FETCH_NEXT, 0);
is($value, undef, "end of result-set");

#now loop all the way back
for($i=1;$i<=9;$i++){
   $value =  $sth->ora_fetch_scroll(OCI_FETCH_PRIOR,0);
   cmp_ok($value->[0], '==', 10-$i, '... we should get the prior record');
}

#now +4 records relative from the present position of 0;

$value =  $sth->ora_fetch_scroll(OCI_FETCH_RELATIVE,4);
cmp_ok($value->[0], '==', 5, '... we should get the 5th record');

#now +2 records relative from the present position of 4;

$value =  $sth->ora_fetch_scroll(OCI_FETCH_RELATIVE,2);
cmp_ok($value->[0], '==', 7, '... we should get the 7th record');

#now -3 records relative from the present position of 6;

$value =  $sth->ora_fetch_scroll(OCI_FETCH_RELATIVE,-3);

cmp_ok($value->[0], '==', 4, '... we should get the 4th record');

#now get the 9th record from the start
$value =  $sth->ora_fetch_scroll(OCI_FETCH_ABSOLUTE,9);

cmp_ok($value->[0], '==', 9, '... we should get the 9th record');

#now get the last record

$value =  $sth->ora_fetch_scroll(OCI_FETCH_LAST,0);

cmp_ok($value->[0], '==', 10, '... we should get the 10th record');

#now get the ora_scroll_position

cmp_ok($sth->ora_scroll_position(), '==', 10, '... we should get the 10 for the ora_scroll_position');

#now back to the first

$value =  $sth->ora_fetch_scroll(OCI_FETCH_FIRST,0);
cmp_ok($value->[0], '==', 1, '... we should get the 1st record');

#check the ora_scroll_position one more time

cmp_ok($sth->ora_scroll_position(), '==', 1, '... we should get the 1 for the ora_scroll_position');

# rt 76695 - fetch after fetch scroll maintains offset
# now fetch forward 2 places then just call fetch
# it should give us the 4th rcord and not the 5th

$value =  $sth->ora_fetch_scroll(OCI_FETCH_RELATIVE,2);
is($value->[0], 3, '... we should get the 3rd record rt76695');
($value) = $sth->fetchrow;
is($value, 4, '... we should get the 4th record rt 76695');

# rt 76410 - fetch after fetch absolute always returns the same row
$value = $sth->ora_fetch_scroll(OCI_FETCH_ABSOLUTE, 2);
is($value->[0], 2, "... we should get the 2nd row rt76410_2");
($value) = $sth->fetchrow;
is($value, 3, "... we should get the 3rd row rt76410_2");

$sth->finish();
drop_table($dbh);


$dbh->disconnect;

1;

