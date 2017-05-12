package    # hide from PAUSE
    CafeInsertion::Result::Sugar;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('sugar');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    sweetness => { data_type => 'integer', default => '2' }
);

__PACKAGE__->set_primary_key('id');

1;
