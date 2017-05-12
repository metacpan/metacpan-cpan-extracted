#!/usr/bin/perl
#
#   @(#)$Id: t94bool.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test basic handling of Boolean data type
#
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler

use strict;
use warnings;
use DBD::Informix::TestHarness;

my ($table) = "dbd_ix_bool";
my ($dbh) = test_for_ius;

stmt_note("1..7\n");

# Test BOOLEAN literals.
$dbh->{RaiseError} = 1;
$dbh->do(qq% create temp table $table(b boolean not null) %);
$dbh->do(qq% insert into $table values('f') %);
$dbh->do(qq% insert into $table values('t') %);

sub check_two_rows
{
    my($sth) = $dbh->prepare(qq% select b from $table order by b%);
    $sth->execute;
    stmt_ok;

    my($row1) = $sth->fetchrow_arrayref;
    stmt_fail unless ($$row1[0] eq 'f');
    stmt_comment "Bool 1: $$row1[0]\n";
    stmt_ok;
    my($row2) = $sth->fetchrow_arrayref;
    stmt_fail unless ($$row2[0] eq 't');
    stmt_comment "Bool 2: $$row2[0]\n";
    stmt_ok;
}

check_two_rows;

# Test BOOLEAN variables.
$dbh->do(qq% delete from $table %);
my($sth) = $dbh->prepare(qq% insert into $table values(?) %);

my($bool) = 'f';
$sth->execute($bool);
$bool = 't';
$sth->execute($bool);

# Fail -415: data conversion error
#$bool = 'true';
#$sth->execute($bool);
#$bool = 'false';
#$sth->execute($bool);

# Fail -9635: no cast from type
#$bool = 0;
#$sth->execute($bool);
#$bool = 1;
#$sth->execute($bool);
stmt_ok;

check_two_rows;

undef $sth;
$dbh->disconnect;

all_ok;

