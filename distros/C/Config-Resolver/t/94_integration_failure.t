#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  use FindBin;
  my $ScriptPath = "$FindBin::Bin/../bin/config-resolver.pl";
  require $ScriptPath;
}

use Test::More;
use File::Temp qw(tempfile tempdir);
use File::Spec;
use YAML::Tiny qw(Dump);

# --- Find our script and lib paths ---
my $Bin     = $FindBin::Bin;
my $Script  = File::Spec->catfile( $Bin, '..', 'bin', 'config-resolver.pl' );
my $LibPath = File::Spec->catfile( $Bin, '..', 'lib' );
my $Perl    = $^X;

# --- Test 1: Non-existent manifest file ---
subtest 'Test Case: Failure (missing manifest file)' => sub {

  # 1. --- Setup ---
  my $non_existent_file = "/tmp/this-file-had-better-not-exist-ABC123.yml";

  # 2. --- Execute the real script ---
  # We run a command that is *guaranteed* to fail.
  # We must also capture STDERR.
  my $command       = "$Perl -I$LibPath $Script resolve -m $non_existent_file 2>&1";
  my $script_output = qx($command);

  # 3. --- Verify the results ---

  # Check 1: Did the script exit with a non-zero code?
  # $? is the exit code. 0 is success. Anything else is failure.
  isnt( $?, 0, 'Script correctly exited with a non-zero status' );

  # Check 2: Did it print the correct error to STDERR?
  like( $script_output, qr/ERROR: manifest file not found:/, 'STDERR output correctly contains the "file not found" error' );
};

# --- Test 2: Non-existent parameter file (from manifest) ---
subtest 'Test Case: Failure (missing parameter file in job)' => sub {

  # 1. --- Setup ---
  # This time, we create a *valid* manifest that *points* to a non-existent file.
  my $non_existent_params = "/tmp/this-also-should-not-exist-XYZ987.json";

  my ( $mf_fh, $mf_path ) = tempfile( SUFFIX => '.yml', UNLINK => 1 );
  print $mf_fh Dump(
    { jobs => [
        { parameters => $non_existent_params,
          template   => 'template.tpl',
          outfile    => 'output.conf',
        }
      ]
    }
  );
  close $mf_fh;

  # 2. --- Execute ---
  my $command       = "$Perl -I$LibPath $Script resolve -m $mf_path 2>&1";
  my $script_output = qx($command);

  # 3. --- Verify ---
  isnt( $?, 0, 'Script correctly exited with a non-zero status' );

  like(
    $script_output,
    qr/ERROR: parameter file not found:/,
    'STDERR output correctly contains the "parameter file not found" error'
  );
};

done_testing();

1;
