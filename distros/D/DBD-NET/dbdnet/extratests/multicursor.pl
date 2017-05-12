#!/usr/bin/perl -w
#
# Tests multiple simultaneous cursors being open
#
# Assuming we have a table of the schema in 'numerics.pl'

$dbname = "test";
$tablename1 = "test3";
$tablename2 = "test2";

use DBI;

$drh = DBI->install_driver( 'Informix' ) || die "Cannot load driver: $!\n";
$dbh = $drh->connect( 'dbhost', $dbname, 'blah', 'blah' );
if ( !defined $dbh ) {
    die "Cannot connect to database: $DBI::errstr\n";
  }

# Open the first cursor
$sth1 = $dbh->prepare( "
    SELECT id1, id2, id3, id4, name
    FROM $tablename1" );
if ( !defined $sth1 ) {
    die "Cannot prepare sth1: $DBI::errstr\n";
  }

# Open the second cursor
$sth2 = $dbh->prepare( "
    SELECT id, name
    FROM $tablename2" );
if ( !defined $sth2 ) {
    die "Cannot prepare sth2: $DBI::errstr\n";
  }

$sth1->execute;
$sth2->execute;

while ( @row1 = $sth1->fetchrow ) {
    print "Row1: @row1\n";
    @row2 = $sth2->fetchrow;
    if ( defined @row2 ) {
        print "Row2: @row2\n";
      }
  }

$sth1->finish;
undef $sth1;
$sth2->finish;
undef $sth2;

$dbh->disconnect;

exit;
