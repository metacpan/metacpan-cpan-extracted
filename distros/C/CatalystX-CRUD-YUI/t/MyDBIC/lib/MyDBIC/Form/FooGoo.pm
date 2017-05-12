package MyDBIC::Form::FooGoo;
use strict;
use base qw( MyDBIC::Base::Form );

sub init_with_foogoo {
    my $self = shift;
    $self->init_with_object(@_);
}

sub foogoo_from_form {
    my $self = shift;
    $self->object_from_form(@_);
}

sub build_form {
    my $self = shift;

    $self->add_fields(

        foo_id => {
            id        => 'foo_id',
            type      => 'integer',
            class     => 'integer',
            label     => 'foo_id',
            size      => 24,
            maxlength => 64,
        },

        goo_id => {
            id        => 'goo_id',
            type      => 'integer',
            class     => 'integer',
            label     => 'goo_id',
            size      => 24,
            maxlength => 64,
        },
    );

}

1;

