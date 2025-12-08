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
  sub init { }

  # Stub: This is *only* for the -V string
  sub get_parameters {
    my ($self) = @_;
    return $self->{_mock_query_string};
  }

  # We will "spy" on the *new* accessors
  sub get_parameters_hash { $_[0]->{_internal_hash} }
  sub set_parameters_hash { $_[0]->{_internal_hash} = $_[1]; }
}

# We need the specs that are actually called
my @option_specs = qw(parameters|V=s parameters_hash);

# --- Create one mock object for all tests ---
my $mock = MockCLI->new(
  commands     => { resolve => sub { }, dump => sub { } },
  option_specs => \@option_specs,
);

# --- Test 1: Basic query string from -V ---
subtest 'Test Case: Basic query string from -V' => sub {
  $mock->{_mock_query_string} = 'foo=bar&baz=123';
  $mock->set_parameters_hash(undef);  # Reset

  my $expected = { foo => 'bar', baz => '123' };

  $mock->fetch_query_params();

  is_deeply( $mock->get_parameters_hash, $expected, 'Correctly parses -V query string' );
};

# --- Test 2: Merging with existing params ---
subtest 'Test Case: Merges query string with existing params' => sub {
  # 1. Set up pre-existing params
  $mock->set_parameters_hash(
    { foo => 'original',   # This will be overridden
      old => 'preserved',  # This will be kept
    }
  );

  # 2. Set up the -V string
  $mock->{_mock_query_string} = 'foo=new&new=added';

  my $expected = {
    foo => 'new',
    old => 'preserved',
    new => 'added',
  };

  $mock->fetch_query_params();

  is_deeply( $mock->get_parameters_hash, $expected, 'Correctly merges -V string, query wins' );
};

# --- Test 3: Fallback to ENV{QUERY_STRING} ---
subtest 'Test Case: Reads from $ENV{QUERY_STRING}' => sub {
  $mock->{_mock_query_string} = undef;  # Simulate no -V
  $mock->set_parameters_hash(undef);    # Reset

  my $expected = { env_key => 'env_val' };

  {
    local $ENV{QUERY_STRING} = 'env_key=env_val';
    $mock->fetch_query_params();
  }

  is_deeply( $mock->get_parameters_hash, $expected, 'Correctly falls back to $ENV{QUERY_STRING}' );
};

done_testing();

1;
