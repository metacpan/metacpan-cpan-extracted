#!perl -T

our $bindir;
use FindBin;
BEGIN { ( $bindir ) = ( $FindBin::Bin =~ /^(.*)$/ ) } # Untaint
use lib $bindir."/lib";

use Test::More;
use Test::Exception;
use TestDB;
use TestDB::Schema;
use TestError;
use strict;
use warnings;

BEGIN {
  use_ok ( "DBIx::Error" );
}

# Connect to database
my $db;
lives_ok { $db = TestDB::Schema->connect ( {
  dsn => TestDSN,
  user => TestUsername,
  password => TestPassword,
  HandleError => DBIx::Error->HandleError,
  HandleSetErr => TestHandleSetErr,
  unsafe => 1,
} ) };
my $rs = $db->resultset ( "Test" );

# Unique constraint violation
{
  throws_ok {
    $db->txn_do ( sub {
      $rs->create ( { id => 1, name => "Me" } );
      $rs->create ( { id => 1, name => "You" } );
    } );
  } "DBIx::Error::UniqueViolation";
}

# Not-null constraint violation
{
  throws_ok {
    $db->txn_do ( sub {
      $rs->create ( { id => 1, name => undef } );
    } );
  } "DBIx::Error::NotNullViolation";
}

# Bulk operation
{
  # Ideally this would throw a UniqueViolation; see CAVEATS in
  # DBIx::Error documentation for why this doesn't happen.
  throws_ok {
    $db->txn_do ( sub {
      $rs->populate ( [ [ qw ( id name ) ],
			[ 1, "Me" ],
			[ 1, "You" ] ] );
    } );
  } "DBIx::Error";
}

# Non-DBI exceptions within transaction blocks
{
  throws_ok {
    $db->txn_do ( sub {
      TestError->throw ( "Should not get reclassed" );
    } );
  } "TestError";
}

done_testing();
