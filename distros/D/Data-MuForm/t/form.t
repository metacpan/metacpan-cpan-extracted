use strict;
use warnings;
use Test::More;
use Data::Dumper;

{
    package Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';
    use Types::Standard ':all';

    has_field 'foo' => (
        type => 'Text',
        label => 'Test Field',
        required => 1,
    );

    has_field 'bar' => (
        type => 'Text',
        label => 'Testing!',
        apply => [ Int ],
    );

    has_field 'submit_btn' => (
        type => 'Submit',
        value => 'Save',
    );
}

my $form = Test::Form->new;

ok($form, 'form built');

is ( $form->num_fields, 3, 'two fields' );

my $field = $form->field('foo');

ok( $field, 'field method works' );

my $params = {
    foo => 'something',
    bar => '1',
};

$form->process( params => $params );
ok( $form->has_params, 'form has_params correct');

ok( $form->validated, 'form validated' );
is_deeply( $form->fif, { foo => 'something', bar => 1 }, 'fif correct when valid' );

# check empty required param
$params = { foo => '' };
$form->process( params => $params );
ok( ! $form->validated, 'form did not validate' );
is ( $form->num_error_fields, 1, 'one error field' );
is ( $form->num_errors, 1, 'one error');
is_deeply( $form->fif, { foo => '', bar => '' }, 'fif correct when error' );

# check incorrect bar param
$params = { foo => 'one', bar => 'two' };
$form->process( params => $params );
ok( ! $form->validated, 'form did not validate' );
is ( $form->num_error_fields, 1, 'one error field' );
is ( $form->num_errors, 1, 'one error');
is_deeply( $form->fif, { foo => 'one', bar => 'two' }, 'fif correct when error' );



done_testing;
