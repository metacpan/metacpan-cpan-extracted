package TestApp::Schema::Result::Resource::Artist;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Ordered Core /);
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_numeric => 1,
        is_auto_increment => 1
    },
    name => {
        data_type => 'varchar',
    },
    password => {
        data_type => 'varchar',
    },
    'position',
    {
        data_type => 'integer',
        is_numeric => 1,
    },
);

__PACKAGE__->set_primary_key ('id');
__PACKAGE__->resultset_attributes({ order_by => 'position' });
__PACKAGE__->position_column('position');

__PACKAGE__->has_many(
   'albums',
   'TestApp::Schema::Result::Resource::Album',
   'artist_id'
);

__PACKAGE__->has_many(
   'concerts',
   'TestApp::Schema::Result::Resource::Concert',
   'artist_id'
);

1;
