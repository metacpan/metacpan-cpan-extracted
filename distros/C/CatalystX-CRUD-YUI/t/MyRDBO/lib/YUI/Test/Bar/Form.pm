package YUI::Test::Bar::Form;
use strict;
use base qw( YUI::Form );

sub init_with_bar {
    my $self = shift;
    $self->init_with_object(@_);
}

sub bar_from_form {
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
            description => 'id is the PK'
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
            description => 'name is a varchar'
        },

        foo_id => {
            id          => 'foo_id',
            type        => 'integer',
            class       => 'integer',
            label       => 'foo_id',
            tabindex    => 3,
            rank        => 3,
            size        => 24,
            maxlength   => 64,
            description => 'foo_id is a FK'
        },
    );

}

1;

