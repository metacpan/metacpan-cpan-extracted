#!perl -T

our $bindir;
use FindBin;
BEGIN { ( $bindir ) = ( $FindBin::Bin =~ /^(.*)$/ ) } # Untaint
use lib $bindir."/lib";

use Test::More;
use Test::Exception;
use Test::Moose;
use TestDBIx::Error;
use strict;
use warnings;

BEGIN {
  use_ok ( "TestDBIx::Error" );
}

# Construction and basic attributes
{
  my $err;

  # Construction
  lives_ok { $err = TestDBIx::Error->new ( message => "Test error",
					   err => "12345",
					   errstr => "Error string",
					   state => "12345" ) };

  # Stringification
  ok ( $err =~ /^Test error$/m );

  # Stack trace attribute
  has_attribute_ok ( $err, "stack_trace" );

  # Throwing
  throws_ok { $err->throw() } "TestDBIx::Error";
}

# Exception class generation
{
  my $class;

  # Custom exception class - specific SQLSTATE
  lives_ok { $class = TestDBIx::Error->exception_class ( "TS001" ) };
  isa_ok ( $class, "TestDBIx::Error::Specific" );
  isa_ok ( $class, "TestDBIx::Error::General" );
  isa_ok ( $class, "DBIx::Error" );

  # Custom exception class - generic SQLSTATE
  lives_ok { $class = TestDBIx::Error->exception_class ( "TS000" ) };
  isa_ok ( $class, "TestDBIx::Error::General" );
  isa_ok ( $class, "DBIx::Error" );

  # Custom exception class - unknown SQLSTATE
  lives_ok { $class = TestDBIx::Error->exception_class ( "TS999" ) };
  isa_ok ( $class, "TestDBIx::Error::General" );
  isa_ok ( $class, "DBIx::Error" );

  # Predefined exception class
  lives_ok { $class = TestDBIx::Error->exception_class ( "23505" ) };
  isa_ok ( $class, "DBIx::Error::UniqueViolation" );
  isa_ok ( $class, "DBIx::Error::IntegrityConstraintViolation" );
  isa_ok ( $class, "DBIx::Error" );

  # Unknown exception class
  lives_ok { $class = TestDBIx::Error->exception_class ( "QX962" ) };
  isa_ok ( $class, "DBIx::Error" );
}

done_testing();
