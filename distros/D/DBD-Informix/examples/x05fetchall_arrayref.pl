#!/usr/bin/perl -w
#
# DBD::Informix Example 5 - fetchall_arrayref
#
# @(#)$Id: x05fetchall_arrayref.pl,v 100.1 2002/02/08 22:50:10 jleffler Exp $
#
# Copyright 1998 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM

use DBI;
printf("DEMO1 Sample DBD::Informix Program running.\n");
printf("Variant 4: using fetchall_arrayref()\n");
my($dbh) = DBI->connect("DBI:Informix:stores7") or die;
my($sth) = $dbh->prepare(q%
	SELECT fname, lname FROM customer WHERE lname < 'C'%) or die;
$sth->execute() or die;
my($ref) = $sth->fetchall_arrayref();
foreach $row (@$ref)
{
  printf("%s %s\n", $$row[0], $$row[1]);
}
undef $sth;
$dbh->disconnect();
printf("\nDEMO1 Sample Program over.\n\n");

