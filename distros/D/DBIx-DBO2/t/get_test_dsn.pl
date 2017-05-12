# Process DBI DSN from environment or provide feedback about how to set it.

use vars qw($dsn $user $pass);

BEGIN { 
  ($dsn, $user, $pass) = ( 
    scalar(@ARGV) ? ( @ARGV ) : 
    $ENV{DBI_DSN} ? ( map $ENV{$_}, qw( DBI_DSN DBI_USER DBI_PASS ) ) :
    ()
  );
  $dsn = '' if ( ! $dsn or $dsn eq '-' );
}

########################################################################

if ( ! $dsn ) {

  warn <<'.';

  Note: This test script can only be run if it can connect to a working DBI
  database driver. Using that connection, this test script will create
  several tables, run various queries against them, and then drop them.

  Although this should not affect other applications, for safety's sake, use
  a test account or temporary data space, and avoid testing this on any
  mission-critical production systems.

  In order to run this test script against a local database, set the
  DBI_DSN environment variable to your connection string before running the
  tests, and if needed, also set the DBI_USER and DBI_PASS variables.
    Example:  > setenv DBI_DSN "DBI:mysql:test"; make test

  If you are running individual test scripts, you can pass the DSN,  
  username, and password as command-line arguments to the test.
    Example:  > perl -Iblib/lib t/standard.t "DBI:mysql:test"

  This script will now query DBI for available drivers and suggested DSNs: 
.

  %common_cases = (
    'AnyData' => 'dbi:AnyData:',
    'SQLite' => 'dbi:SQLite:dbname=t/data/test.sqlite',
    'mysql' => 'dbi:mysql:test',
  );
  @exclude_patterns = (
    'ExampleP',   # Insufficient capabilities
    'blib$', 	  # for file-based DBDs, don't show the compilation directory
    'DBO2$', 	  # nor the source directory...
  );
  require DBI;
  foreach my $driver ( DBI->available_drivers ) {
    eval {
      DBI->install_driver($driver);
      my @data_sources;
      eval {
	@data_sources = DBI->data_sources($driver);
      };
      push @data_sources, split(' ', $common_cases{$driver} || '');
      if (@data_sources) {
	foreach my $source ( @data_sources ) {
	  next if grep { $source =~ /\b$_\b/ } @exclude_patterns;
	  $source =~ s{\bt$}{t/test_data};
	  push @suggestions, ($source =~ /:/ ? $source : "dbi:$driver:$source");
	} 
      } else { 
	push @suggestions, "dbi:$driver";
      }
    };
  } 

  if ( scalar @suggestions ) {
    %suggestions = map { $_ => 1 } @suggestions;
    @suggestions = sort { lc($a) cmp lc($b) } keys %suggestions;
    warn join '', map "    $_\n", @suggestions;
  } else {
    warn "    (No suggestions found.)\n";
  }

  plan tests => 1;
  skip(
    "Skipping: specify DBI_DSN in environment to test your local server.\n",
    0,
  );
  exit 0;

}

########################################################################

warn <<".";

  The remaining tests will use the DBI DSN specified in your environment: 
    $dsn

  In a few seconds, this script will connect to this data source, create
  several tables, run various queries against them, and then drop them.

  Although this should not affect other applications, for safety's sake, use
  a test account or temporary data space, and avoid testing this on any
  mission-critical production systems.

.

sleep(1);
