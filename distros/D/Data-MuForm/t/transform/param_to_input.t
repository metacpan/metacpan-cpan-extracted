use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( transform_param_to_input => \&fix_param );
    has_field 'bar' => ( transform_param_to_input => \&fix_param );

    sub fix_param {
        my ( $self, $input ) = @_;
        if ( length $input == 0 ) {
            $input = 'def';
        }
        return $input;
    }

}

my $form = MyApp::Form::Test->new;
ok( $form );

my $params = {
  foo => '',
  bar => 'mybar',
};

$form->process( params => $params );
my $fif = { foo => 'def', bar => 'mybar' };
is_deeply( $form->fif, $fif, 'got expected fif' );

done_testing;
