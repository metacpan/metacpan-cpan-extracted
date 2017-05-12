BEGIN{unshift @INC, "../../lib", "./lib";}

use DBI;

$testtable = "uuuuu";

$dbname = 'comets';

print "Testing: DBI->install_driver( 'Informix' ): ";
( $drh = DBI->install_driver( 'Informix' ) )
  and print( "ok\n" )
  or die "not ok: $DBI::errstr\n";

print "Testing: \$drh->connect( 'dbhost', '$dbname', 'dbuser', 'dbpass' ): ";
( $dbh = $drh->connect( 'dbhost', $dbname, 'dbuser', 'dbpass' ) )
    and print("ok\n") 
    or die "not ok: $DBI::errstr\n";

print "Testing: \$dbh->disconnect(): ";
( $dbh->disconnect )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$drh->connect( 'dbhost', '$dbname', 'dbuser', 'dbpass' ): ";
( $dbh = $drh->connect( 'dbhost', $dbname, 'dbuser', 'dbpass' ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print STDERR "*** Testing: \$dbh->do FUNCTION: Just ignore: \n
              Statement handle DBI::st=HASH(0x80dedf0) destroyed without
              finish()\n\n    errors ***\n";
print "Testing: \$dbh->do( 'CREATE TABLE $testtable
                       (
                        id INTEGER,
                        name CHAR(64)
                       )' ): ";
( $dbh->do( "CREATE TABLE $testtable ( id INTEGER, name CHAR(64) )" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: \$dbh->do( 'DROP TABLE $testtable' ): ";
( $dbh->do( "DROP TABLE $testtable" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$dbh->do( 'CREATE TABLE $testtable
                       (
                        id INTEGER,
                        name CHAR(64)
                       )' ): ";
( $dbh->do( "CREATE TABLE $testtable ( id INTEGER, name CHAR(64) )" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

# List the fields of the table we've just created in here.....

#print "Testing: \$dbh->func( $testtable, '_ListFields' ): ";
#( $ref = $dbh->func( $testtable, '_ListFields' ) )
#    and print( "ok\n" )
#    or die "not ok: $DBI::errstr\n";

# List the fields. Uncomment this if you're the curious type........

print "Testing: \$dbh->do( 'INSERT INTO $testtable VALUES ( 1, 'Alligator Descartes' )' ): ";
( $dbh->do( "INSERT INTO $testtable VALUES( 1, 'Alligator Descartes' )" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: \$dbh->do( 'DELETE FROM $testtable WHERE id = 1' ): ";
( $dbh->do( "DELETE FROM $testtable WHERE id = 1" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Testing: \$cursor = \$dbh->prepare( 'SELECT FROM $testtable WHERE id = 1' ): ";
( $cursor = $dbh->prepare( "SELECT * FROM $testtable WHERE id = 1" ) )
    and print( "ok\n" )
    or print( "not ok: $DBI::errstr\n" );

print "Testing: \$cursor->execute: ";
( $cursor->execute )
    and print( "ok\n" )
    or print( "not ok: $DBI::errstr\n" );

print "*** Expect this test to fail with NO error message!\n";
print "Testing: \$cursor->fetchrow: ";
( @row = $cursor->fetchrow ) 
    and print( "ok: $row\n" )
    or print( "not ok: $DBI::errstr\n" );

print "Testing: \$cursor->finish: ";
( $cursor->finish )
    and print( "ok\n" )
    or print( "not ok: $DBI::errstr\n" );

# Temporary bug-plug
undef $cursor;

print "Re-testing: \$dbh->do( 'INSERT INTO $testtable VALUES ( 1, 'Alligator Descartes' )' ): ";
( $dbh->do( "INSERT INTO $testtable VALUES( 1, 'Alligator Descartes' )" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$cursor = \$dbh->prepare( 'SELECT FROM $testtable WHERE id = 1' ): ";
( $cursor = $dbh->prepare( "SELECT * FROM $testtable WHERE id = 1" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

#print "Rows returned should be: 1\nActual rows returned: $numrows\n";

print "Re-testing: \$cursor->execute: ";
( $cursor->execute )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$cursor->fetchrow: ";
( @row = $cursor->fetchrow ) 
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$cursor->finish: ";
( $cursor->finish )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

# Temporary bug-plug
undef $cursor;

print "Testing: \$dbh->do( 'UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'' ): ";
( $dbh->do( "UPDATE $testtable SET id = 2 WHERE name = 'Alligator Descartes'" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "Re-testing: \$dbh->do( 'DROP TABLE $testtable' ): ";
( $dbh->do( "DROP TABLE $testtable" ) )
    and print( "ok\n" )
    or die "not ok: $DBI::errstr\n";

print "*** Testing of DBD::Informix complete! You appear to be normal! ***\n";
