use strict;
use warnings;
use Test::More;

{
    package Test::Form1;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    sub build_messages {
        {
            required => 'You must supply this field',
        }
    }
    has_field 'foo' => ( type => 'Text', required => 1 );
    has_field 'bar';
}

my $form = Test::Form1->new;
ok( $form, 'form built');
$form->process( params => { bar => 1} );
my $errors = $form->errors;
is( $errors->[0], 'You must supply this field', 'form has errors' );

{
    package Test::Form2;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( required => 1, messages => { required => "You must supply a FOO!" } );
    has_field 'bar' => ( required => 1, messages => { required => 'You must supply a BAR!' } );
    has_field 'baz';
}

$form = Test::Form2->new;

$form->process( params => {} );
$form->process( params => { baz => 'True' } );

my @errors = $form->all_errors;
is( scalar @errors, 2, 'right number of errors' );
is( $errors[0], 'You must supply a FOO!', 'right message for foo' );
is( $errors[1], 'You must supply a BAR!', 'right message for bar' );

done_testing;
