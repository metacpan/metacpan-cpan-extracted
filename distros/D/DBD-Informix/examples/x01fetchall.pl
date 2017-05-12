#!/usr/bin/perl -w
#
# DBD::Informix Example 1 - fetchall_arrayref
#
# @(#)$Id: x01fetchall.pl,v 100.1 2002/02/08 22:50:07 jleffler Exp $
#
# Copyright 1998 Jonathan Leffler
# Copyright 2000 Informix Software Inc
# Copyright 2002 IBM

use DBI;
$dbh = DBI->connect("DBI:Informix:stores7");
$sth = $dbh->prepare(q%SELECT Fname, Lname, Phone FROM Customer WHERE Customer_num > ?%);
$sth->execute(106);
$ref = $sth->fetchall_arrayref();
for $row (@$ref)
{
	print "Name: $$row[0] $$row[1], Phone: $$row[2]\n";
}
$dbh->disconnect;
