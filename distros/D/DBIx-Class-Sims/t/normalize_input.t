# vi:sw=2
use strictures 2;

use Test2::V0 qw( done_testing subtest is );

use File::Temp qw( tempfile );
use DBIx::Class::Sims;

my $sub = \&DBIx::Class::Sims::normalize_input;

my $expected = { 'some' => [ 'testing', { struct => 'is big' } ] };

# Verify loading from a structure
is( $sub->($expected), $expected, "A structure is passed through" );

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
  is( $sub->($str), $expected, "A YAML string is parsed" );

  # Verify loading from a YAML file
  my ($fh, $fn) = tempfile();
  print $fh "$str\n";
  close $fh;
  is( $sub->($fn), $expected, "A YAML file is loaded and parsed" );
};

# Test the JSON inputs
subtest "Load a JSON string" => sub {
  my $str = "{'some':['testing', {'struct':'is big'}]}";

  # Verify loading from a JSON string
  is( $sub->($str), $expected, "A JSON string is parsed" );

  # Verify loading from a JSON file
  my ($fh, $fn) = tempfile();
  print $fh "$str\n";
  close $fh;
  is( $sub->($fn), $expected, "A YAML file is loaded and parsed" );
};

done_testing;
