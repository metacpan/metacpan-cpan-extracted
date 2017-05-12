use strict;
use warnings;

package TestSchema::Affe;

use parent qw/DBIx::Class/;

__PACKAGE__->load_components(qw/DynamicDefault Core/);
__PACKAGE__->table('affe');

__PACKAGE__->add_columns(
    moo => {
        data_type                 => 'integer',
        dynamic_default_on_update => 'moo_default',
        always_update             => 1,
    },
    kooh => {
        data_type                 => 'text',
        dynamic_default_on_update => 'kooh_default',
    },
);

__PACKAGE__->set_primary_key(qw/moo/);

{
    my $i = 0;

    sub moo_default {
        return ++$i;
    }
}

sub kooh_default {
    return 'zomtec';
}

1;
