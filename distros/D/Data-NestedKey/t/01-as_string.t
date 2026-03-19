use strict;
use warnings;

use Data::Dumper;
use Data::NestedKey;
use English qw(-no_match_vars);
use JSON;
use Storable qw(thaw);
use Test::More;
use YAML::XS qw(Load);

# More complex data structure
my $expected_data = {
  foo => {
    bar => {
      baz  => 42,
      qux  => 'hello',
      list => [ 1, 2, 3 ],
    },
    nested => { hash => { key1 => 'val1', key2 => 'val2' } }
  },
  top_level => 'root_value'
};

# Create a new object with complex data
my $nk = Data::NestedKey->new( %{$expected_data} );

# Test JSON format
$Data::NestedKey::FORMAT = 'JSON';
my $json_data = decode_json( $nk->as_string() );

is_deeply( $json_data,         $expected_data, 'JSON: Serialization and deserialization are consistent' );
is_deeply( decode_json("$nk"), $expected_data, 'JSON: Interpolation preserves structure' );

# Test YAML format
$Data::NestedKey::FORMAT = 'YAML';
my $yaml_data = Load( $nk->as_string() );

is_deeply( $yaml_data,  $expected_data, 'YAML: Serialization and deserialization are consistent' );
is_deeply( Load("$nk"), $expected_data, 'YAML: Interpolation preserves structure' );

# Test Data::Dumper format
$Data::NestedKey::FORMAT = 'Dumper';
my $dumper_output = $nk->as_string();

# Ensure Dumper output is wrapped in `{}` to be evaluated as a proper hash ref
use vars qw($VAR1);

if ( $dumper_output !~ /^[{]/xsm ) {
  $dumper_output = "{ $dumper_output }";
}

my $dumper_data = eval $dumper_output;

if ($EVAL_ERROR) {
  diag("Eval error: $EVAL_ERROR");
}

is_deeply( $dumper_data, $expected_data, 'Dumper: Serialization and deserialization are consistent' );

$dumper_data = eval "{ $nk }";  # Interpolation test

is_deeply( $dumper_data, $expected_data, 'Dumper: Interpolation preserves structure' );

# Test Storable format
$Data::NestedKey::FORMAT = 'Storable';
my $storable_data = thaw( $nk->as_string() );

is_deeply( $storable_data, $expected_data, 'Storable: Serialization and deserialization are consistent' );

$storable_data = thaw("$nk");  # Interpolation test
is_deeply( $storable_data, $expected_data, 'Storable: Interpolation preserves structure' );

done_testing();

1;
