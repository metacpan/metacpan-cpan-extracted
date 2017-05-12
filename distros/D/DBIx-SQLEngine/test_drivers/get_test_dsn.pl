# Process DBI DSN from environment or provide feedback about how to set it.

use vars qw($dsn $user $pass $sqldb);

($dsn, $user, $pass) = ( 
  scalar(@ARGV) ? ( @ARGV ) : 
  $ENV{DBI_DSN} ? ( map $ENV{$_}, qw( DBI_DSN DBI_USER DBI_PASS ) ) :
  ()
);
$dsn = '' if ( ! $dsn or $dsn eq '-' );

########################################################################

if ( ! $dsn ) {

  warn <<".";

  Note: This test script can only be run if it can connect to a working DBI
  database driver. Using that connection, this test script will create
  a table named sqle_test, run various queries against it, and then drop it.

  Although this should not affect other applications, for safety's sake, use
  a test account or temporary data space, and avoid testing this on any
  mission-critical production systems.

  In order to run this test script against a local database, set the
  DBI_DSN environment variable to your connection string before running the
  tests, and if needed, also set the DBI_USER and DBI_PASS variables.
    Example:  > setenv DBI_DSN "DBI:mysql:test"; make test_drivers/*.t

  If you are running individual test scripts, you can pass the DSN,  
  username, and password as command-line arguments to the test.
    Example:  > perl -Mblib $0 "DBI:mysql:test"
.

  plan tests => 1;
  skip(
    "Skipping: specify DBI_DSN in environment to test your local server.\n",
    0,
  );
  exit 0;
}

########################################################################

$sqldb = DBIx::SQLEngine->new($dsn, $user, $pass);

if ( ! $sqldb ) {
warn <<".";
  Skipping: Could not connect to this DBI_DSN to test your local server.
.
  plan tests => 1;
  skip(
    "Skipping: Could not connect to this DBI_DSN to test your local server.",
    0,
  );
  exit 0;
}

$sqldb->select_detect_dbms_flavor if ($sqldb->can('select_detect_dbms_flavor'));


1;
