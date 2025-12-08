#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  use FindBin;
  my $ScriptPath = "$FindBin::Bin/../bin/config-resolver.pl";
  require $ScriptPath;
}

use Test::More;
use Data::Dumper;

# --- Setup a Mock Class ---
{

  package MockCLI;
  our @ISA = qw(CLI::Config::Resolver);

  # Override init to do nothing
  sub init { }

  # --- Mocks for fetch_parameters ---

  # Stub: Return the name of our fake file
  sub get_parameter_file {
    my ($self) = @_;
    return $self->{_mock_file_name};
  }

  # Stub: Return our mock data hash (no I/O needed)
  sub fetch_file {
    my ( $self, $file ) = @_;
    # Only return the data if it's the file we expect
    if ( $file eq $self->{_mock_file_name} ) {
      return $self->{_mock_file_content};
    }
    return;
  }

  # --- Spies for the CORRECT accessors ---
  sub get_parameters_hash {
    my ($self) = @_;
    return $self->{_internal_param_hash};
  }

  sub set_parameters_hash {
    my ( $self, $hash ) = @_;
    $self->{_internal_param_hash} = $hash;
  }
}

my @option_specs = qw(
  debug|g dump|d help key|k=s manifest|m=s outfile|o=s
  parameter-file|p=s pretty|P parameters|V=s plugins=s parameter=s
  plugin=s@ resolve|r template=s umask=s warning-level|w=s
  parameters_hash
);

# --- Test 1: Simple load (no pre-existing params) ---
subtest 'Test Case: Simple parameter file load' => sub {

  my $mock = MockCLI->new(
    commands      => { resolve => sub { }, dump => sub { } },
    option_specs  => \@option_specs,
    extra_options => qw['parameters_hash'],
  );

  my $file_data = { file_key => 'from_file' };

  # Inject our mock data
  $mock->{_mock_file_name}    = 'params.json';
  $mock->{_mock_file_content} = $file_data;

  # Run the subroutine
  $mock->fetch_parameters();

  # Check the result using the CORRECT accessor
  my $final_params = $mock->get_parameters_hash();
  is_deeply( $final_params, $file_data, 'Parameters hash is set from file' );
};

# --- Test 2: Merge (file wins) ---
subtest 'Test Case: File parameters merge and override existing' => sub {

  my $mock = MockCLI->new(
    commands      => { resolve => sub { }, dump => sub { } },
    option_specs  => \@option_specs,
    extra_options => qw['parameters_hash'],
  );

  # 1. Set up pre-existing parameters using the CORRECT accessor
  my $existing_data = {
    file_key => 'from_existing',  # This will be overridden
    old_key  => 'is_preserved',   # This will be kept
  };
  $mock->set_parameters_hash($existing_data);

  # 2. Set up the file data that will be "loaded"
  my $file_data = {
    file_key => 'from_file',      # The override
    new_key  => 'is_added',       # A new key
  };

  # 3. Inject our mock stubs
  $mock->{_mock_file_name}    = 'params.json';
  $mock->{_mock_file_content} = $file_data;

  # 4. Run the subroutine
  $mock->fetch_parameters();

  # 5. Define and check the final, merged hash
  my $expected_data = {
    file_key => 'from_file',      # <-- Overridden
    old_key  => 'is_preserved',   # <-- Preserved
    new_key  => 'is_added',       # <-- Added
  };

  # Check the result using the CORRECT accessor
  my $final_params = $mock->get_parameters_hash();
  is_deeply( $final_params, $expected_data, 'Parameters merged correctly, file wins' );
};

# --- Test 3: No file (should do nothing) ---
subtest 'Test Case: No parameter file' => sub {

  my $mock = MockCLI->new(
    commands      => { resolve => sub { }, dump => sub { } },
    option_specs  => \@option_specs,
    extra_options => qw['parameters_hash'],
  );

  my $existing_data = { old_key => 'is_preserved' };
  $mock->set_parameters_hash($existing_data);

  # get_parameter_file will return undef, so fetch_parameters should return early
  $mock->fetch_parameters();

  # Check the result using the CORRECT accessor
  my $final_params = $mock->get_parameters_hash();
  is_deeply( $final_params, $existing_data, 'Parameters are unchanged when no file is given' );
};

done_testing();

1;
