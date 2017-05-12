package YUI::Test::Goo::Form;
use strict;
use base qw( YUI::Form );

sub object_class { 'YUI::Test::Goo' }

sub init_with_goo {
    my $self = shift;
    $self->init_with_object(@_);
}

sub goo_from_form {
    my $self = shift;
    $self->object_from_form(@_);
}

sub build_form {
    my $self = shift;
    
    $self->add_fields(
    
    id => {
        id      => 'id',
        type    => 'hidden',
        class   => 'serial',
        label   => 'id',
        rank    => 1,
        },

    name => {
        id          => 'name',
        type        => 'text',
        class       => 'varchar',
        label       => 'name',
        tabindex    => 2,
        rank        => 2,
        size        => 16,
        maxlength   => 64,
        },
    );
    
    return $self->SUPER::build_form(@_);
}

1;

