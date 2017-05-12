package YUI::Test::Foo::Form;
use strict;
use base qw( YUI::Form );

sub init_with_foo {
    my $self = shift;
    $self->init_with_object(@_);
}

sub foo_from_form {
    my $self = shift;
    $self->object_from_form(@_);
}

sub build_form {
    my $self = shift;

    $self->add_fields(

        id => {
            id          => 'id',
            type        => 'hidden',
            class       => 'serial',
            label       => 'id',
            rank        => 1,
            description => 'id is a PK for Foo class'
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

        static => {
            id        => 'static',
            type      => 'text',
            class     => 'character',
            label     => 'static',
            tabindex  => 3,
            rank      => 3,
            size      => 8,
            maxlength => 64,
        },

        my_int => {
            id        => 'my_int',
            type      => 'integer',
            class     => 'integer',
            label     => 'my_int',
            tabindex  => 4,
            rank      => 4,
            size      => 24,
            maxlength => 64,
        },

        my_dec => {
            id        => 'my_dec',
            type      => 'numeric',
            class     => 'float',
            label     => 'my_dec',
            tabindex  => 5,
            rank      => 5,
            size      => 16,
            maxlength => 32,
        },

        my_bool => {
            id       => 'my_bool',
            type     => 'boolean',
            label    => 'my_bool',
            tabindex => 6,
            rank     => 6,
            class    => 'boolean',
        },

        ctime => {
            id        => 'ctime',
            type      => 'datetime',
            class     => 'timestamp',
            label     => 'ctime',
            tabindex  => 7,
            rank      => 7,
            size      => 0,
            maxlength => 64,
        },
    );

}

1;

