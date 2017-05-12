#!/usr/bin/perl
#
#   @(#)$Id: t60unlog.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test that unlogged databases refuse to connect with AutoCommit => 0
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2004-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

if (defined $ENV{DBD_INFORMIX_NO_DBCREATE} && $ENV{DBD_INFORMIX_NO_DBCREATE})
{
    stmt_note "1..0 # Skip: requires database create permission but DBD_INFORMIX_NO_DBCREATE set.\n";
    exit 0;
}

my ($dbname) = "dbd_ix_db";
my ($user) = $ENV{DBD_INFORMIX_USERNAME};
my ($pass) = $ENV{DBD_INFORMIX_PASSWORD};

stmt_note("# Test DBI->connect('dbi:Informix:.DEFAULT.')\n");
my $dbh;
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));

stmt_note("1..10\n");
stmt_ok;

# Do not care about non-existent database
$dbh->{PrintError} = 0;
$dbh->do("drop database $dbname");
$dbh->{PrintError} = 1;
$dbh->{ChopBlanks} = 1;

my $select = "SELECT TabName, Owner FROM 'informix'.SysTables WHERE TabID = 1";

stmt_note("# Create unlogged database $dbname\n");
stmt_test($dbh, "create database $dbname");

if ($dbh->{ix_ServerVersion} >= 800 && $dbh->{ix_ServerVersion} < 900)
{
    # XPS 8.xx does not support unlogged databases, so this test is
    # doomed to fail if it runs against XPS.
    $dbh->{PrintError} = 0;
    $dbh->do("close database");
    $dbh->do("drop database $dbname");
    $dbh->disconnect;
    stmt_skip("XPS server - no unlogged databases!");
    # Already printed ok thrice (one in stmt_test, one in stmt_skip); 5 more needed.
    for (my $i = 0; $i < 5; $i++) { stmt_ok; }
    all_ok;
    exit 0;
}

my $result = { 'systables' => { 'owner' => 'informix', 'tabname' => 'systables' } };

my $sth = $dbh->prepare($select) or stmt_fail;
stmt_ok;
$sth->execute ? validate_unordered_unique_data($sth, 'tabname', $result) : stmt_nok;

stmt_test($dbh, "close database");
stmt_fail unless ($dbh->disconnect);
stmt_ok;
undef $dbh;

my $msg;
$SIG{__WARN__} = sub { $msg = $_[0]; };
stmt_note("# Test DBI->connect('dbi:Informix:$dbname',...,{AutoCommit=>0})\n");
$dbh = DBI->connect("dbi:Informix:$dbname", $user, $pass,
                    { AutoCommit => 0, PrintError => 1 });
$SIG{__WARN__} = 'DEFAULT';
# Under DBI 0.85, this connection worked.  Ideally it should have failed.
# Under DBI 0.90, this connection fails, as it is supposed to!
stmt_note("# Connection failed - which is the correct response\n") if (!defined $dbh);
stmt_ok if (!defined $dbh);
# JL 2004-12-03: Starting at DBI v1.43, under Perl 5.6.1 (but not
# 5.8.[56]), the variable $msg is not assigned to for reasons which are
# unclear.  Consequently, skip this next test on those platforms where
# that is a problem.  Found in the pre-release testing for DBD::Informix
# 2004.02, but also found with DBD::Informix 2003.04.
if ($] < 5.008 && $DBI::VERSION >= 1.43 && !($msg && $msg =~ /-256:/))
{
    stmt_skip("Perl $] plus DBI $DBI::VERSION known to fail.\n# Upgrade Perl to 5.8.x or downgrade DBI to 1.42.");
}
elsif ($msg && $msg =~ /-256:/)
{
    stmt_ok;
}
else
{
    stmt_fail;
}
$msg =~ s/\n/ /mg;
stmt_note("# $msg\n");

# Remove test database
stmt_fail unless ($dbh = DBI->connect('dbi:Informix:.DEFAULT.', $user, $pass));
$dbh->{PrintError} = 1;
stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

all_ok();
