use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+skip_fields_without_input' => ( default => 1 );

    has_field 'foo' => ( required => 1);
    has_field 'bar';
    has_field 'max';
    has_field 'min';

}

my $form = MyApp::Form::Test->new;
ok( $form );

my $params = {
    bar => 1,
    max => 2,
    min => 0,
};

$form->process( params => $params );
ok( $form->validated, 'form validated without required param');

$params->{foo} = '';
$form->process( params => $params );
ok( $form->has_errors, 'form has errors with empty required param' );


delete $params->{foo};
$form->skip_fields_without_input(0);
$form->process( params => $params );
ok( $form->has_errors, 'form has errors without required param' );

done_testing;
