use strict;
use warnings;
use Test::More;

# integer

my $class = 'Data::MuForm::Field::Integer';
use_ok( $class );
my $field = $class->new( name    => 'test_field',);

ok( defined $field,  'new() called' );
$field->input( 1 );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 1' );
is( $field->value, 1, 'Test value == 1' );

$field->input( 0 );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 2' );
is( $field->value, 0, 'Test value == 0' );

$field->input( 'checked' );
$field->field_validate;
ok( $field->has_errors, 'Test non integer' );
is( $field->errors->[0], 'Value must be an integer', 'correct error');

$field->clear;
$field->input( '+10' );
$field->field_validate;
ok( !$field->has_errors, 'Test positive' );
is( $field->value, 10, 'Test value == 10' );

$field->input( '-10' );
$field->field_validate;
ok( !$field->has_errors, 'Test negative' );
is( $field->value, -10, 'Test value == -10' );

$field->input( '-10.123' );
$field->field_validate;
ok( $field->has_errors, 'Test real number' );

$field->clear_errors;
$field->range_start( 10 );
$field->input( 9 );
$field->field_validate;
ok( $field->has_errors, 'Test 9 < 10 fails' );

$field->clear;
$field->input( 100 );
$field->field_validate;
ok( !$field->has_errors, 'Test 100 > 10 passes ' );

$field->range_end( 20 );
$field->input( 100 );
$field->field_validate;
ok( $field->has_errors, 'Test 10 <= 100 <= 20 fails' );

$field->clear_errors;
$field->range_end( 20 );
$field->input( 15 );
$field->field_validate;
ok( !$field->has_errors, 'Test 10 <= 15 <= 20 passes' );

$field->input( 10 );
$field->field_validate;
ok( !$field->has_errors, 'Test 10 <= 10 <= 20 passes' );

$field->input( 20 );
$field->field_validate;
ok( !$field->has_errors, 'Test 10 <= 20 <= 20 passes' );

$field->input( 21 );
$field->field_validate;
ok( $field->has_errors, 'Test 10 <= 21 <= 20 fails' );

$field->clear_errors;
$field->input( 9 );
$field->field_validate;
ok( $field->has_errors, 'Test 10 <= 9 <= 20 fails' );

done_testing;
