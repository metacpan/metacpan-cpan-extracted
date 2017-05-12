use strict;
use warnings;
use Test::More;
use Data::Dumper;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( default => 'mine' );
    has_field 'bar' => ( default => 'yours' );

}

my $form = MyApp::Form::Test->new;
ok( $form );

$form->process( params => {} );

# process has already been done by BUILD
is( $form->filled_from, 'fields', 'looking at field filled' );

my $params = {
   foo => 'one',
   bar => 'two',
};

$form->process( params => $params );
is( $form->filled_from, 'params', 'looking at param filled' );

my $init_obj = { foo => 'three', bar => 'four' };
$form->process( init_values => $init_obj, params => {} );
is( $form->filled_from, 'object', 'looking at object filled' );


done_testing;
