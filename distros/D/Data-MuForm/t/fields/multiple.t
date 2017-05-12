use strict;
use warnings;
use Test::More;


# multiple

my $class = 'Data::MuForm::Field::Multiple';
use_ok( $class );
my $field = $class->new( name    => 'test_field',);

ok( defined $field,  'new() called' );
$field->options([
    { value => 1, label => 'one' },
    { value => 2, label => 'two' },
    { value => 3, label => 'three' },
]);
ok( $field->options,  'options method called' );

$field->input( 1 );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 1' );
is_deeply( $field->value, [1], 'Test 1 => [1]' );

$field->input( [1] );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 2' );
ok( eq_array( $field->value, [1], 'test array' ), 'Check [1]');

$field->input( [1,2] );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 3' );
ok( eq_array( $field->value, [1,2], 'test array' ), 'Check [1,2]');

$field->input( [1,2,4] );
$field->field_validate;
ok( $field->has_errors, 'Test for errors 4' );
is( $field->errors->[0], "'4' is not a valid value", 'Error message' );

done_testing;
