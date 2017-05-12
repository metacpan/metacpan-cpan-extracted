use strict;
use warnings;
use Test::More;

{

    package My::CustomIdForm;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+name' => ( default => 'F123' );
    has '+field_prefix' => ( default => 'ffm' );

    has_field 'foo';
    has_field 'bar';

    sub after_build_fields {
        my $self = shift;
        foreach my $field ( values %{$self->index} ) {
            $field->{methods}->{build_id} = \&build_id;
        }
    }
    sub build_id {
        my $self = shift;
        my $form_name = $self->form->name;
        return $form_name . "." . $self->full_name;
    }
}
my $form = My::CustomIdForm->new;
is( $form->field('foo')->id, 'F123.foo', 'got correct id' );

# test dynamic field ID
{
    package My::DynamicFieldId;
    use Moo::Role;
    around 'id' => sub {
        my $orig = shift;
        my $self = shift;
        my $form_name = $self->form->name;
        return $form_name . "." . $self->full_name;
    };
}

{

    package My::CustomIdForm2;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has '+name' => ( default => 'D123' );

    has_field 'foo';
    has_field 'bar';

    sub after_build_fields {
        my $self = shift;
        foreach my $field ( values %{$self->index} ) {
            Role::Tiny->apply_roles_to_object($field, 'My::DynamicFieldId');
        }
    }
}

$form = My::CustomIdForm2->new;
is( $form->field('foo')->id, 'D123.foo', 'got correct id' );


done_testing;
