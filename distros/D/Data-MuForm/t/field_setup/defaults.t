use strict;
use warnings;
use Test::More;
use lib 't/lib';

{
    package Test::Defaults;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( default => 'default_foo' );
    has_field 'bar' => ( default => '' );
    has_field 'bax' => ( default => 'default_bax' );
    has_field 'box' => ( 'meth.default' => \&some_default );
    sub some_default { 'bibbidy' }
}

my $form = Test::Defaults->new;
my $cmp_fif = {
    foo => 'default_foo',
    bar => '',
    bax => 'default_bax',
    box => 'bibbidy',
};
# test that defaults in fields are used in
# filling in the form
is_deeply( $form->fif, $cmp_fif, 'fif has right defaults' );
$form->process( params => {} );
is_deeply( $form->fif, $cmp_fif, 'fif has right defaults' );

# test that an init_values overrides defaults in fields
my $init_obj = { foo => '', bar => 'testing', bax => '' };
$form->process( init_values => $init_obj, params => {} );
is_deeply( $form->fif, { foo => '', bar => 'testing', bax => '', box => 'bibbidy' }, 'object overrides defaults');

=comment
# default_over_obj not implemented
{
    package Test::DefaultsX;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( default_over_obj => 'default_foo' );
    has_field 'bar' => ( default_over_obj => '' );
    has_field 'bax' => ( default_over_obj => 'default_bax' );
}
# test that the 'default_over_obj' type defaults override an init_values/model
$form = Test::DefaultsX->new;
$form->process( init_values => $init_obj, params => {} );
is( $form->field('foo')->default_over_obj, 'default_foo', 'foo correct' );
is_deeply( $form->fif, $cmp_fif, 'fif uses defaults overriding object' );
=cut

{
    package My::Form1;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+name' => ( default => 'testform_' );
    has_field 'optname' => ( custom => 'First' );
    has_field 'reqname' => ( required => 1 );
    has_field 'somename';
}



$init_obj = { reqname => 'Starting Perl', optname => 'Over Again' };
$form = My::Form1->new( init_values => $init_obj );
# additional test for init_values provided defaults
ok( $form, 'non-db form created OK');
is( $form->field('optname')->value, 'Over Again', 'get right value from form');
$form->process(init_values => $init_obj, params => {});
ok( !$form->validated, 'form validated' );
is( $form->field('reqname')->fif, 'Starting Perl',
                      'get right fif with init_values');

{
    package My::Form2;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+name' => ( default => 'initform_' );
    has_field 'foo';
    has_field 'bar';
    has_field 'bax' => ( default => 'default_bax' );
    has '+init_values' => ( default => sub { { foo => 'initfoo' } } );
    sub default_bar { 'init_value_bar' }
}

$form = My::Form2->new;
# test default_<field_name> methods in form
# plus init_values defined in form class
# plus default is used when init_values doesn't have key/accessor
is( $form->field('foo')->value, 'initfoo', 'value from init_values' );
is( $form->field('foo')->fif,   'initfoo', 'fif ok' );
is( $form->field('bar')->value, 'init_value_bar', 'value from field default meth' );
is( $form->field('bar')->fif,   'init_value_bar', 'fif ok' );
is( $form->field('bax')->value, 'default_bax', 'value from field default' );
is( $form->field('bax')->fif,   'default_bax', 'fif ok' );

{
    package Mock::Object;
    use Moo;
    has 'foo' => ( is => 'rw' );
    has 'bar' => ( is => 'rw' );
    has 'baz' => ( is => 'rw' );
}
{
    package Test::Object1;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';
    with 'Data::MuForm::Model::Object';

    sub BUILD {
        my $self = shift;
        my $var = 'test';
    }
    has_field 'foo';
    has_field 'bar';
    has_field 'baz';
    has_field 'bax' => ( default => 'bax_from_default' );
    has_field 'zero' => ( type => 'Integer', default => 0 );
    has_field 'foo_list' => ( type => 'Select', multiple => 1, default => [1,3],
       options => [{ value => 1, label => 'One'},
                   { value => 2, label => 'Two'},
                   { value => 3, label => 'Three'},
                  ]
    );

    sub init_values {
        my $self = shift;
        return { bar => 'initbar' };
    }

}

my $obj = Mock::Object->new( foo => 'myfoo', bar => 'mybar', baz => 'mybaz' );

$form = Test::Object1->new;
$form->process( model => $obj, model_id => 1, params => {} );
# test that model is used for value
is( $form->field('foo')->value, 'myfoo', 'field value from model');
is( $form->field('foo')->fif, 'myfoo', 'field fif from model');
is( $form->field('bar')->value, 'mybar', 'field value from model');
is( $form->field('bar')->fif, 'mybar', 'field fif from model');
# test that non-model default is used
is( $form->field('bax')->value, 'bax_from_default', 'non-model field value from default' );
is( $form->field('zero')->value, 0, 'zero default works');
is_deeply( $form->field('foo_list')->value, [1,3], 'multiple default works' );


{
    package Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has 'quuz' => ( is => 'ro', default => 'some_quux' );
    has_field 'foo';
    has_field 'bar';

    sub init_values {
        my $self = shift;
        return { foo => $self->quuz, bar => 'bar!' };
    }
}
$form = Test::Form->new;
is( $form->field('foo')->value, 'some_quux', 'field initialized by init_values' );


{
    package Mock::Object2;
    use Moo;
    has 'meow' => ( is => 'rw' );
}
{
    package Test::Object3;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';
    with 'Data::MuForm::Model::Object';
    has_field 'meow' => ( default => 'this_should_get_overridden' );

}

$obj = Mock::Object2->new( meow => 'the_real_meow' );

$form = Test::Object3->new;
$form->process( model => $obj, model_id => 1, params => {} );
is( $form->field('meow')->value, 'the_real_meow', 'defaults should not override actual model values');


done_testing;
