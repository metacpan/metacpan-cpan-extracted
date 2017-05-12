use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Rep;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+name' => ( default => 'testform' );
    has_field 'test';
    # TODO: this used to be inactive => 1. Get working?
    has_field 'my_array' => ( type => 'Repeatable', required => 1, active => 0 );
    has_field 'my_array.one';
    has_field 'my_array.two';
}

my $form = MyApp::Form::Rep->new;
ok( $form );
my $params = {
   'text' => 'foo',
};
$form->process( params => $params );
ok( !$form->has_errors, 'form has no errors' );

done_testing;
