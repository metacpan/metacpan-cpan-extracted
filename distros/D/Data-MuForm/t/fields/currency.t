use strict;
use warnings;
use Test::More;

# money

my $class = 'Data::MuForm::Field::Currency';
use_ok( $class );
my $field = $class->new( name    => 'test_field',);
ok( defined $field,  'new() called' );

$field->input( '   $123.45  ' );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors "   $123.00  "' );
is( $field->value, 123.45, 'Test value == 123.45' );

$field->input( '   $12x3.45  ' );
$field->field_validate;
ok( $field->has_errors, 'Test for errors "   $12x3.45  "' );
is( $field->errors->[0], 'Must be a real number', 'get error' );

$field->clear;
$field->input( 2345 );
$field->field_validate;
is( $field->value, '2345.00', 'transformation worked: 2345 => 2345.00' );

done_testing;
