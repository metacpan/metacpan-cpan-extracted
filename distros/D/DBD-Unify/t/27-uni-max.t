#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# Test if all of the documented DBI API is implemented and working OK

my ($max_sth, $tests);

BEGIN {
    $max_sth = 473;	# Arbitrary limit test count
    $tests   = 9 + 5 * ($max_sth + 1); # All tests run from 0 to $max_sth

    $ENV{MAXSCAN}       = $max_sth + 1;
    $ENV{MXOPENCURSORS} = 2 * $max_sth;

    if (exists $ENV{DBD_UNIFY_SKIP_27}) {
	plan skip_all => "Skip max tests on user request";
	done_testing;
	}
    print STDERR "# To disable future max tests: setenv DBD_UNIFY_SKIP_27 1\n";

    use_ok ("DBI");
    }

# =============================================================================

my $dbh;

ok ($dbh = DBI->connect ("dbi:Unify:"), "connect");

unless ($dbh) {
    BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");
    exit 0;
    }

my $sts;

# =========================================================================

ok ($sts = $dbh->do (join " " => q;
    create table xx (
	xs numeric       (4) not null,
	xl numeric       (9)
	);), "do");
if ($dbh->err) {
    BAIL_OUT ("Unable to create table ($DBI::errstr)\n");
    exit 0;
    }
ok ($dbh->commit, "commit");

# Now check hitting realloc sth_id with an arbitrary number
my @sti = map {
    my $sth;
    ok ($sth = $dbh->prepare ("insert into xx (xs, xl) values ($_, ?)"), "ins prepare $_");
    $sth } (0 .. $max_sth);
ok ($sti[$_]->execute (1234), "ins execute $_") for 0 .. $#sti;
my @sts = map {
    my $sth;
    ok ($sth = $dbh->prepare ("select xs, xl from xx where xs = ?"), "sel prepare $_");
    $sth } (0 .. $max_sth);
foreach my $i (0 .. $max_sth) {
    ok ($sts[$i]->execute ($i), "execute $i");
    my ($xs, $xl) = $sts[$i]->fetchrow_array;
    ok ($xs == $i && $xl == 1234, "fetch $i");
    }
map { $_->finish () } @sts, @sti;
ok ($dbh->commit, "commit");

# =============================================================================
ok ($dbh->do ("drop table xx"), "drop");
ok ($dbh->commit, "commit");

ok ($dbh->disconnect, "disconnect");
ok (!$dbh->ping, "!ping");

done_testing;
