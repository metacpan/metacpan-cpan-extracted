package    # hide from PAUSE
    CafeInsertion::Result::Cream;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('cream');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    fat_free => { data_type => 'boolean', default => 0 }
);

__PACKAGE__->set_primary_key('id');

1;
