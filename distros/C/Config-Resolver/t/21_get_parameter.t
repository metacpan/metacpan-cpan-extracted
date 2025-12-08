#!/usr/bin/env perl
use strict;
use warnings;

# --- Load the ENGINE, not the script ---
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Config::Resolver;
use Data::Dumper;

my $params = {
  greeting => 'hello',
  path     => { to => { value => 'world' } },
  servers  => [ { name => 'app01' }, { name => 'app02' } ],
};

# --- Test 1: Simple path traversal ---
subtest 'Test Case: Simple path (calls get_value)' => sub {
  my $resolver = Config::Resolver->new();

  my $result = $resolver->get_parameter( $params, 'path.to.value' );
  is( $result, 'world', 'Correctly traverses a simple dot-notation path' );

  $result = $resolver->get_parameter( $params, 'servers[1].name' );
  is( $result, 'app02', 'Correctly traverses a path with an array index' );
};

# --- Test 2: Base "allow-list" function (uc) ---
subtest 'Test Case: Base function (uc)' => sub {
  my $resolver = Config::Resolver->new();

  my $result = $resolver->get_parameter( $params, 'uc(greeting)' );
  is( $result, 'HELLO', 'Correctly calls the default "uc" function' );
};

# --- Test 3: Custom "allow-list" function ---
subtest 'Test Case: Custom function (from new())' => sub {
  # Test the 'functions' key in new() [cite: 313-315]
  my $resolver = Config::Resolver->new( functions => { 'reverse' => sub { return scalar reverse( $_[0] // '' ) }, } );

  my $result = $resolver->get_parameter( $params, 'reverse(greeting)' );
  is( $result, 'olleh', 'Correctly calls a user-injected "reverse" function' );
};

# --- Test 4: Disallowed function (croaks) ---
subtest 'Test Case: Disallowed function (croaks)' => sub {
  my $resolver = Config::Resolver->new();

  # The 'dies' test passes if the code inside it 'croak's
  eval { $resolver->get_parameter( $params, 'reverse(greeting)' ) };

  # Check that it croaked with the correct error
  like( $@, qr/ERROR: function 'reverse' is not permitted/, 'Correctly croaks when calling a non-allowed function' );
};

done_testing();

1;
