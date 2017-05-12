#!perl -w
use Test::More;

use DBI;
use DBD::Oracle qw(ORA_RSET);
use strict;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my $dbh = DBI->connect($dsn, $dbuser, '', { PrintError => 0 });

if ($dbh) {
    plan tests=> 29;
} else {
    plan skip_all =>"Unable to connect to Oracle";
}

# ref cursors may be slow due to oracle bug 3735785
# believed fixed in
#	 9.2.0.6 (Server Patch Set)
#	10.1.0.4 (Server Patch Set)
#	10.2.0.1 (Base Release)

my $outer = $dbh->prepare(q{
    SELECT object_name, CURSOR(SELECT object_name FROM dual)
    FROM all_objects WHERE rownum <= 5});
ok($outer, 'prepare select');

ok( $outer->{ora_types}[1] == ORA_RSET, 'set ORA_RSET');
ok( $outer->execute, 'outer execute');
ok( my @row1 = $outer->fetchrow_array, 'outer fetchrow');
my $inner1 = $row1[1];
is( ref $inner1, 'DBI::st', 'inner DBI::st');
ok( $inner1->{Active}, 'inner Active');
ok( my @row1_1 = $inner1->fetchrow_array, 'inner fetchrow_array');
is( $row1[0], $row1_1[0], 'rows equal');
ok( $inner1->{Active}, 'inner Active');
ok(my @row2 = $outer->fetchrow_array, 'outer fetchrow_array');
ok(!$inner1->{Active}, 'inner not Active');
ok(!$inner1->fetch, 'inner fetch finished');
is($dbh->err, -1, 'err = -1');
like($dbh->errstr, qr/ defunct /, 'defunct');
ok($outer->finish, 'outer finish');
is($dbh->{ActiveKids}, 0, 'ActiveKids');

#########################################################################
# Same test again but this time with 2 cursors
#########################################################################

$outer = $dbh->prepare(q{
    SELECT object_name, 
           CURSOR(SELECT object_name FROM dual),
           CURSOR(SELECT object_name FROM dual)
      FROM all_objects WHERE rownum <= 5});
ok($outer, 'prepare select');

ok( $outer->{ora_types}[1] == ORA_RSET, 'set ORA_RSET');
ok( $outer->{ora_types}[2] == ORA_RSET, 'set ORA_RSET');
ok( $outer->execute, 'outer execute');
ok(  @row1 = $outer->fetchrow_array, 'outer fetchrow');
$inner1 = $row1[1];
my $inner2 = $row1[2];
is( ref $inner1, 'DBI::st', 'inner DBI::st');
is( ref $inner2, 'DBI::st', 'inner DBI::st');

ok( $inner1->{Active}, 'inner Active');
ok( $inner2->{Active}, 'inner Active');
ok( @row1_1 = $inner1->fetchrow_array, 'inner fetchrow_array');
ok( my @row2_1 = $inner2->fetchrow_array, 'inner fetchrow_array');
is( $row1[0], $row1_1[0], 'rows equal');
is( $row1[0], $row2_1[0], 'rows equal');



#########################################################################
# Fetch speed test: START
#########################################################################

$dbh->{RaiseError} = 1;

sub timed_fetch {
  my ($rs,$caption) = @_;
  my $row_count = 0;
  my $tm_start = DBI::dbi_time();
  $row_count++ while $rs->fetch;
  my $elapsed = DBI::dbi_time() - $tm_start;

  note "Fetched $row_count rows ($caption): $elapsed secs.";

  return $elapsed;
}

##################################################
# regular select
##################################################
my $sql1 = q{
    SELECT object_name
    FROM (SELECT object_name FROM all_objects WHERE ROWNUM<=70),
	 (SELECT           1 FROM all_objects WHERE ROWNUM<=70)
};
$outer = $dbh->prepare($sql1);
$outer->execute();
my $dur_std = timed_fetch($outer,'select');

##################################################
# nested cursor
##################################################
$outer = $dbh->prepare("SELECT CURSOR($sql1) FROM DUAL");
$outer->execute();
my $ref_csr = $outer->fetchrow_arrayref->[0];
my $dur_ref = timed_fetch($ref_csr,'nested cursor');

#########################################################################
# Fetch speed test: END
#########################################################################

exit 0;

