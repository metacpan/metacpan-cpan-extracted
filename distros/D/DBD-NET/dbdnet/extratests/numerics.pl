#!/usr/bin/perl -w
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# To use:
#
# 1) Create a table:
#
#	id1	INTEGER
#	id2	SMALLINT
#	id3	FLOAT
#	id4	DECIMAL
#	name	CHAR(64)
#
# 2) Insert some test data, with numerics preferably longer than 4 digits
# 3) Change the connect string to suit

$tablename = "test3";

$dbname = "test";

use DBI;

$drh = DBI->install_driver( 'Informix' ) || die "Cannot load driver: $!\n";
$dbh = $drh->connect( 'dbhost', $dbname, 'blah', 'blah' );
if ( !defined $dbh ) {
    die "Cannot connect to database: $DBI::errstr\n";
  }

$sth = $dbh->prepare( "
    SELECT id1, id2, id3, id4, name
    FROM $tablename" );
if ( !defined $sth ) {
    die "Cannot prepare sth: $DBI::errstr\n";
  }

$sth->execute;

while ( ( $id1, $id2, $id3, $id4, $name ) = $sth->fetchrow ) {
    print "Row: $id1\t$id2\t$id3\t$id4\t$name\n";
  }

$sth->finish;
undef $sth;

$dbh->disconnect;

exit;
