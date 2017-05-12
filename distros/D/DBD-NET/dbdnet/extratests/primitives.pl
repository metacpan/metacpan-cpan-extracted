#!/usr/bin/perl -w
#
# Exercises the returning of error codes in ESQL/C intermediate step failure

use strict;
use DBI;

my ($drh, $dbh, $cursor, @row ) ;

( $drh = DBI->install_driver( 'Informix' ) )
  or die "not ok: $DBI::errstr\n";
print "Installed\n" ;

( $dbh = $drh->connect('localhost', 'test','','') )
  or die "not ok: $DBI::errstr\n";
print "Connected\n" ;

( $cursor = $dbh->prepare( "SELECT x FROM test" ) )
  or die "not ok: $DBI::errstr\n";
print "Prepared\n" ;

( $cursor->execute )
  or die "not ok: $DBI::errstr\n";
print "Executed\n" ;

( @row = $cursor->fetchrow )
  and print "@row\n"
  or die "not ok: $DBI::errstr\n";
print "Fetched\n" ;

( $cursor->finish )
  or die "not ok: $DBI::errstr\n";
print "Finished\n" ;

undef $cursor;

( $dbh->disconnect )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";
print "Disconnected\n" ;
