use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use Test::Exception;

BEGIN {
    {
        package MyApp::Schema::Result::Artist;
        use base 'DBIx::Class::Core';
        __PACKAGE__->table('artists');
        __PACKAGE__->add_columns(
            id => 'int',
            first_album_id => 'int',
        );
        __PACKAGE__->set_primary_key('id');
        __PACKAGE__->has_many('albums', 'MyApp::Schema::Result::Album', 'artist_id');
    }

    {
        package MyApp::Schema::Result::Album;
        use base 'DBIx::Class::Core';
        __PACKAGE__->table('albums');
        __PACKAGE__->add_columns(
            id => 'int',
            artist_id => 'int',
        );
        __PACKAGE__->set_primary_key('id');
        __PACKAGE__->belongs_to('artist', 'MyApp::Schema::Result::Artist', 'artist_id');
    }
    MyApp::Schema::Result::Artist->belongs_to('first_album', 'MyApp::Schema::Result::Album', 'first_album_id');

    {
        package MyApp::Schema;
        use base 'DBIx::Class::Schema';
        __PACKAGE__->register_class(Artist => 'MyApp::Schema::Result::Artist');
        __PACKAGE__->register_class(Album => 'MyApp::Schema::Result::Album');
        __PACKAGE__->load_components('TopoSort');
    }
}

use Test::DBIx::Class qw(:resultsets);

dies_ok { Schema->toposort() } 'toposort dies with a cycle';

my @tables = Schema->toposort(skip => {
    'Artist' => [qw/ first_album /],
});
cmp_deeply( [@tables], ['Artist', 'Album'], "Connected tables are returned in has_many order" );

done_testing;
