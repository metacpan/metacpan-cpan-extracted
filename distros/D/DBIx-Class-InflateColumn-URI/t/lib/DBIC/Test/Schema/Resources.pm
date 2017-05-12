package DBIC::Test::Schema::Resources;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class Class::Accessor::Grouped/;
};

__PACKAGE__->load_components(qw/InflateColumn::URI Core/);
__PACKAGE__->table('resources');
__PACKAGE__->source_name('Resources');
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
    url => {
        data_type          => 'VARCHAR',
        size               => 255,
        is_nullable        => 0,
        is_uri             => 1,
        default_uri_scheme => 'http'
    },
);
__PACKAGE__->set_primary_key('id');

1;
