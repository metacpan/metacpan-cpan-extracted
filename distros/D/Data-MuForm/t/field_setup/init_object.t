use strict;
use warnings;
use Test::More;

# this tests that a multiple select with value from an init_values
# has the right value with both a hashref and a blessed object
{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'foo' => ( type => 'Select', multiple => 1 );
    sub options_foo {
        [
            1 => 'One',
            2 => 'Two',
            3 => 'Three',
            4 => 'Four',
        ]
    }
    has_field 'bar';
}

{
    package FooObject;
    use Moo;
    use Types::Standard -types;
    has 'foo' => ( is => 'ro', isa => ArrayRef );
    has 'bar' => ( is => 'ro', isa => Str );
}

my $form = MyApp::Form::Test->new;
ok( $form );

# try with hashref
my $init_obj = {
    foo => [1],
    bar => 'my_test',
};
$form->process( init_values => $init_obj );
is_deeply( $form->field('foo')->value, [1], 'right value for foo field with hashref init_obj' );

# try with object
my $foo = FooObject->new(
    foo => [1],
    bar => 'my_test',
);
$form->process( init_values => $foo );
is_deeply( $form->field('foo')->value, [1], 'right value for foo field with object init_obj' );

done_testing;
