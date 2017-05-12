use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';
    with 'Data::MuForm::Role::RequestToken';

    sub build_crypto_key { '%hdEi2z79#kd-@sdRt' }

    has_field 'foo';
    has_field 'bar';

}

my $form = MyApp::Form::Test->new;
ok( $form );

my $params = $form->fif;
$params->{foo} = 'test1';
$params->{bar} = 'test2';
$form->process( params => $params );
ok( $form->validated, 'form validated' );

$params->{_token} = undef;
$form->process( params => $params );
ok( ! $form->validated, 'form did not validate' );

done_testing;
