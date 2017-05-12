use strict;
use warnings;
use Test::More;

use Data::MuForm::Types (':all');
use Data::MuForm::Field::Text;

my $field = Data::MuForm::Field::Text->new( name => 'test',
   apply => [ Collapse ]
);
ok( $field, 'field with Collapse' );
$field->input('This  is  a   test');
$field->field_validate;
is( $field->value, 'This is a test');

$field = Data::MuForm::Field::Text->new( name => 'test',
   apply => [ Upper ]
);
ok( $field, 'field with Upper' );
$field->input('This is a test');
$field->field_validate;
is( $field->value, 'THIS IS A TEST');

$field = Data::MuForm::Field::Text->new( name => 'test',
   apply => [ Lower ]
);
ok( $field, 'field with Lower' );
$field->input('This Is a Test');
$field->field_validate;
is( $field->value, 'this is a test');

$field = Data::MuForm::Field::Text->new( name => 'test',
   trim => undef,
   apply => [ Trim ]
);
ok( $field, 'field with Trim' );
$field->input('  This is a test   ');
$field->field_validate;
is( $field->value, 'This is a test');

done_testing;
