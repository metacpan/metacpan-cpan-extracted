use strict;
use warnings;

package TestSchema::Table;

use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/DynamicDefault Core/);
__PACKAGE__->table('fubar');

__PACKAGE__->add_columns(
        quux => {
            data_type                 => 'integer',
            dynamic_default_on_create => 'quux_default',
        },
        garply => {
            data_type                 => 'integer',
            is_nullable               => 1,
            dynamic_default_on_update => sub { return $$ },
        },
        foo => {
            data_type                 => 'integer',
            accessor                  => 'corge',
            dynamic_default_on_create => \&corge_default,
            dynamic_default_on_update => 'corge_default',
        },
        fred => { data_type => 'text' },
);

__PACKAGE__->set_primary_key(qw/quux/);

{
    my $i = 0;

    sub quux_default {
        return ++$i;
    }

    sub corge_default {
        my ($self) = @_;

        return 'update' . ++$i if $self->in_storage;
        return 'create';
    }
}

1;
