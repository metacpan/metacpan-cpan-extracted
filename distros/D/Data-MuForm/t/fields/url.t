use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'my_link' => ( type => 'URL' );
    has_field 'a_link' => ( type => 'URL' );

}

my $form = MyApp::Form::Test->new;
ok( $form );

my $params = {
  my_link => 'testing',
  a_link => 'http://somewhere.com',
};

$form->process( params => $params );
ok( $form->field('my_link')->has_errors, 'incorrect fields has errors' );
ok( ! $form->field('a_link')->has_errors, 'correct field does not have errors' );

done_testing;
