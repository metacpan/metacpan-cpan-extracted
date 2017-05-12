#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok ("DBI") }

my $dbh;
ok ($dbh = DBI->connect ("dbi:Unify:", "", ""), "connect");

$dbh or BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");

# Hmm with perlIO I can use
# open my $trace_handle, ">", \$trace;
# $dbh->trace (1, $trace_handle);
# $dbh->trace (0);
# and have the complete trace in $trace
my $tracefile = "trace.log";
my $trace;

sub stoptrace
{
    $dbh->trace (0);

    $trace = "";
    open my $tf, "<", $tracefile or return;
    {   local $/;
	$trace = <$tf>;
	}
    close $tf;

    unlink $tracefile;
    } # stoptrace

END {
    stoptrace (0);
    }

my ($catalog, $schema, $table, $type, $rw);

my %pat = (
    dbi => [	qr{^}s,
		qr{trace level set to 0x0/1}s,
		qr{trace level set to 0x0/2}s,
		qr{trace level set to 0x0/3}s,
		qr{trace level set to 0x0/4}s,
		qr{trace level set to 0x0/5}s,
		],
    dbd => [	qr{^}s, qr{^}s,
		undef,
		qr{DBD::Unify::st_fetch u_sql_00_000000}s,
		qr{DBD::Unify::st_finish u_sql_00_000000}s,
		qr{Field   2: \[01 12 00 00 12\]}s,
		qr{Field   2: \[01 12 00 00 FFFFFFFF\] OWNR}s,
		qr{LEVEL 6 HAS NOT YET BEEN IMPLEMENTED}s,
		],
    );
# The output for level 2 differs, as the report for DBD_VERBOSE
#  itself is on level 2, and level 2 is supposed to be DBI only
my @patv2 = (
    qr{^}s,
    qr{.}s,
    qr{Set DBD_VERBOSE = 1}s,
    qr{Set DBD_VERBOSE = 2}s,
    qr{FETCH.'dbd_verbose'}s,
    );
my %dbdv2 = (
    "0.1"	=> $patv2[1],
    "0.2"	=> $patv2[0],
    "0.3"	=> $patv2[0],
    "0.4"	=> $patv2[0],
    "0.5"	=> $patv2[0],
    "0.6"	=> $patv2[0],
    "1.1"	=> $patv2[3],
    "1.2"	=> $patv2[4],
    "1.3"	=> $patv2[0],
    "1.4"	=> $patv2[0],
    "1.5"	=> $patv2[0],
    "1.6"	=> $patv2[0],
    "2.1"	=> $patv2[2],
    "2.2"	=> $patv2[3],
    "2.3"	=> $patv2[3],
    "2.4"	=> $patv2[3],
    "2.5"	=> $patv2[3],
    "2.6"	=> $patv2[3],
    "3.1"	=> $patv2[3],
    "3.2"	=> $patv2[3],
    "3.3"	=> $patv2[3],
    "3.4"	=> $patv2[3],
    "3.5"	=> $patv2[3],
    "3.6"	=> $patv2[3],
    "4.1"	=> $patv2[3],
    "4.2"	=> $patv2[3],
    "4.3"	=> $patv2[3],
    "4.4"	=> $patv2[3],
    "4.5"	=> $patv2[3],
    "4.6"	=> $patv2[3],
    "5.1"	=> $patv2[3],
    "5.2"	=> $patv2[3],
    "5.3"	=> $patv2[3],
    "5.4"	=> $patv2[3],
    "5.5"	=> $patv2[3],
    "5.6"	=> $patv2[3],
    );

sub testtrace
{
    my $dbdv = shift;
    ok (1, "-- $dbdv: table_info ()");

    ok (my $sth = $dbh->table_info (), "table_info ()");
    ok ($sth->bind_columns (\($catalog, $schema, $table, $type, $rw)), "bind");
    my $n = 0;
    ok ($sth->fetch,  "fetch");
    ok ($sth->finish, "finish");

    ok (1, "Stop trace");
    stoptrace ();

    ok (1, "$dbdv - trace = " . length $trace);
    } # testtrace

foreach     my $v_dbi (0 .. 4) {
    foreach my $v_dbd (1 .. 6) {
	my $v_trc = $v_dbi > $v_dbd ? $v_dbi : $v_dbd; # DBD trace uses the highest

	my $dbdv = "$v_dbi.$v_dbd";
	ok ($dbdv,				"=== Testing $dbdv");

	$pat{dbd}[2] = $dbdv2{$dbdv};

	is ($dbh->trace ($v_dbi, $tracefile),  0, "Set DBI trace level $v_dbi");
	is ($dbh->{dbd_verbose} = $v_dbd, $v_dbd, "Set DBD trace level $v_dbd");
	testtrace ($dbdv);

	my $v_nxt = $v_dbi + 1;
	like   ($trace, $pat{dbi}[$v_dbi],	"DBI trace matches level $v_dbi");
	unlike ($trace, $pat{dbi}[$v_nxt],	"DBI trace doesn't match $v_nxt");

	$v_dbd or next;
	   $v_nxt = $v_trc + 1;
	like   ($trace, $pat{dbd}[$v_trc],	"DBD trace matches level $v_trc");
	unlike ($trace, $pat{dbd}[$v_nxt],	"DBD trace doesn't match $v_nxt");
	}
    }

ok (1, "Stop trace");
stoptrace (0);
done_testing;
