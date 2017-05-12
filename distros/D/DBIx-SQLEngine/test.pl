#!/usr/bin/perl

use Test::Harness;
use File::Find;
use ExtUtils::MakeMaker;

unshift @INC, qw( blib/arch blib/lib );
$Test::Harness::verbose = $ENV{TEST_VERBOSE} || 0;

my $separator = ( '=' x 79 ) . "\n";

########################################################################

sub get_tests {
  my @t;
  find( sub { /\.t\z/ and push @t, $File::Find::name }, @_ );
  return sort { lc $a cmp lc $b } @t
	or die "$0: Can't find any tests in @_\n";
}

@t_all = get_tests( 'test_core' );

@t_dsn = get_tests( 'test_drivers' );

########################################################################

my $has_config = -f 'test.cfg';
if ( $has_config ) {
  open( CNXNS, 'test.cfg' ) or die $!;
  @dsns = <CNXNS>;
  chomp @dsns;
  close( CNXNS ) or die $!;
}

( -d "test_data" ) or mkdir("test_data"); 

########################################################################

my $count_dsns = scalar @dsns;
if ( $has_config ) {
  print <<".";
You have $count_dsns local driver connection strings listed in test.cfg.
You can edit these by running perl test_cfg.pl
.
} else {
  print <<".";

About SQLEngine Driver Tests

  DBIx::SQLEngine includes a number of tests which can be run against your local
  database drivers. You can specify one or more connections to test, each with 
  its own DSN and optionally also a user name, password, and DBI attributes.
  
  Using each of the specified connections, the driver test scripts will
  create tables with "sqle_test" in their names, run various queries
  against those tables, and then drop them.
  
  (Although this should not affect other database tables or applications, 
  for safety's sake please use a test account or temporary database, and 
  do not run tests against any mission-critical production data sources.)
  
  You can define connections interactively by running test_cfg.pl, or you
  can directly edit the test.cfg file to list one DSN on each line.

.

  $yn = prompt("Do you want to define a list of DSNs to test against?", "N");

  if ( $yn !~ /\S/ or $yn =~ /n/i ) {
    open( CNXNS, '>test.cfg' ) and close( CNXNS );
  } else {
    do "test_cfg.pl" or die $@;
  }
}

########################################################################

# define_named_connections_from_text

print $separator;

if ( scalar(@dsns) ) {
  warn "Running " . ( scalar(@t_all) + scalar(@t_dsn) * scalar(@dsns)  ) . " tests: " . scalar(@t_all) . " core tests plus " . scalar(@t_dsn) . " tests for use with each of " . scalar(@dsns) . " DSNs.\n";
} else {
  warn "Running " . ( scalar(@t_all) ) . " tests: " . scalar(@t_all) . " core tests, no driver tests.\n";
}

########################################################################

CORE_TESTS: {

  print $separator;
  
  local $ENV{DBI_DSN}="";
  Test::Harness::runtests( @t_all );
}

foreach my $dsn ( @dsns ) {

  print $separator;
  print "Starting Driver Tests For: $dsn\n";

  if ( $dsn =~ m{(test_data/\w+)} ) {
    unless ( -d $1 ) {
      warn "Creating test data directory:  $1\n";
      mkdir $1;
    }
  }

  $ENV{DBI_DSN} = "$dsn";

  eval {
    Test::Harness::runtests( @t_dsn );
  };
  if ( $@ ) {
    warn "Failure: $@"
  }

}

print $separator;
