#!perl -T

use Test::More;
use Test::Exception;
use Test::Moose;
use strict;
use warnings;

BEGIN {
  use_ok ( "DBIx::Error" );
}

# Construction and basic attributes
{
  my $err;

  # Construction
  lives_ok { $err = DBIx::Error->new ( message => "Test error",
				       err => "12345",
				       errstr => "Error string",
				       state => "12345" ) };

  # Stringification
  ok ( $err =~ /^Test error$/m );

  # Stack trace attribute
  has_attribute_ok ( $err, "stack_trace" );

  # Throwing
  throws_ok { $err->throw() } "DBIx::Error";
}

# Exception class generation
{
  my $class;

  # Known SQLSTATE - unique constraint violation
  lives_ok { $class = DBIx::Error->exception_class ( "23505" ) };
  isa_ok ( $class, "DBIx::Error::UniqueViolation" );
  isa_ok ( $class, "DBIx::Error::IntegrityConstraintViolation" );
  isa_ok ( $class, "DBIx::Error" );

  # Known SQLSTATE - serialization failure
  lives_ok { $class = DBIx::Error->exception_class ( "40001" ) };
  isa_ok ( $class, "DBIx::Error::SerializationFailure" );
  isa_ok ( $class, "DBIx::Error::TransactionRollback" );
  isa_ok ( $class, "DBIx::Error" );

  # Generic SQLSTATE - feature not supported
  lives_ok { $class = DBIx::Error->exception_class ( "0A000" ) };
  isa_ok ( $class, "DBIx::Error::FeatureNotSupported" );
  isa_ok ( $class, "DBIx::Error" );

  # Unknown SQLSTATE within known generic SQLSTATE class
  lives_ok { $class = DBIx::Error->exception_class ( "20962" ) };
  isa_ok ( $class, "DBIx::Error::CaseNotFound" );
  isa_ok ( $class, "DBIx::Error" );

  # Unknown SQLSTATE within unknown generic SQLSTATE class
  lives_ok { $class = DBIx::Error->exception_class ( "ZW098" ) };
  isa_ok ( $class, "DBIx::Error" );
}

done_testing();
