#!/usr/bin/perl -w
#
# (c)1996 Hermetica. Written by Alligator Descartes <descarte@hermetica.com>
#
# Test @ary = $drh->func( '_ListDBs' );

use DBI;

$drh = 
    DBI->install_driver( 'Informix' ) || 
        die "Cannot load Informix driver: $!\n";
@ary = $drh->func( '_ListDBs' );
if ( !defined @ary ) {
    print "ListDBs failed\n";
  } else {
    foreach $db ( @ary ) {
        print "Database: $db\n";
      }
  }

exit;
