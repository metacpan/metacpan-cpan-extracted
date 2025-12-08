#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  use FindBin;
  my $ScriptPath = "$FindBin::Bin/../bin/config-resolver.pl";
  require $ScriptPath;
}

use Test::More;
use File::Temp qw(tempfile);
use File::Spec;
use Config::Resolver::Utils qw(slurp_file);

use JSON qw(to_json from_json);

# --- Find our script and lib paths ---
my $Bin     = $FindBin::Bin;
my $Script  = File::Spec->catfile( $Bin, '..', 'bin', 'config-resolver.pl' );
my $LibPath = File::Spec->catfile( $Bin, '..', 'lib' );
my $Perl    = $^X;  # Get the path to the current perl executable

# --- Setup: Create a single, real params file for all tests ---
my $test_data = {
  foo => 'bar',
  baz => { nested => 'value' },
};
my ( $p_fh, $p_path ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
print $p_fh to_json($test_data);
close $p_fh;

# --- Test 1: Full dump (no -k) ---
subtest 'Test Case: End-to-end dump (full object)' => sub {

  # 1. --- Execute the real script ---
  # We test the default JSON output
  my $command       = "$Perl -I$LibPath $Script dump $p_path";
  my $script_output = qx($command);

  # 2. --- Verify the results ---
  is( $?, 0, 'Script exited successfully (exit code 0)' );

  # 3. --- Check the output ---
  # We must use from_json (from the main script) to parse the output
  # We don't care about the string. We check the data structure.
  is_deeply( from_json($script_output), $test_data, 'STDOUT is the correct data structure (as JSON)' );
};

# --- Test 2: Single key dump (with -k) ---
subtest 'Test Case: End-to-end dump (single key)' => sub {

  # 1. --- Execute the real script ---
  # We ask for a simple key
  my $command       = "$Perl -I$LibPath $Script dump -k foo $p_path";
  my $script_output = qx($command);

  # 2. --- Verify the results ---
  is( $?,             0,     'Script exited successfully (exit code 0)' );
  is( $script_output, 'bar', 'STDOUT is the correct simple string value' );
};

# --- Test 3: Single key dump (complex value) ---
subtest 'Test Case: End-to-end dump (complex key)' => sub {

  # 1. --- Execute the real script ---
  # We ask for a key whose *value* is a hash
  my $command       = "$Perl -I$LibPath $Script dump -k baz $p_path";
  my $script_output = qx($command);

  # 2. --- Verify the results ---
  is( $?, 0, 'Script exited successfully (exit code 0)' );

  # 3. --- Check the output ---
  # The script should (correctly) format the complex value as JSON
  # We don't care about the string. We check the data structure.
  is_deeply( from_json($script_output), $test_data->{baz}, 'STDOUT is the correct data structure for the nested hash' );
};

done_testing();

1;
