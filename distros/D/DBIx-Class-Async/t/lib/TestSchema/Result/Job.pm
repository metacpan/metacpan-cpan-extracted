package TestSchema::Result::Job;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/ InflateColumn::DateTime /);
__PACKAGE__->table('job');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    created_at => {
        data_type   => 'timestamptz',
        is_nullable => 0,
    },
);
__PACKAGE__->set_primary_key('id');

1;
