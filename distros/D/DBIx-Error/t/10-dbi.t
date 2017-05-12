#!perl -T

our $bindir;
use FindBin;
BEGIN { ( $bindir ) = ( $FindBin::Bin =~ /^(.*)$/ ) } # Untaint
use lib $bindir."/lib";

use Test::More;
use Test::Exception;
use TestDB;
use DBI;
use strict;
use warnings;

BEGIN {
  use_ok ( "DBIx::Error" );
}

# Connect to database
my $dbh;
lives_ok { $dbh = DBI->connect ( TestDSN, TestUsername, TestPassword,
				 { HandleError => DBIx::Error->HandleError,
				   HandleSetErr => TestHandleSetErr } ) };

# Unique constraint violation
{
  $dbh->begin_work();
  lives_ok { $dbh->do ( "INSERT INTO test ( id, name ) VALUES ( 1, 'Me' )" ) };
  throws_ok { $dbh->do ( "INSERT INTO test ( id, name ) VALUES ( 1, 'You' )" ) }
      "DBIx::Error::UniqueViolation";
  $dbh->rollback();
}

# Not-null constraint violation
{
  $dbh->begin_work();
  throws_ok { $dbh->do ( "INSERT INTO test ( id, name ) VALUES ( 1, NULL )" ) }
      "DBIx::Error::NotNullViolation";
  $dbh->rollback();
}

done_testing();
