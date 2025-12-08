#!/usr/bin/env perl

use strict;
use warnings;

# --- Load the ENGINE, not the script ---
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use Config::Resolver;
use File::Temp qw(tempfile);
use Data::Dumper;

# --- Test 1: env:// handler ---
subtest 'Test Case: Engine - base env:// handler' => sub {
  my $resolver = Config::Resolver->new();
  my $expected = 'hallelujah';

  # Use 'local' to safely set an ENV var for this test
  my $result;
  {
    local $ENV{MY_TEST_VAR} = $expected;
    ( $result, undef ) = $resolver->resolve_value( 'env://MY_TEST_VAR', {} );
  }  # $ENV{MY_TEST_VAR} is restored here

  is( $result, $expected, 'Correctly resolves value from $ENV' );
};

# --- Test 2: file:// handler ---
subtest 'Test Case: Engine - base file:// handler' => sub {
  my $resolver = Config::Resolver->new();
  my $expected = 'pass the mashed potatoes';

  # Create a real, temporary file
  my ( $fh, $file_name ) = tempfile( UNLINK => 1 );
  print $fh $expected;
  close $fh;

  # Test the file:// protocol
  my ( $result, undef ) = $resolver->resolve_value( "file://$file_name", {} );

  is( $result, $expected, 'Correctly slurps file content with file://' );
};

# --- Test 3: User 'backends' override base 'env://' ---
subtest 'Test Case: Engine - user backends override base' => sub {
  # This proves the merge order is correct
  my $resolver = Config::Resolver->new(
    backends => {
      'env' => sub {
        my ( $path, $params ) = @_;
        return "OVERRIDDEN($path)";
      }
    }
  );

  my ( $result, undef ) = $resolver->resolve_value( 'env://ANYTHING', {} );

  is( $result, 'OVERRIDDEN(ANYTHING)', 'User-defined backend correctly overrides base env://' );
};

done_testing();

1;
