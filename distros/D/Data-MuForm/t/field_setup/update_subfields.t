use strict;
use warnings;
use Test::More;

# tests that 'by_flag' works for contains
# Test 'by_type' flag
{
    package Test::Form;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

#   sub build_update_subfields {{
#       by_flag => { contains => { wrapper_class => ['rep_elem'] } },
#       by_type => { 'Select' => { wrapper_class => ['sel_wrapper'] },
#                    'Boolean' => { element_class => ['sel_elem'] },
#       },
#   }}
    has_field 'records' => ( type => 'Repeatable' );
    has_field 'records.one';
    has_field 'records.two';
    has_field 'foo' => ( type => 'Select', options => [
        { value => 1, label => 'One' }, { value => 2, label => 'Two' }] );
    has_field 'bar' => ( type => 'Boolean' );

    sub after_build_fields {
        my $self = shift;
        foreach my $field ( $self->all_repeatable_fields ) {
            $field->init_instance({ 'ra.wa.class' => ['rep_elem'] });
        }
        foreach my $field ( $self->all_fields ) {
            if ( $field->type eq 'Select' ) {
                $field->render_args->{wrapper_attr}{class} = ['sel_wrapper'];
            }
            elsif ( $field->type eq 'Boolean' ) {
                $field->render_args->{element_attr}{class} = ['sel_elem'];
            }
        }
    }

}

my $form = Test::Form->new;
$form->process;
is_deeply( $form->field('records.0')->render_args->{wrapper_attr}{class}, ['rep_elem'], 'contains has correct class by flag' );
is_deeply( $form->field('foo')->render_args->{wrapper_attr}{class}, ['sel_wrapper'], 'correct class by type' );
is_deeply( $form->field('bar')->render_args->{element_attr}{class}, ['sel_elem'], 'correct class by type' );

done_testing;
