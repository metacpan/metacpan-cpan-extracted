#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Warn;  # We'll use this to test our warning messages
use English qw(-no_match_vars);
use Data::Dumper;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
  use FindBin;

  my $ScriptPath = "$FindBin::Bin/../bin/config-resolver.pl";

  require $ScriptPath;
}

my $EMPTY_HOME = tempdir( CLEANUP => 1 );

# --- Setup a Mock Class ---
# We need to test the _build_plugin_config method.
# But that method calls $self->fetch_file and $self->get_plugin.
#
# We will create a simple "Mock" class that *inherits* from your real class.
# This lets us override just those two methods to return whatever
# test data we want.
{

  package MockCLI;
  use Data::Dumper;
  our @ISA = qw(CLI::Config::Resolver);

  # Override init to do nothing
  sub init { }

  # Stub: Call the REAL fetch_file from the parent
  sub fetch_file {
    my ( $self, $file ) = @_;
    return $self->SUPER::fetch_file($file);
  }

  # Stub: Return our mock CLI argument array
  sub get_plugin {
    my ($self) = @_;
    return $self->{_mock_plugin_args};
  }
}

my @option_specs = qw(
  parameter
  warning-level|w
  debug|g
  plugins
  resolver
  parameters
  parameter-file
  dump
  resolve
);

# --- Test 2: The "Empty" Case ---
# Test what happens with no RC file and no CLI args.
subtest 'Test Case: Empty config' => sub {
  my $mock = MockCLI->new(
    commands      => { foo => sub { return 0; } },
    option_specs  => \@option_specs,
    extra_options => ['parameters_hash'],
  );

  $mock->{_mock_rc}          = undef;
  $mock->{_mock_plugin_args} = [];

  my $config;

  {
    local $ENV{HOME} = $EMPTY_HOME;
    $config = $mock->_build_plugin_config();
  }

  is_deeply( $config, {}, 'Returns an empty hash for no input' );
};

# --- Test 3: The "CLI Only" Case ---
# Test parsing a couple of CLI arguments.
subtest 'Test Case: CLI args only' => sub {
  my $mock = MockCLI->new(
    commands      => { foo => sub { return 0; } },
    option_specs  => \@option_specs,
    extra_options => ['parameters_hash'],
  );

  $mock->{_mock_rc}          = undef;
  $mock->{_mock_plugin_args} = [
    'ssm:region=us-east-1',
    'vault:addr=http://local',
    'ssm:endpoint_url=http://test'  # Test adding a second key to ssm
  ];

  my $config;
  {
    local $ENV{HOME} = $EMPTY_HOME;
    $config = $mock->_build_plugin_config();
  }

  my $expected = {
    ssm => {
      region       => 'us-east-1',
      endpoint_url => 'http://test',
    },
    vault => { addr => 'http://local', },
  };

  is_deeply( $config, $expected, 'Correctly parses multiple CLI plugins into a hash' );
};

# --- Test 4: The "RC File Only" Case ---
subtest 'Test Case: RC file only' => sub {
  # 1. Create a temp environment
  my $temp_dir     = tempdir( CLEANUP => 1 );
  my $rc_file_path = File::Spec->catfile( $temp_dir, '.config-resolverrc' );

  # 2. Write the temp RC file (using the INI format we proved)
  my $rc_file_content = "[plugin SSM]\nregion = us-east-1\n";
  open my $fh, '>', $rc_file_path or die "Could not write $rc_file_path: $OS_ERROR";
  print ${fh} $rc_file_content;
  close $fh;

  # 3. Create the mock
  my $mock = MockCLI->new(
    commands      => { foo => sub { return 0; } },
    option_specs  => \@option_specs,
    extra_options => ['parameters_hash'],
  );
  $mock->{_mock_plugin_args} = [];

  # 4. Run the test with our temp $HOME
  my $config;
  {
    local $ENV{HOME} = $temp_dir;  # <-- Temporarily set $HOME
    $config = $mock->_build_plugin_config();
  }  # $HOME is restored here

  # 5. Check the result
  my $expected = { ssm => { region => 'us-east-1' } };
  is_deeply( $config, $expected, 'Correctly reads real RC file' );
};

# --- Test 5: The "Merge" Case (CLI wins) ---
subtest 'Test Case: RC and CLI merge (CLI wins)' => sub {
  # 1. Create a temp environment
  my $temp_dir     = tempdir( CLEANUP => 1 );
  my $rc_file_path = File::Spec->catfile( $temp_dir, '.config-resolverrc' );

  # 2. Write the temp RC file
  my $rc_file_content = "[plugin SSM]\nregion = us-east-1\nendpoint_url = http://prod.example.com\n";
  open my $fh, '>', $rc_file_path or die "Could not write $rc_file_path: $!";
  print $fh $rc_file_content;
  close $fh;

  # 3. Create the mock
  my $mock = MockCLI->new(
    commands      => { foo => sub { return 0; } },
    option_specs  => \@option_specs,
    extra_options => ['parameters_hash'],
  );
  # Inject the CLI override
  $mock->{_mock_plugin_args} = ['ssm:region=us-west-2'];

  # 4. Run the test
  my $config;
  {
    local $ENV{HOME} = $temp_dir;
    $config = $mock->_build_plugin_config();
  }

  # 5. Check the result
  my $expected = {
    ssm => {
      region       => 'us-west-2',                # <-- The overridden value
      endpoint_url => 'http://prod.example.com',  # <-- The value from the RC
    }
  };
  is_deeply( $config, $expected, 'CLI arguments correctly override real RC file' );
};

# --- Test 6: The "Malformed Args" Case ---
# Test that we correctly warn and skip bad input.
subtest 'Test Case: Malformed arguments' => sub {
  my $mock = MockCLI->new(
    commands      => { foo => sub { return 0; } },
    option_specs  => \@option_specs,
    extra_options => [qw(_mock_rc _mock_plugin_args parameters_hash)],
  );

  $mock->{_mock_rc}          = undef;
  $mock->{_mock_plugin_args} = [
    'ssm:region=us-east-1',  # Good
    'badformat',             # Bad (no colon)
    'vault:addr',            # Bad (no equals)
  ];

  my $config;

  # Test::Warn checks that our code produces the warnings we expect

  my $warnings = warning_like {
    local $ENV{HOME} = $EMPTY_HOME;
    $config = $mock->_build_plugin_config()
  }

  [ qr/Ignoring malformed --plugin argument: badformat/, qr/Ignoring malformed --plugin argument: vault:addr/, ],
    'Correctly warns on two malformed arguments';

  my $expected = { ssm => { region => 'us-east-1' }, };

  is_deeply( $config, $expected, 'Correctly parses good args and discards bad' );
};

# --- All done ---
done_testing();
