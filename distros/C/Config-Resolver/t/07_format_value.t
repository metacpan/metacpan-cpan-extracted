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
use JSON qw(to_json);  # We'll need this to test pretty-print

# --- Setup a Mock Class ---
{

  package MockCLI;
  our @ISA = qw(CLI::Config::Resolver);
  sub init { }

  # Stubs for the accessors format_value uses
  sub get_warning_level { $_[0]->{_mock_warn_level} }
  sub get_pretty        { $_[0]->{_mock_pretty} }
}

# We only need the specs that are actually called
my @option_specs = qw(warning-level|w=s pretty|P);

# --- Create one mock object for all tests ---
my $mock = MockCLI->new(
  commands     => { resolve => sub { }, dump => sub { } },
  option_specs => \@option_specs,
);

# --- Test 1: Plain scalar value ---
subtest 'Test Case: Plain scalar' => sub {
  is( $mock->format_value('foo'), 'foo', 'Returns plain scalar' );
};

# --- Test 2: Undefined value ---
subtest 'Test Case: Undefined value' => sub {
  is( $mock->format_value(undef), '<undefined>', 'Returns <undefined> for undef' );
};

# --- Test 3: Complex value (no key) ---
subtest 'Test Case: Complex value, no key' => sub {
  my $hash     = { a => 1 };
  my $expected = to_json( $hash, { pretty => 0, allow_blessed => 1, convert_blessed => 1 } );
  is( $mock->format_value($hash), $expected, 'Returns compact JSON for hashref' );
};

# --- Test 4: Complex value with Pretty ---
subtest 'Test Case: Complex value with pretty' => sub {
  $mock->{_mock_pretty} = 1;  # Turn on pretty-print

  my $hash     = { a => 1 };
  my $expected = to_json( $hash, { pretty => 1, allow_blessed => 1, convert_blessed => 1 } );

  is( $mock->format_value($hash), $expected, 'Returns pretty JSON for hashref' );

  $mock->{_mock_pretty} = 0;  # Reset for next test
};

# --- Test 5: Key extraction ---
subtest 'Test Case: Key extraction' => sub {
  my $hash = { a => 1, b => 'foo' };
  is( $mock->format_value( $hash, 'b' ), 'foo', 'Extracts correct key from hashref' );
};

# --- Test 6: Key extraction (complex) ---
subtest 'Test Case: Key extraction (complex value)' => sub {
  my $hash     = { a => 1, b => { nested => 'data' } };
  my $expected = to_json( { nested => 'data' }, { pretty => 0, allow_blessed => 1, convert_blessed => 1 } );

  is( $mock->format_value( $hash, 'b' ), $expected, 'Returns JSON for nested complex value' );
};

# --- Test 7: Missing key (warn level) ---
subtest 'Test Case: Missing key (warn)' => sub {
  $mock->{_mock_warn_level} = 'warn';  # Set to default
  my $hash = { a => 1 };

  is( $mock->format_value( $hash, 'badkey' ), '<undefined>', 'Returns <undefined> for missing key (warn)' );
};

# --- Test 8: Missing key (error level) ---
subtest 'Test Case: Missing key (error)' => sub {
  $mock->{_mock_warn_level} = 'error';  # Set to error
  my $hash = { a => 1 };

  # The 'dies' test passes if the code inside it 'croak's
  eval { $mock->format_value( $hash, 'badkey' ) };
  like( $@, qr/badkey not found/, 'Script croaks for missing key (error)' );

  $mock->{_mock_warn_level} = 'warn';   # Reset
};

done_testing();

1;
