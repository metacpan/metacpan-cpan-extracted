#!perl -w
# From: Jeffrey Horn <horn@cs.wisc.edu>
use Test::More;
use DBI;
use DBD::Oracle qw(ORA_RSET);
use strict;

unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

my ($limit, $tests);

my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';
my $dbh = DBI->connect($dsn, $dbuser, '', { PrintError => 0 });

if ($dbh) {
    # ORA-00900: invalid SQL statement
    # ORA-06553: PLS-213: package STANDARD not accessible
    my $tst = $dbh->prepare(
        q{declare foo char(50); begin RAISE INVALID_NUMBER; end;});
    if ($dbh->err && ($dbh->err==900 || $dbh->err==6553 || $dbh->err==600)) {
        warn "Your Oracle server doesn't support PL/SQL" if $dbh->err== 900;
        warn "Your Oracle PL/SQL is not properly installed"
            if $dbh->err==6553||$dbh->err==600;
        plan skip_all => 'server does not support pl/sql or not installed';
    }

    $limit = $dbh->selectrow_array(
        q{SELECT value-2 FROM v$parameter WHERE name = 'open_cursors'});
    # allow for our open and close cursor 'cursors'
    $limit -= 2 if $limit && $limit >= 2;
    unless (defined $limit) { # v$parameter open_cursors could be 0 :)
        warn("Can't determine open_cursors from v\$parameter, so using default\n");
        $limit = 1;
    }
    $limit = 100 if $limit > 100; # lets not be greedy or upset DBA's
    $tests = 2 + 10 * $limit + 6;

    plan tests => $tests;

    note "Max cursors: $limit";

} else {
    plan skip_all => "Unable to connect to Oracle";
}

my @cursors;
my @row;

note("opening cursors\n");
my $open_cursor = $dbh->prepare( qq{
	BEGIN OPEN :kursor FOR
		SELECT * FROM all_objects WHERE rownum < 5;
	END;
} );
ok($open_cursor, 'open cursor' );

foreach ( 1 .. $limit ) {
	note("opening cursor $_\n");
	ok( $open_cursor->bind_param_inout( ":kursor", \my $cursor, 0, { ora_type => ORA_RSET } ), 'open cursor bind param inout' );
	ok( $open_cursor->execute, 'open cursor execute' );
	ok(!$open_cursor->{Active}, 'open cursor Active');

	ok($cursor->{Active}, 'cursor Active' );
	ok($cursor->fetchrow_arrayref, 'cursor fetcharray');
	ok($cursor->fetchrow_arrayref, 'cursor fetcharray');
	ok($cursor->finish, 'cursor finish' );	# finish early
	ok(!$cursor->{Active}, 'cursor not Active');

	push @cursors, $cursor;
}

note("closing cursors\n");
my $close_cursor = $dbh->prepare( qq{ BEGIN CLOSE :kursor; END; } );
ok($close_cursor, 'close cursor');
foreach ( 1 .. @cursors ) {
	print "closing cursor $_\n";
	my $cursor = $cursors[$_-1];
	ok($close_cursor->bind_param( ":kursor", $cursor, { ora_type => ORA_RSET }), 'close cursor bind param');
	ok($close_cursor->execute, 'close cursor execute');
}

my $PLSQL = <<"PLSQL";
DECLARE
  TYPE t IS REF CURSOR;
  c t;
BEGIN
  ? := c;
END;
PLSQL

ok(my $sth1 = $dbh->prepare($PLSQL),
   'prepare exec of proc for null cursor');
ok($sth1->bind_param_inout(1, \my $cursor, 100, {ora_type => ORA_RSET}),
   'binding cursor for null cursor');
ok($sth1->execute, 'execute for null cursor');
is($cursor, undef, 'undef returned for null cursor');
ok($sth1->execute, 'execute 2 for null cursor');
is($cursor, undef, 'undef 2 returned for null cursor');

$dbh->disconnect;

exit 0;

