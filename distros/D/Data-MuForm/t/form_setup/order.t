use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::Test;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'fee';
    has_field 'fie';
    has_field 'foo' => ( order => 5 );
    has_field 'bar' => ( order => 99 );
    has_field 'mix';
    has_field 'max' => ( order => 35 );

}

my $form = MyApp::Form::Test->new;
ok( $form );
is( $form->field('fee')->order, 5, 'first field' );
is( $form->field('fie')->order, 10, 'second field' );
is( $form->field('foo')->order, 5, 'third field' );
is( $form->field('bar')->order, 99, 'fourth field' );
is( $form->field('mix')->order, 25, 'fifth field' );
is( $form->field('max')->order, 35, 'sixth field' );

my @names;
my @orders;
foreach my $field ( $form->all_sorted_fields ) {
    push @orders, $field->order;
    push @names, $field->name;
}

is_deeply( \@names, ['fee', 'foo', 'fie', 'mix', 'max', 'bar'], 'names in expected order' );
is_deeply( \@orders, [ 5, 5, 10, 25, 35, 99 ], 'order in expected order' );

{
    package MyApp::Form::Role::MyFields;
    use Moo::Role;
    use Data::MuForm::Meta;

    has_field 'r-one';
    has_field 'r-two';
    has_field 'r-three';
}

{
    package MyApp::Form::TestRole;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    with 'MyApp::Form::Role::MyFields';

    has_field 'f-one';
    has_field 'f-two';
    has_field 'f-three';
    has_field 'f-four';

    # put role fields between f-two and f-three
    sub order_fields {
        my $self = shift;
        my @form_order = (1, 2, 6, 7, 8);
        my @role_order = (3, 4, 5);
        foreach my $field ( $self->all_fields ) {
            my $order;
            if ( $field->source eq __PACKAGE__ ) {
                $order = shift @form_order;
            }
            else {
                $order = shift @role_order;
            }
            $field->order($order);
        }
    }

}

$form = MyApp::Form::TestRole->new;
ok( $form, 'form built' );

is( $form->field('f-one')->order, 1, 'first field' );
is( $form->field('f-two')->order, 2, 'second field' );
is( $form->field('f-three')->order, 6, 'third field' );
is( $form->field('f-four')->order, 7, 'fourth field' );
is( $form->field('r-one')->order, 3, 'fifth field' );
is( $form->field('r-two')->order, 4, 'sixth field' );
is( $form->field('r-three')->order, 5, 'seventh field' );

done_testing;
