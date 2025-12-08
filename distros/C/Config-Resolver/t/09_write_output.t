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
use JSON qw(to_json);
use YAML::Tiny qw(Dump);
use IO::Scalar;
use Config::Resolver::Utils qw(slurp_file);

# --- Setup a Mock Class ---
{

  package MockCLI;
  our @ISA = qw(CLI::Config::Resolver);
  sub init { }

  # Stubs for all the accessors write_output uses
  sub get_outfile { $_[0]->{_mock_outfile} }
  sub get_umask   { $_[0]->{_mock_umask} }
  sub get_format  { $_[0]->{_mock_format} }
  sub get_pretty  { $_[0]->{_mock_pretty} }
}

my @option_specs = qw(
  outfile|o=s umask=s format=s pretty|P
);

# --- Helper sub to capture STDOUT ---
sub capture_stdout {
  my ($sub_to_run) = @_;

  my $stdout_capture = '';

  # 1. Create a new, in-memory filehandle
  #    that is tied to our scalar.
  my $mem_fh = IO::Scalar->new( \$stdout_capture );

  {
    # 2. Localize *STDOUT and point it to
    #    our in-memory filehandle.
    local *STDOUT = $mem_fh;

    # 3. Run the code. All STDOUT
    #    is now captured by $mem_fh.
    $sub_to_run->();
  }

  # STDOUT is automatically restored here

  return $stdout_capture;
}

# --- Create one mock object for all tests ---
my $mock = MockCLI->new(
  commands     => { resolve => sub { }, dump => sub { } },
  option_specs => \@option_specs,
);

# --- Test 1: Plain string to STDOUT ---
subtest 'Test Case: Plain string to STDOUT' => sub {
  $mock->{_mock_outfile} = undef;  # Ensure output to STDOUT

  my $output = capture_stdout(
    sub {
      $mock->write_output("Hello, World!");
    }
  );

  is( $output, "Hello, World!", 'Correctly prints plain string to STDOUT' );
};

# --- Test 2: Hash to STDOUT (compact JSON) ---
subtest 'Test Case: Hash to STDOUT (JSON default)' => sub {
  $mock->{_mock_outfile} = undef;
  $mock->{_mock_format}  = 'json';
  $mock->{_mock_pretty}  = 0;

  my $hash_data     = { a => 1, b => 2 };
  my $expected_json = to_json( $hash_data, { pretty => 0, allow_blessed => 1, convert_blessed => 1 } );

  my $output = capture_stdout(
    sub {
      $mock->write_output($hash_data);
    }
  );

  is( $output, $expected_json, 'Correctly prints compact JSON to STDOUT' );
};

# --- Test 3: Hash to STDOUT (pretty JSON) ---
subtest 'Test Case: Hash to STDOUT (pretty JSON)' => sub {
  $mock->{_mock_outfile} = undef;
  $mock->{_mock_format}  = 'json';
  $mock->{_mock_pretty}  = 1;      # Turn on pretty

  my $hash_data     = { a => 1, b => 2 };
  my $expected_json = to_json( $hash_data, { pretty => 1, allow_blessed => 1, convert_blessed => 1 } );

  my $output = capture_stdout(
    sub {
      $mock->write_output($hash_data);
    }
  );

  is( $output, $expected_json, 'Correctly prints pretty JSON to STDOUT' );
};

# --- Test 4: Hash to STDOUT (YAML) ---
subtest 'Test Case: Hash to STDOUT (YAML)' => sub {
  $mock->{_mock_outfile} = undef;
  $mock->{_mock_format}  = 'yml';

  my $hash_data     = { a => 1, b => 2 };
  my $expected_yaml = Dump($hash_data);

  my $output = capture_stdout(
    sub {
      $mock->write_output($hash_data);
    }
  );

  is( $output, $expected_yaml, 'Correctly prints YAML to STDOUT' );
};

# --- Test 5: Hash to file (with umask) ---
subtest 'Test Case: Hash to file with umask' => sub {

  # 1. Create a temp *filename*, but not the file itself
  # UNLINK => 1 means it will be deleted after the test
  my ( undef, $temp_file ) = tempfile( UNLINK => 1 );

  $mock->{_mock_outfile} = $temp_file;
  $mock->{_mock_format}  = 'json';
  $mock->{_mock_pretty}  = 0;
  $mock->{_mock_umask}   = '0077';     # Set a very restrictive umask

  my $hash_data     = { a => 1, b => 2 };
  my $expected_json = to_json( $hash_data, { pretty => 0, allow_blessed => 1, convert_blessed => 1 } );

  # 2. Run the sub -- this will create the file
  $mock->write_output($hash_data);

  # 3. Test the file's *content*
  my $file_content = slurp_file($temp_file);
  is( $file_content, $expected_json, 'File content is correct' );

  # 4. Test the file's *permissions*
  # (stat($file))[2] returns the mode
  my $mode = ( stat($temp_file) )[2] & 0777;
  # A umask of 0077 on a file (default 0666) should be 0600
  my $expected_mode = 0600;  # (rw-------)

  is( $mode, $expected_mode, 'File permissions are correctly set by umask 0077' );
};

done_testing();

1;
