use strict;
use warnings;
use Test::More;

#
# Boolean
#
my $class = 'Data::MuForm::Field::Boolean';
use_ok($class);
my $field = $class->new( name => 'test', );
ok( defined $field, 'new() called' );
$field->input(1);
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 1' );
is( $field->value, 1, 'Test true == 1' );
$field->input(0);
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 2' );
is( $field->value, 0, 'Test true == 0' );
$field->input('checked');
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 3' );
is( $field->value, 1, 'Test true == 1' );
$field->input('0');
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 4' );
is( $field->value, 0, 'Test true == 0' );

done_testing;
