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

# --- Setup a Mock Class ---
{

  package MockCLI;
  our @ISA = qw(CLI::Config::Resolver);

  # Override init to do nothing
  # We just need an object to call the method on.
  sub init { }
}

my @option_specs = qw(
  debug|g dump|d help key|k=s manifest|m=s outfile|o=s
  parameter-file|p=s pretty|P parameters|V=s plugins=s
  plugin=s@ resolve|r template=s umask=s warning-level|w=s
);

# --- Create one mock object for all tests ---
my $mock = MockCLI->new(
  commands     => { resolve => sub { }, dump => sub { } },
  option_specs => \@option_specs,
);

my $test_data = { foo => 'bar', baz => [ 1, 2 ] };

# --- Test 1: JSON file ---
subtest 'Test Case: fetch_file correctly parses JSON' => sub {
  my ( $fh, $file_name ) = tempfile( SUFFIX => '.json', UNLINK => 1 );
  print $fh to_json($test_data);
  close $fh;

  my $object = $mock->fetch_file($file_name);
  is_deeply( $object, $test_data, 'Correctly parsed JSON file' );
};

# --- Test 2: YAML file ---
subtest 'Test Case: fetch_file correctly parses YAML' => sub {
  my ( $fh, $file_name ) = tempfile( SUFFIX => '.yml', UNLINK => 1 );
  print $fh Dump($test_data);
  close $fh;

  my $object = $mock->fetch_file($file_name);
  is_deeply( $object, $test_data, 'Correctly parsed YAML file' );
};

# --- Test 3: Plain text file ---
subtest 'Test Case: fetch_file returns plain text' => sub {
  my ( $fh, $file_name ) = tempfile( SUFFIX => '.txt', UNLINK => 1 );
  my $content = sprintf "This is just plain text.\n%s", '${foo.bar}';
  print $fh $content;
  close $fh;

  my $object = $mock->fetch_file($file_name);
  is( $object, $content, 'Correctly returned plain text for unknown extension' );
};

done_testing();

1;
