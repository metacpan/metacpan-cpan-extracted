use strict;
use warnings;
use Test::More;

# checkbox
my $class = 'Data::MuForm::Field::Checkbox';
use_ok($class);
my $field = $class->new( name => 'test', );

ok( defined $field, 'new() called' );
$field->input(1);
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 1' );
is( $field->value, 1, 'input 1 is 1' );
$field->input(0);
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 2' );
is( $field->value, 0, 'input 0 is 0' );
$field->input('checked');
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 3' );
is( $field->value, 'checked', 'value is "checked"' );
$field->input(undef);
$field->field_validate;
ok( !$field->has_errors, 'Test for errors 4' );
is( $field->value, undef, 'input undef is 0' );
$field = $class->new(
   name     => 'test_field2',
   required => 1
);
$field->input(0);
$field->field_validate;
ok( $field->has_errors, 'required field fails with 0' );

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => (
        type => 'Checkbox',
    );
    has_field 'bar' => (
        type => 'Checkbox',
        input_without_param => 'x',
    );

    has_field 'win' => (
        type => 'Checkbox',
        input_without_param => undef,
    )

}

my $form = MyApp::Form::Test->new;
ok( $form );

is( $form->field('bar')->input_without_param, 'x', 'correct input_without_param' );
ok( $form->field('bar')->has_input_without_param, 'input_without_param predicate is correct' );
ok( ! length( $form->field('win')->input_without_param ), 'correct input_without_param' );
ok( $form->field('win')->has_input_without_param, 'input_without_param predicate is correct' );


$form->process( submitted => 1, params => {} );
is( $form->field('foo')->value, 0, 'foo has unchecked value' );
is( $form->field('bar')->value, 'x', 'bar has correct input_without_param' );
ok( ! length($form->field('win')->value), 'win has correct value' );
is_deeply ( $form->value, { foo => 0, bar => 'x', win => undef }, 'correct values' );

done_testing;
