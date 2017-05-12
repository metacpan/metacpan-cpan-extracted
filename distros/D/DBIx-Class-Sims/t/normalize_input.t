# vi:sw=2
use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;

use File::Temp qw( tempfile );

use_ok 'DBIx::Class::Sims';

my $sub = \&DBIx::Class::Sims::normalize_input;

my $expected = { 'some' => [ 'testing', { struct => 'is big' } ] };

# Verify loading from a structure
cmp_deeply( $sub->($expected), $expected, "A structure is passed through" );

# Test the YAML inputs
subtest "Load a YAML string" => sub {
  my $str = "
    some:
      -
        testing
      -
        struct: 'is big'
  ";

  my $expected = { 'some' => [ 'testing', { struct => 'is big' } ] };

  # Verify loading from a YAML string
  cmp_deeply( $sub->($str), $expected, "A YAML string is parsed" );

  # Verify loading from a YAML file
  my ($fh, $fn) = tempfile();
  print $fh "$str\n";
  close $fh;
  cmp_deeply( $sub->($fn), $expected, "A YAML file is loaded and parsed" );
};

# Test the JSON inputs
subtest "Load a JSON string" => sub {
  my $str = "{'some':['testing', {'struct':'is big'}]}";

  # Verify loading from a JSON string
  cmp_deeply( $sub->($str), $expected, "A JSON string is parsed" );

  # Verify loading from a JSON file
  my ($fh, $fn) = tempfile();
  print $fh "$str\n";
  close $fh;
  cmp_deeply( $sub->($fn), $expected, "A YAML file is loaded and parsed" );
};

done_testing;
