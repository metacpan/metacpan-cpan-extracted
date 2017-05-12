#!/usr/bin/perl
#
#   @(#)$Id: t20error.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test error on EXECUTE for DBD::Informix
#
#   Copyright 1997-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use DBD::Informix::TestHarness;
use strict;
use warnings;

# Test install...
my $dbh = connect_to_test_database();

my $tabname = "dbd_ix_err01";

stmt_note("1..5\n");
stmt_ok();

stmt_test $dbh, qq{
CREATE TEMP TABLE $tabname
(
    Col01   SERIAL NOT NULL PRIMARY KEY,
    Col02   CHAR(20) NOT NULL
)
};

stmt_test $dbh, qq{ CREATE UNIQUE INDEX pk_$tabname ON $tabname(Col02) };

my $insert01 = qq{ INSERT INTO $tabname VALUES(0, 'Gee Whizz!') };

my $sth = $dbh->prepare($insert01) or die "Prepare failed\n";

# Should be OK!
my $rv = $sth->execute();
stmt_fail() if ($rv != 1);

my $msg;
$SIG{__WARN__} = sub { $msg = $_[0]; };

# Should fail (dup value)!
$rv = $sth->execute();
if (defined $rv)
{
    print "# Return from failed execute = <<$rv>>\n";
    stmt_fail();
}
stmt_fail() unless ($msg && $msg =~ /-100:/ && $msg =~ /-239:/);
$SIG{__WARN__} = 'DEFAULT';

my @isam = @{$sth->{ix_sqlerrd}};
print "# SQL = $sth->{ix_sqlcode}; ISAM = $isam[1]\n";
print "# DBI::state: $DBI::state\n";
print "# DBI::err:   $DBI::err\n";
print "# DBI::errstr:\n$DBI::errstr\n";
stmt_ok();

my $sel = $dbh->prepare("SELECT * FROM $tabname") or stmt_fail;
$sel->execute or stmt_fail;
validate_unordered_unique_data($sel, 'col01',
    {   1 => { 'col01' => 1, 'col02' => 'Gee Whizz!' }, });

all_ok();
