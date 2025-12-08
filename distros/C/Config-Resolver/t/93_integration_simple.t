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
use JSON qw(to_json from_json);

# --- Find our script and lib paths ---
my $Bin     = $FindBin::Bin;
my $Script  = File::Spec->catfile( $Bin, '..', 'bin', 'config-resolver.pl' );
my $LibPath = File::Spec->catfile( $Bin, '..', 'lib' );
my $Perl    = $^X;

# --- Test 1: Simple resolve (no manifest) ---
subtest 'Test Case: End-to-end simple resolve (-p and -t)' => sub {

  # 1. --- Setup the full "battlefield" ---
  my ( $p_fh, $p_path ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
  print $p_fh to_json( { name => 'Simple Resolve' } );
  close $p_fh;

  my ( $t_fh, $t_path ) = tempfile( SUFFIX => '.tpl', UNLINK => 1 );
  print $t_fh 'Rendered: ${name}';
  close $t_fh;

  # 2. --- Execute the real script ---
  # This time, we are not using a manifest.
  # We are testing the -p and -t flags directly.
  # Output should go to STDOUT.
  my $command       = "$Perl -I$LibPath $Script resolve -p $p_path -t $t_path";
  my $script_output = qx($command);

  # 3. --- Verify the results ---

  # Check 1: Did the script exit successfully?
  is( $?, 0, 'Script exited successfully (exit code 0)' );

  # Check 2: The FINAL proof. Is the STDOUT content correct?
  is( $script_output, 'Rendered: Simple Resolve', 'STDOUT content is correctly rendered' );
};

# --- Test 2: Simple resolve (no template) ---
subtest 'Test Case: End-to-end simple resolve (no -t)' => sub {

  # 1. --- Setup ---
  my $test_data = { name => 'Simple Resolve', foo => 'bar' };
  my ( $p_fh, $p_path ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
  print $p_fh to_json($test_data);
  close $p_fh;

  # 2. --- Execute ---
  # We are testing the "no template" branch of resolve()
  # This should dump the resolved parameters hash to STDOUT
  # (and it will be compact JSON because of our 'format=s' fix)
  my $command       = "$Perl -I$LibPath $Script resolve -p $p_path";
  my $script_output = qx($command);

  # 3. --- Verify ---
  is( $?, 0, 'Script exited successfully (exit code 0)' );

  # 4. --- Check the data (not the string) ---
  is_deeply( from_json($script_output), $test_data, 'STDOUT is the correct, resolved parameters hash (as JSON)' );
};

done_testing();

1;
