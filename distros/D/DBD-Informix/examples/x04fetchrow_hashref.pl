#!/usr/bin/perl -w
#
# DBD::Informix Example 4 - fetchrow_hashref
#
# @(#)$Id: x04fetchrow_hashref.pl,v 100.1 2002/02/08 22:50:09 jleffler Exp $
#
# Copyright 1998 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM

use DBI;
printf("DEMO1 Sample DBD::Informix Program running.\n");
printf("Variant 3: using fetchrow_hashref()\n");
my($dbh) = DBI->connect("DBI:Informix:stores7") or die;
my($sth) = $dbh->prepare(q%
	SELECT fname, lname FROM customer WHERE lname < 'C'%) or die;
$sth->execute() or die;
my($row);
while ($row = $sth->fetchrow_hashref())
{
  printf("%s %s\n", $$row{fname}, $$row{lname});
}
undef $sth;
$dbh->disconnect();
printf("\nDEMO1 Sample Program over.\n\n");

