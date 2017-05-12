#!perl -w
# $Id$


use strict;
use DBI;

my $dbh = DBI->connect();

# create a temp table with an identity property on a column:
my $sql = qq{CREATE TABLE #TEMP1 (MyCol INT NOT NULL IDENTITY)};
$dbh->do($sql);

# Set the identity insert property for this table on
# this should allow me to explicitly give a value to be inserted into the # identity column:

$sql = qq{SET IDENTITY_INSERT #TEMP1 ON};
$dbh->do($sql);		# Added by JLU
# now try to insert an explicit value into this identity column:

$sql = qq{INSERT INTO #TEMP1 (MyCol) VALUES (1)};
$dbh->do($sql);

$dbh->disconnect;
