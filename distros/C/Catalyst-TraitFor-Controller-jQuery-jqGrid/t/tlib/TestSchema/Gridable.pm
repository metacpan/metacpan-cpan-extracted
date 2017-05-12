use strict;
use warnings;

package TestSchema::Gridable;

use parent 'DBIx::Class';

__PACKAGE__->load_components('Core');
__PACKAGE__->table('griddable');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
    },
    column1 => { data_type => 'varchar', size => 50 },
    column2 => { data_type => 'varchar', size => 50 },
    column3 => { data_type => 'varchar', size => 50 },
);

__PACKAGE__->set_primary_key('id');

1;
