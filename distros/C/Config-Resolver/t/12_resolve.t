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

# --- Setup a Mock Resolver Class ---
# This mocks the main Config::Resolver engine
{

  package MockResolver;

  sub new { bless {}, shift; }

  # This is our "spy" method.
  # For this test, it will just return whatever it was given.
  sub resolve {
    my ( $self, $input_hash, $params_hash ) = @_;

    # If we are in the template-processing stage...
    if ( defined $params_hash ) {
      # This is a simplified simulation of template resolution
      if ( $input_hash->{value} eq "Template line with \${foo}" ) {
        return { value => "Template line with bar" };
      }
    }

    # Otherwise, this is the first call (parameter resolution)
    # Just return the hash, "resolved"
    return $input_hash;
  }
}

# --- Setup a Mock CLI Class ---
{

  package MockCLI;
  our @ISA = qw(CLI::Config::Resolver);
  sub init { }

  # --- Stubs for resolve() ---
  sub get_resolver        { $_[0]->{_mock_resolver} }
  sub get_parameters_hash { $_[0]->{_mock_params_hash} }
  sub get_template        { $_[0]->{_mock_template} }

  # We will mock fetch_file to return a plain string
  sub fetch_file {
    my ( $self, $file ) = @_;
    return "Template line with \${foo}";
  }

  # We will mock resolve_stream to just return its input
  # (We already tested its logic in t/05)
  sub resolve_stream {
    my ( $self, $fh, $params ) = @_;
    # In a real test, we'd mock this better, but for now,
    # let's just confirm it was called by returning a known string.
    return "FROM_RESOLVE_STREAM";
  }

  # Spy: Record what write_output is called with
  sub write_output {
    my ( $self, $output ) = @_;
    $self->{_called_output} = $output;
  }
}

my @option_specs = qw(
  debug|g dump|d help key|k=s manifest|m=s outfile|o=s
  parameter-file|p=s pretty|P parameters|V=s plugins=s
  plugin=s@ resolve|r template=s umask=s warning-level|w=s
  parameters_hash resolver
);

# --- Create one mock object for all tests ---
my $mock = MockCLI->new(
  commands     => { resolve => sub { }, dump => sub { } },
  option_specs => \@option_specs,
);
$mock->{_mock_resolver} = MockResolver->new();

# --- Test 1: Resolve WITHOUT template ---
subtest 'Test Case: Resolve (no template)' => sub {

  my $params = { foo => 'bar', baz => 123 };
  $mock->{_mock_params_hash} = $params;
  $mock->{_mock_template}    = undef;   # No -t option

  $mock->resolve();

  # The 'resolve' sub should just pass the resolved
  # parameters hash directly to write_output
  is_deeply( $mock->{_called_output}, $params, 'Passes resolved params to write_output' );
};

# --- Test 2: Resolve WITH template ---
subtest 'Test Case: Resolve (with template)' => sub {

  my $params = { foo => 'bar' };
  $mock->{_mock_params_hash} = $params;
  $mock->{_mock_template}    = 'template.tpl';  # A -t option is given

  # We must also mock the "plain text" branch of resolve_stream
  # (We already tested the logic in t/05, so we just mock it here)
  {
    local *MockCLI::resolve_stream = sub {
      my ( $self, $fh, $params ) = @_;
      # Read from the in-memory filehandle
      my $line = <$fh>;
      if ( $line eq "Template line with \${foo}" ) {
        return "Template line with bar";
      }
      return "UNEXPECTED_TEMPLATE";
    };

    $mock->resolve();
  }

  # The 'resolve' sub should have run the template logic
  # and passed the *final string* to write_output
  is( $mock->{_called_output}, "Template line with bar", 'Passes rendered template string to write_output' );
};

done_testing();

1;
