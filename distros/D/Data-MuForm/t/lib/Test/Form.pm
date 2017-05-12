package Test::Form;
use Moo;
use Data::MuForm::Meta;
extends 'Data::MuForm';
with 'Test::FormRole';

has_field 'foo';
has_field 'bar';

has_field 'submit_btn' => ( type => 'Submit' );

1;
