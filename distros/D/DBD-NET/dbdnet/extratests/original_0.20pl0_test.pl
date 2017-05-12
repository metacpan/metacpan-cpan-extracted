#!/usr/bin/perl -w
#
#

$dbhost = 'localhost';		# Leave this just now
$dbname = 'test';		# Alter this to the name of a local database

use DBI;

DBI->internal->{DebugDispatch} = 0;

$drh = DBI->install_driver( 'Informix' );

$dbh = $drh->connect( $dbhost, $dbname, 'user', 'pass' );
die "Cannot connect to test\n" unless $dbh;

print "*** Preparing SELECT * from systables ***\n";

$cursor = 
    $dbh->prepare( "SELECT * FROM systables" );

$cursor->execute;

print "*** Selecting data as an ary ***\n";

while ( @row = $cursor->fetchrow ) {
    print "Row: @row\n";
  }

$cursor->finish;
undef $cursor;

print "*** Preparing SELECT * FROM systables WHERE tabname = 'systables' ***\n";

$cursor2 = 
    $dbh->prepare( "SELECT tabname, owner
                    FROM systables
                    WHERE tabname = 'systables'" );

$cursor2->execute;

print "*** Selecting data as a list of specified vars ***\n";

while ( ( $tabname, $owner ) = $cursor2->fetchrow ) {
    print "tabname: $tabname\towner: $owner\n";
  }

$cursor2->finish;
undef $cursor2;

$cursor3 = 
    $dbh->do( "CREATE TABLE pants2 ( a INTEGER )" );

$dbh->disconnect;
