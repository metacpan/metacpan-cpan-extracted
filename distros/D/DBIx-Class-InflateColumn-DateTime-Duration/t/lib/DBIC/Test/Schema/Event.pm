package DBIC::Test::Schema::Event;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class Class::Accessor::Grouped/;
};

__PACKAGE__->load_components(qw/InflateColumn::DateTime::Duration Core/);
__PACKAGE__->table('event');
__PACKAGE__->source_name('Event');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'INT',
        is_auto_increment => 1,
        is_nullable       => 0,
        extras            => {unsigned => 1}
    },
    label => {
        data_type   => 'VARCHAR',
        size        => 25,
        is_nullable => 0,
    },
    length => {
        data_type          => 'VARCHAR',
        size               => 45,
        is_nullable        => 0,
        is_duration        => 1,
    },
);
__PACKAGE__->set_primary_key('id');

1;
