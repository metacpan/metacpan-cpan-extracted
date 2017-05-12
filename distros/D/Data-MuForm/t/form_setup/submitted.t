use strict;
use warnings;
use Test::More;

{
    package MyApp::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => 'Checkbox' );
    has_field 'bar';
}

my $form = MyApp::Form->new;
ok( $form );

$form->process( params => {} );
ok( ! $form->ran_validation, 'no validation with empty params' );

$form->process( params => { foo => 1, bar => 'my_bar' } );
ok( $form->ran_validation, 'validation with params' );

$form->process( params => { dux => 1 } );
ok( $form->ran_validation, 'validation with non-field params' );

my $req_method = 'GET';
$form->process( submitted => ( $req_method eq 'POST' ),
    params => { duz => 'xxx' } );
ok( ! $form->ran_validation, 'validation was not performed with extra params and false submitted flag' );
ok( ! $form->validated, 'not validated' );

$req_method = 'POST';
$form->process( submitted => ( $req_method eq 'POST' ), params => {} );
ok( $form->ran_validation, 'validation was performed with empty params and submitted flag' );

done_testing;
