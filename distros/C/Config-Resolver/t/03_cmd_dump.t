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
use File::Temp qw(tempfile);
use JSON;

# --- Setup a Mock Class ---
{

  package MockCLI;
  our @ISA = qw(CLI::Config::Resolver);

  use Config::Resolver;
  use File::Temp qw(tempfile);
  use JSON;

  sub init {
    my ($self) = @_;

    my $resolver = Config::Resolver->new;

    # 1. Create a real temp file with JSON data
    my $test_data = { foo => 'bar', baz => 123 };
    $self->{_test_data} = $test_data;

    my ( $fh, $file_name ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
    print $fh to_json($test_data);
    close $fh;

    $self->set_parameter_file($file_name);

    $self->fetch_parameters;

    return $self->set_resolver($resolver);
  }

  # --- Mocks for cmd_dump ---

  # Stub: Return a LIST, not an ARRAYREF
  sub get_args {
    my ($self) = @_;
    return @{ $self->{_mock_args} || [] };
  }

  # Stub: Return the key from the -k option
  sub get_key { $_[0]->{_mock_key} }

  # Stub: Call the REAL fetch_file from the parent
  sub fetch_file {
    my ( $self, $file ) = @_;
    # This will correctly read our temp file from disk
    return $self->SUPER::fetch_file($file);
  }

  # Spy: Record what cmd_dump tries to print
  sub write_output {
    my ( $self, $output ) = @_;
    $self->{_called_output} = $output;
  }
}

my @option_specs = qw(
  debug|g dump|d help key|k=s manifest|m=s outfile|o=s
  parameter-file|p=s pretty|P parameters|V=s plugins=s
  plugin=s@ resolve|r template=s umask=s warning-level|w=s
);

# --- Test 1: Dump the whole object ---
subtest 'Test Case: Dump entire object' => sub {

  # 2. Create the mock object
  my $mock = MockCLI->new(
    commands      => { resolve => sub { }, dump => sub { } },
    option_specs  => \@option_specs,
    extra_options => [ 'parameters_hash', 'resolver' ],
  );

  # 3. Inject mock data
  $mock->{_mock_args} = [ $mock->get_parameter_file ];  # Pass the REAL file name
  $mock->{_mock_key}  = undef;                          # No -k key

  # 4. Run the test
  # This will now work:
  # - get_args() returns the real file name
  # - The '-e' check in cmd_dump() PASSES
  # - fetch_file() calls SUPER::fetch_file() and reads the temp file
  $mock->cmd_dump();

  is_deeply( $mock->{_called_output}, $mock->{_test_data}, 'Dumps the full object when no key is given' );
};

# --- Test 2: Dump a single key ---
subtest 'Test Case: Dump single key' => sub {

  my $mock = MockCLI->new(
    commands      => { resolve => sub { }, dump => sub { } },
    option_specs  => \@option_specs,
    extra_options => [ 'parameters_hash', 'resolver' ],
  );

  # 3. Inject mock data
  $mock->{_mock_args} = [ $mock->get_parameter_file ];  # Pass the REAL file name
  $mock->{_mock_key}  = 'foo';                          # User passed -k foo

  # 4. Run the test
  $mock->cmd_dump();

  is( $mock->{_called_output}, 'bar', 'Dumps only the specified key "foo"' );
};

done_testing();

1;
