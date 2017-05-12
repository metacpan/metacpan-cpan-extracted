use strict;
use warnings;
use Test::More;

# email
my $class = 'Data::MuForm::Field::Email';
use_ok($class);
my $field = $class->new( name => 'test', );
ok( defined $field, 'new() called' );
my $address = 'test@example.com';
$field->input( $address );
$field->field_validate;
ok( !$field->has_errors, 'Email Test for errors 1' );
is( $field->value, $address, 'is value input string' );
my $Address = 'Test@example.com';
$field->input( $Address );
$field->field_validate;
ok( !$field->has_errors, 'Email Test for errors 2' );
is( $field->value, lc($Address), 'is value input string' );
$field->preserve_case(1);
$field->input( $Address );
$field->field_validate;
ok( !$field->has_errors, 'Email Test for errors 3' );
is( $field->value, $Address, 'field was not lowercased' );


$field->input( 'test @ example . com' );
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 3' );
is( $field->value, 'test@example.com', 'is email-valid corrected input string' );

done_testing;
