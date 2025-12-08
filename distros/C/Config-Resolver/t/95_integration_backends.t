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
use JSON qw(to_json);
use Config::Resolver::Utils qw(slurp_file);

# --- Find our script and lib paths ---
my $Bin     = $FindBin::Bin;
my $Script  = File::Spec->catfile( $Bin, '..', 'bin', 'config-resolver.pl' );
my $LibPath = File::Spec->catfile( $Bin, '..', 'lib' );
my $Perl    = $^X;  # Get the path to the current perl executable

# --- Test 1: Full end-to-end "batteries included" run ---
subtest 'Test Case: End-to-end built-in backends (env and file)' => sub {

  # 1. --- Setup the "battlefield" ---

  # Create the "secret" file for file://
  my $secret_value = "Hallelujah, this is the secret!";
  my ( $secret_fh, $secret_path ) = tempfile( UNLINK => 1 );
  print $secret_fh $secret_value;
  close $secret_fh;

  # Create the params.json file
  my ( $p_fh, $p_path ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
  print $p_fh to_json(
    { my_env_var  => 'env://MY_TEST_ENV_VAR',
      my_file_var => "file://$secret_path",
    }
  );
  close $p_fh;

  # Create the template
  my ( $t_fh, $t_path ) = tempfile( SUFFIX => '.tpl', UNLINK => 1 );
  print $t_fh "ENV_TEST: \${my_env_var}\nFILE_TEST: \${my_file_var}";
  close $t_fh;

  # 2. --- Execute the real script ---
  my $command = "$Perl -I$LibPath $Script resolve -p $p_path -t $t_path";

  # We must run this inside a 'local' block to set the ENV var
  my $script_output;
  {
    local $ENV{MY_TEST_ENV_VAR} = 'pass the mashed potatoes';
    $script_output = qx($command 2>&1);
  }  # $ENV is restored here

  # 3. --- Verify the results ---

  # Check 1: Did the script exit successfully?
  is( $?, 0, 'Script exited successfully (exit code 0)' )
    or diag("Script Output: $script_output");

  # Check 2: The FINAL proof. Is the content correct?
  my $expected_content = "ENV_TEST: pass the mashed potatoes\n" . "FILE_TEST: $secret_value";

  is( $script_output, $expected_content, 'Output string is correctly rendered from env:// and file://' );
};

done_testing();

1;
