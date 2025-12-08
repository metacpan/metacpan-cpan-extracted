#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Data::Dumper;
use English qw(-no_match_vars);
use Config::Resolver;

########################################################################
subtest '1. function call: basic (uc)' => sub {
########################################################################
  # This tests the built-in 'uc' function from the base map

  my $resolver = Config::Resolver->new( debug => 0 );

  my $result = $resolver->resolve( '${uc(greeting)}', { greeting => 'hello' } );

  is( $result, 'HELLO', 'built-in uc() works' );
};

########################################################################
subtest '2. function call: injected (custom_func)' => sub {
########################################################################
  # This is the KEY test for our new feature.
  # We are "injecting" a new, allowed function.
  my $resolver
    = Config::Resolver->new( functions => { 'reverse' => sub { return scalar reverse( $_[0] // '' ) } } );

  my $result = $resolver->resolve( '${reverse(greeting)}', { greeting => 'hello' } );

  is( $result, 'olleh', 'injected function "reverse" works' );
};

########################################################################
subtest '3. function call: injection override (uc)' => sub {
########################################################################
  # This tests that an injected function can OVERRIDE a base one

  my $resolver = Config::Resolver->new(
    functions => {
      'uc' => sub { return 'OVERRIDDEN' },  # User overrides 'uc'
    }
  );

  my $result = $resolver->resolve( '${uc(greeting)}', { greeting => 'hello' } );

  is( $result, 'OVERRIDDEN', 'injected function overrides base "uc"' );
};

########################################################################
subtest '4. function call: NOT ALLOWED' => sub {
########################################################################
  # This tests that our "allow-list" is secure and correctly croaks
  my $resolver = Config::Resolver->new();

  # We use an 'eval' block to catch the expected 'croak'
  my $result = eval {
    $resolver->resolve(
      '${reverse(greeting)}',  # 'reverse' is not in the base map
      { greeting => 'hello' }
    );
  };

  # $result should be undef, and $EVAL_ERROR ($@) should be set
  ok( !$result && $EVAL_ERROR, 'resolver croaks on non-allowed function' );
  like( $EVAL_ERROR, qr/function 'reverse' is not permitted/, 'error message is correct' );
};

########################################################################
subtest '5. ternary: stability (no-eval check)' => sub {
########################################################################
  # This tests our 'eval'-free ternary refactor.
  # We are passing a value with a double-quote, which would have
  # caused a syntax error in the old string-based eval.
  my $resolver = Config::Resolver->new();

  my $result = $resolver->resolve( '${name eq "John \"Quote\" Doe" ? "IS_JOHN" : "NOT_JOHN"}', { name => 'John "Quote" Doe' } );

  is( $result, 'IS_JOHN', 'ternary handles quotes in value safely' );

  # And test the other side
  $result = $resolver->resolve( '${name eq "Other" ? "IS_JOHN" : "NOT_JOHN"}', { name => 'John "Quote" Doe' } );

  is( $result, 'NOT_JOHN', 'ternary handles quotes in value safely (false)' );
};

########################################################################
subtest '6. ternary: invalid operator' => sub {
########################################################################
  # This tests our dispatch hash safety check
  my $resolver = Config::Resolver->new();

  my $result = eval {
    $resolver->resolve(
      '${name xor "prod" ? "a" : "b"}',  # 'xor' is not a valid operator
      { name => 'prod' }
    );
  };

  ok( !$result && $EVAL_ERROR, 'resolver croaks on invalid ternary operator' );

  like( $EVAL_ERROR, qr/Invalid operator xor/, 'error message for operator is correct' )
    or diag($EVAL_ERROR);
};

done_testing;

1;
