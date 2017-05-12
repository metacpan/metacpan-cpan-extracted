use strict;
use warnings;
use Test::More;

use_ok('Data::MuForm::Field::Textarea');

my $field = Data::MuForm::Field::Textarea->new( name => 'comments', cols => 40, rows => 3 );
ok( $field, 'get Textarea field');
$field->input("Testing, testing, testing... This is a test");
$field->field_validate;
ok( !$field->has_errors, 'field has no errors');
$field->maxlength( 10 );
$field->field_validate;
ok( $field->has_errors, 'field has errors');
is( $field->errors->[0], 'Field should not exceed 10 characters. You entered 43',  'Test for too long' );

done_testing;
