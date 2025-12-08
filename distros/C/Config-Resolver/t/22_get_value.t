#!/usr/bin/env perl
use strict;
use warnings;

# --- Load the ENGINE, not the script ---
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Config::Resolver;
use Data::Dumper;

# --- Setup a Mock Object ---
# We just need a "dumb" object to call the method on
my $resolver = Config::Resolver->new();

# This is the data structure we will traverse
my $params = {
  foo     => { bar => 'baz' },
  servers => [ { name => 'app01', ip => '10.0.0.1' }, { name => 'app02', ip => '10.0.0.2' }, ],
  simple  => 'value',
};

# --- Test 1: Simple hash traversal ---
subtest 'Test Case: Simple hash path' => sub {
  my $result = $resolver->get_value( $params, 'foo.bar' );
  is( $result, 'baz', 'Correctly traverses simple dot-notation' );
};

# --- Test 2: Array index traversal ---
subtest 'Test Case: Array index path' => sub {
  my $result = $resolver->get_value( $params, 'servers[0].name' );
  is( $result, 'app01', 'Correctly traverses path with array index [0]' );

  $result = $resolver->get_value( $params, 'servers[1].ip' );
  is( $result, '10.0.0.2', 'Correctly traverses path with array index [1]' );
};

# --- Test 3: Top-level key ---
subtest 'Test Case: Top-level key' => sub {
  my $result = $resolver->get_value( $params, 'simple' );
  is( $result, 'value', 'Correctly returns a top-level key' );
};

# --- Test 4: Missing path ---
subtest 'Test Case: Missing path' => sub {
  my $result = $resolver->get_value( $params, 'foo.bar.nonexistent' );
  is( $result, undef, 'Correctly returns undef for a missing deep path' );

  $result = $resolver->get_value( $params, 'badkey' );
  is( $result, undef, 'Correctly returns undef for a missing top-level path' );
};

# --- Test 5: Mixed path ---
subtest 'Test Case: Path with key and index on same part' => sub {
  # This tests the 'is_key_or_idx' helper [cite: 289-292]
  my $result = $resolver->get_value( $params, 'servers[0]' );
  is_deeply( $result, { name => 'app01', ip => '10.0.0.1' }, 'Correctly returns a hash from an array index' );
};

done_testing();

1;
