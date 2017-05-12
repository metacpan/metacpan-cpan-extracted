use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => 'List', valid => ['one','bar','mix']);
    has_field 'bar' => ( type => 'List' );

}

my $form = MyApp::Form::Test->new;
ok( $form );
my $params = {
    foo => ['one', 'two', 'bar'],
    bar => ['fruit', 'vegetable', 'meat'],
};
$form->process( params => $params );
is_deeply( $form->fif, $params, 'right fif' );
is_deeply( $form->values, $params, 'right values' );
ok( $form->has_errors, 'form has errors' );

done_testing;
