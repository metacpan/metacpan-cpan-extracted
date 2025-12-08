#!/usr/bin/env perl
use strict;
use warnings;

# --- Load the ENGINE, not the script ---
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Config::Resolver;
use Data::Dumper;

# --- Test 1: Simple Variable ${...} Expansion ---
subtest 'Test Case: Engine - Simple ${var} expansion' => sub {
  my $resolver = Config::Resolver->new( warning_level => 'warn' );
  my $params   = { foo => 'bar', baz => 123 };

  my ( $result, undef ) = $resolver->resolve_value( 'Hello, ${foo}!', $params );

  is( $result, 'Hello, bar!', 'Correctly resolves a simple ${...} variable' );
};

# --- Test 2: Ternary Operator ---
subtest 'Test Case: Engine - Ternary operator' => sub {
  my $resolver = Config::Resolver->new();
  my $params   = { env => 'prod' };

  my $template = '${env eq "prod" ? "PROD_DB" : "DEV_DB"}';
  my ( $result, undef ) = $resolver->resolve_value( $template, $params );

  is( $result, 'PROD_DB', 'Correctly resolves ternary (true case)' );

  $params->{env} = 'dev';
  ( $result, undef ) = $resolver->resolve_value( $template, $params );
  is( $result, 'DEV_DB', 'Correctly resolves ternary (false case)' );
};

# --- Test 3: Protocol Handler (using a mock) ---
subtest 'Test Case: Engine - Protocol handler' => sub {
  # We test the protocol logic using the 'backends' shim
  my $resolver = Config::Resolver->new(
    backends => {
      'test' => sub {
        my ( $path, $params ) = @_;
        return "RESOLVED($path)";
      }
    }
  );

  my ( $result, undef ) = $resolver->resolve_value( 'test://foo/bar', {} );

  is( $result, 'RESOLVED(foo/bar)', 'Correctly dispatches to protocol handler' );
};

# --- Test 4: Mixed resolution order ---
subtest 'Test Case: Engine - Mixed (Protocol wins)' => sub {
  # This proves that protocols run BEFORE ${...} expansion
  my $resolver = Config::Resolver->new(
    backends => {
      'test' => sub { return '${this_is_literal}' }
    }
  );

  # The 'test://' protocol runs first and returns a string.
  # The resolver should NOT run a second pass.
  my ( $result, undef ) = $resolver->resolve_value( 'test://foo', { this_is_literal => 'FAIL' } );

  is( $result, '${this_is_literal}', 'Correctly resolves protocol and stops' );
};

done_testing();

1;
