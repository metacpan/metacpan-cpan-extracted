#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  use FindBin;
  my $ScriptPath = "$FindBin::Bin/../bin/config-resolver.pl";
  require $ScriptPath;
}

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use YAML::Tiny qw(Dump);
use JSON qw(to_json);
use Config::Resolver::Utils qw(slurp_file);

# --- Find our script and lib paths ---
# We need to find the script to run, and the -I path for the subprocess
my $Bin     = $FindBin::Bin;
my $Script  = File::Spec->catfile( $Bin, '..', 'bin', 'config-resolver.pl' );
my $LibPath = File::Spec->catfile( $Bin, '..', 'lib' );

# --- Test 1: Full end-to-end manifest run ---
subtest 'Test Case: End-to-end manifest run' => sub {

  # 1. --- Setup the full "battlefield" ---
  my $temp_dir = tempdir( CLEANUP => 1 );

  # Create the params.json file
  my $params_path = File::Spec->catfile( $temp_dir, 'params.json' );
  open my $pfh, '>', $params_path or die "Could not write $params_path: $!";
  print $pfh to_json( { name => 'Integration Test' } );
  close $pfh;

  # Create the template.tpl file
  my $template_path = File::Spec->catfile( $temp_dir, 'template.tpl' );
  open my $tfh, '>', $template_path or die "Could not write $template_path: $!";
  print $tfh 'Hello, ${name}!';
  close $tfh;

  # Define the path for the file our script will create
  my $output_path = File::Spec->catfile( $temp_dir, 'output.conf' );

  # Create the manifest.yml file
  my $manifest_path = File::Spec->catfile( $temp_dir, 'manifest.yml' );
  my $manifest_data = {
    globals => { parameters => $params_path, },
    jobs    => [
      { template => $template_path,
        outfile  => $output_path,
      }
    ]
  };
  open my $mfh, '>', $manifest_path or die "Could not write $manifest_path: $!";
  print $mfh Dump($manifest_data);
  close $mfh;

  # 2. --- Execute the real script ---
  # We use qx() (backticks) to run this as a real shell command.
  # The -I flag is critical so the 'perl' subprocess can find
  # your Config::Resolver module.
  my $command = "perl -I$LibPath $Script resolve -m $manifest_path";

  # We run the command and capture any STDOUT/STDERR
  my $script_output = qx($command);

  # 3. --- Verify the results ---

  # Check 1: Did the script exit successfully?
  is( $?, 0, 'Script exited successfully (exit code 0)' );

  # Check 2: Did it print anything to STDOUT/STDERR?
  # (It shouldn't, since we used an outfile)
  is( $script_output, '', 'Script produced no unexpected output on STDOUT/STDERR' );

  # Check 3: The REAL proof. Did it create the file?
  ok( -e $output_path, 'Output file was successfully created' );

  # Check 4: The FINAL proof. Is the content correct?
  my $file_content = slurp_file($output_path);
  is( $file_content, 'Hello, Integration Test!', 'Output file content is correctly rendered' );
};

done_testing();

1;
