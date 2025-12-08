#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  use FindBin;
  my $ScriptPath = "$FindBin::Bin/../bin/config-resolver.pl";
  require $ScriptPath;
}

use Test::More;
use IO::String;  # Core module for creating in-memory filehandles

# --- Setup a Mock Resolver Class ---
# This is a new, simple mock object.
# resolve_stream will call this object's 'resolve' method.
{

  package MockResolver;

  sub new { bless { _called => 0 }, shift; }

  # This is our "spy" method
  sub resolve {
    my ( $self, $hash, $params ) = @_;

    $self->{_called}++;  # Record that we were called

    # Simulate a real resolution
    if ( $hash->{value} =~ /\$\{name\}/ ) {
      return { value => "Hello, World!\n" };
    }

    # Should not be called, but return this just in case
    return { value => "UNEXPECTED_CALL\n" };
  }
}

# --- Setup a Mock CLI Class ---
{

  package MockCLI;
  our @ISA = qw(CLI::Config::Resolver);

  # Override init to do nothing
  sub init { }

  # Stub: Return our mock resolver
  sub get_resolver {
    my ($self) = @_;
    return $self->{_mock_resolver};
  }
}

my @option_specs = qw(
  debug|g dump|d help key|k=s manifest|m=s outfile|o=s
  parameter-file|p=s pretty|P parameters|V=s plugins=s
  plugin=s@ resolve|r template=s umask=s warning-level|w=s
);

# --- Test 1: Test the stream resolver ---
subtest 'Test Case: resolve_stream' => sub {

  # 1. Create our mock objects
  my $mock_resolver = MockResolver->new();

  my $mock = MockCLI->new(
    commands     => { resolve => sub { }, dump => sub { } },
    option_specs => \@option_specs,
  );

  # 2. Inject the mock resolver
  $mock->{_mock_resolver} = $mock_resolver;

  # 3. Create the test data
  my $parameters      = { name => 'World' };
  my $template_string = "Line 1 is plain.\n" . "Line 2 has a \${name}\n" . "Line 3 is also plain.\n";

  # Create a virtual, in-memory filehandle
  my $fh = IO::String->new($template_string);

  # 4. Run the test
  my $output = $mock->resolve_stream( $fh, $parameters );

  # 5. Define what we expect
  my $expected_output = "Line 1 is plain.\n" . "Hello, World!\n"  # This line was resolved
    . "Line 3 is also plain.\n";

  # 6. Assert the results
  is( $output,                   $expected_output, 'Final string is correctly assembled' );
  is( $mock_resolver->{_called}, 1,                'The resolver was called exactly once' );
};

done_testing();

1;
