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

# --- No MockCLI object is needed for this test ---

# --- Test 1: Valid JSON string ---
subtest 'Test Case: Valid JSON' => sub {
  my $content  = '{"foo":"bar", "baz": [1]}';
  my $expected = { foo => 'bar', baz => [1] };

  # Call the sub directly in its package
  my $result = CLI::Config::Resolver::to_object($content);
  is_deeply( $result, $expected, 'Correctly parses JSON string' );
};

# --- Test 2: Valid YAML string (invalid JSON) ---
subtest 'Test Case: Valid YAML' => sub {
  # This string is valid YAML, but is *not* valid JSON.
  # This proves the eval chain works in order.
  my $content  = "---\nfoo: bar\nbaz: 1\n";
  my $expected = { foo => 'bar', baz => 1 };

  my $result = CLI::Config::Resolver::to_object($content);
  is_deeply( $result, $expected, 'Correctly falls back to parsing YAML' );
};

# --- Test 3: Valid INI string ---
subtest 'Test Case: Valid INI' => sub {
  # Use the format we proved is correct
  my $content  = "foo = bar\n[section]\nbaz = buz\n";
  my $expected = { foo => 'bar', section => { baz => 'buz' } };

  my $result = CLI::Config::Resolver::to_object($content);
  is_deeply( $result, $expected, 'Correctly falls back to parsing INI' );
};

# --- Test 4: Plain text (invalid everything) ---
subtest 'Test Case: Plain text' => sub {
  my $content = "this is just a string";

  my $result = CLI::Config::Resolver::to_object($content);
  is( $result, undef, 'Correctly returns undef for plain text' );
};

done_testing();

1;
