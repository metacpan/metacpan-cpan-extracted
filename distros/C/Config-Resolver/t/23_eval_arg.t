#!/usr/bin/env perl
use strict;
use warnings;

# --- Load the ENGINE, not the script ---
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Config::Resolver;
use Data::Dumper;

# --- Setup a Mock Class ---
{

  package MockResolver;
  our @ISA = qw(Config::Resolver);

  # We don't need to override init, new() is fine

  # Spy: We'll spy on get_parameter
  # which eval_arg calls for variables
  sub get_parameter {
    my ( $self, $params, $path ) = @_;

    $self->{_called_get_parameter} = $path;  # Record what path it asked for

    # Return a known value
    if ( $path eq 'path.to.var' ) {
      return 'FROM_VARIABLE';
    }
    return 'UNKNOWN_VARIABLE';
  }
}

# --- Create one mock object for all tests ---
my $mock   = MockResolver->new();
my $params = { foo => 'bar' };    # A dummy hash

# --- Test 1: Parses a number ---
subtest 'Test Case: Parses a number' => sub {
  my $result = $mock->eval_arg( '123', $params );
  is( $result, 123, 'Correctly returns a number' );
};

# --- Test 2: Parses a single-quoted string ---
subtest 'Test Case: Parses a single-quoted string' => sub {
  my $result = $mock->eval_arg( "'hello'", $params );
  is( $result, 'hello', 'Correctly parses a single-quoted string' );
};

# --- Test 3: Parses a double-quoted string ---
subtest 'Test Case: Parses a double-quoted string' => sub {
  my $result = $mock->eval_arg( '"world"', $params );
  is( $result, 'world', 'Correctly parses a double-quoted string' );
};

# --- Test 4: Parses a variable path ---
subtest 'Test Case: Parses a variable path' => sub {
  $mock->{_called_get_parameter} = undef;  # Reset the spy

  my $result = $mock->eval_arg( 'path.to.var', $params );

  is( $result,                        'FROM_VARIABLE', 'Correctly returns value from get_parameter' );
  is( $mock->{_called_get_parameter}, 'path.to.var',   'Spy confirms get_parameter was called' );
};

# --- Test 5: Parses escaped quotes (from docs) ---
subtest 'Test Case: Parses escaped quotes' => sub {
  my $result = $mock->eval_arg( q{"hello\'world"}, $params );
  is( $result, q{hello'world}, 'Correctly parses escaped single quote' );

  $result = $mock->eval_arg( q{'hello\"world'}, $params );
  is( $result, q{hello"world}, 'Correctly parses escaped double quote' );
};

done_testing();

1;
