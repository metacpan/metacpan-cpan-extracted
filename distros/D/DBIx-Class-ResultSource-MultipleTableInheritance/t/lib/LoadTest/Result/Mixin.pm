package    # hide from PAUSE
    LoadTest::Result::Mixin;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('mixin');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    words => { data_type => 'text' }
);

__PACKAGE__->set_primary_key('id');

1;
