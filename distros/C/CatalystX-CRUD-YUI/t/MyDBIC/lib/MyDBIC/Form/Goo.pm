package MyDBIC::Form::Goo;
use strict;
use base qw( MyDBIC::Base::Form );

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
            id    => 'id',
            type  => 'hidden',
            class => 'serial',
            label => 'id',
            rank  => 1,
        },

        name => {
            id        => 'name',
            type      => 'text',
            class     => 'varchar',
            label     => 'name',
            tabindex  => 2,
            rank      => 2,
            size      => 16,
            maxlength => 64,
        },
    );
}

1;

