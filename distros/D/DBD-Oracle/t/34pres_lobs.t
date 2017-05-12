#!perl -w

use Test::More;

use DBI;
use Config;
use DBD::Oracle qw(:ora_types);



## ----------------------------------------------------------------------------
## 33pres_lobs.t
## By John Scoles, The Pythian Group
## ----------------------------------------------------------------------------
##  Checks to see if the Interface for Persistent LOBs is working
##  Nothing fancy. Just an insert and a select if they fail this there is something up in OCI or the version
##  of oci being used
## ----------------------------------------------------------------------------

unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

# create a database handle
my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my $dbh;
eval {$dbh = DBI->connect($dsn, $dbuser, '',
                          { RaiseError=>1,
                            AutoCommit=>1,
                            PrintError => 0 ,LongReadLen=>10000000})};
if ($dbh) {
    plan skip_all => "Data Interface for Persistent LOBs new in Oracle 9"
        if $dbh->func('ora_server_version')->[0] < 9;
    plan tests => 28;
} else {
    plan skip_all => "Unable to connect to Oracle";
}
# check that our db handle is good
my $ora_oci = DBD::Oracle::ORA_OCI(); # dualvar

SKIP: {
   	skip "OCI version less than 9.2\n Persistent LOBs Tests skiped.", 29 unless $ora_oci >= 9.2;


my $table = table();

eval { $dbh->do("DROP TABLE $table") };

ok($dbh->do(qq{
	CREATE TABLE $table (
	    id NUMBER,
	    clob1 CLOB,
	    clob2 CLOB,
	    blob1 BLOB,
	    blob2 BLOB)
    }), 'create test table');


my $in_clob='ABCD' x 10_000;
my $in_blob=("0\177x\0X"x 2048) x (1);
my ($sql, $sth,$value);

$sql = "insert into ".$table."
	(id,clob1,clob2, blob1,blob2)
	values(?,?,?,?,?)";
ok($sth=$dbh->prepare($sql ), 'prepare for insert into lobs');
$sth->bind_param(1,3);
ok($sth->bind_param(2,$in_clob,{ora_type=>SQLT_CHR}), 'bind p2');
ok($sth->bind_param(3,$in_clob,{ora_type=>SQLT_CHR}), 'bind p3');
ok($sth->bind_param(4,$in_blob,{ora_type=>SQLT_BIN}), 'bind p4');
ok($sth->bind_param(5,$in_blob,{ora_type=>SQLT_BIN}), 'bind p5');
ok($sth->execute(), 'execute');

$sql='select * from '.$table;

ok($sth=$dbh->prepare($sql,{ora_pers_lob=>1}), 'prepare with ora_pers_lob');

ok($sth->execute(), 'execute with ora_pers_lob');
my ($p_id,$log,$log2,$log3,$log4);

ok(( $p_id,$log,$log2,$log3,$log4 )=$sth->fetchrow(),
   'fetcheow for ora_pers_lob');

is($log, $in_clob, 'clob1 = in_clob');
is($log2, $in_clob, 'clob2 = in_clob');
is($log3, $in_blob, 'clob1 = in_blob');
is($log4, $in_blob, 'clob2 = in_blob');

ok($sth=$dbh->prepare($sql,{ora_clbk_lob=>1,ora_piece_size=>.5*1024*1024}),
   'prepare for ora_piece_size');

ok($sth->execute(), 'execute for ora_piece_size');

ok(( $p_id,$log,$log2,$log3,$log4 )=$sth->fetchrow(), 'fetchrow');
ok($log eq $in_clob, 'clob1 = in_clob');
ok($log2 eq $in_clob, 'clob2 = in_clob');
ok($log3 eq $in_blob, 'clob1 = in_clob');
ok($log4 eq $in_blob, 'clob2 = in_clob');

ok($sth=$dbh->prepare($sql,{ora_piece_lob=>1,ora_piece_size=>.5*1024*1024}),
  'prepare with ora_piece_lob/ora_piece_size');

ok($sth->execute(), 'execute');
ok( ( $p_id,$log,$log2,$log3,$log4 )=$sth->fetchrow(),
   'fetchrow');

ok($log eq $in_clob, 'clob1 = in_clob');
ok($log2 eq $in_clob, 'clob2 = in_clob');
ok($log3 eq $in_blob, 'clob1 = in_clob');
ok($log4 eq $in_blob, 'clob2 = in_clob');

#no neeed to look at the data is should be ok

$sth->finish();
drop_table($dbh);
}


$dbh->disconnect;

1;
