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

# --- Test 1: Globals only ---
subtest 'Test Case: Globals only' => sub {
  # Add the trailing newline, which Config::INI::Tiny requires
  my $content  = "foo=bar\nbaz=123\n";
  my $expected = { foo => 'bar', baz => '123' };

  # Call the sub directly in its package
  my $result = CLI::Config::Resolver::from_ini_file($content);
  is_deeply( $result, $expected, 'Correctly parses global section' );
};

# --- Test 2: Sections only ---
subtest 'Test Case: Sections only' => sub {
  my $content  = "[section1]\nfoo = bar\n[section2]\nbaz = 123\n";
  my $expected = {
    section1 => { foo => 'bar' },
    section2 => { baz => '123' },
  };

  my $result = CLI::Config::Resolver::from_ini_file($content);
  is_deeply( $result, $expected, 'Correctly parses sections' );
};

# --- Test 3: Globals and sections merge ---
subtest 'Test Case: Globals and sections' => sub {
  my $content  = "global_key = global_val\n[section1]\nfoo = bar\n";
  my $expected = {
    global_key => 'global_val',
    section1   => { foo => 'bar' },
  };

  my $result = CLI::Config::Resolver::from_ini_file($content);
  is_deeply( $result, $expected, 'Correctly merges globals and sections' );
};

done_testing();

1;
