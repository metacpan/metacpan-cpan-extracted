package TestApp::Schema::Result::Resource::Concert;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('concert');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_numeric => 1,
        is_auto_increment => 1
    },
    artist_id => {
        data_type => 'int',
        is_numeric => 1,
    },
    location => {
        data_type => 'varchar',
    },
);

__PACKAGE__->set_primary_key ('id');

__PACKAGE__->belongs_to(
    'artist',
    'TestApp::Schema::Result::Resource::Artist',
    'artist_id'
);

1;
