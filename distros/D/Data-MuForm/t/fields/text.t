use strict;
use warnings;
use Test::More;

# text

my $class = 'Data::MuForm::Field::Text';
use_ok( $class );
my $field = $class->new( name    => 'test',);
ok( defined $field,  'new() called' );
my $string = 'Some text';
$field->input( $string );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 1' );
is( $field->value, $string, 'is value input string');

$field->input( '' );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 2' );
is( $field->value, undef, 'is value input string');

$field->required(1);
$field->field_validate;
ok( $field->has_errors, 'Test for errors 3' );

$field->clear_errors;
$field->input('hello');
$field->required(1);
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 3' );
is( $field->value, 'hello', 'Check again' );

$field->maxlength( 3 );
$field->field_validate;
is( $field->errors->[0], 'Field should not exceed 3 characters. You entered 5',  'Test for too long' );

$field->clear_errors;
$field->maxlength( 5 );
$field->field_validate;
ok( !$field->has_errors, 'Test for right length' );

$field->minlength( 10 );
$field->field_validate;
is( $field->errors->[0], 'Field must be at least 10 characters. You entered 5', 'Test not long enough' );

$field->clear_errors;
$field->minlength( 5 );
$field->field_validate;
ok( !$field->has_errors, 'Test just long enough' );

$field->minlength( 4 );
$field->field_validate;
ok( !$field->has_errors, 'Test plenty long enough' );

$field = $class->new( name    => 'test_not_nullable', not_nullable => 1);
$field->input('');
$field->field_validate;
is( $field->value, '', 'empty string');

done_testing;

