use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo';
    has_field 'bar';

}

my $form = MyApp::Form::Test->new;
ok( $form );

my $params = { foo => 'twiddle', bar => 'twaddle' };
$form->process( params => $params );
ok( $form->validated, 'form validated' );

is_deeply( $form->value, $params, 'got right value' );

done_testing;
