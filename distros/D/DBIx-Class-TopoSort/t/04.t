use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Deep;
use List::MoreUtils qw( first_index );

BEGIN {
    {
        package MyApp::Schema::Result::Artist;
        use base 'DBIx::Class::Core';
        __PACKAGE__->table('artists');
        __PACKAGE__->add_columns(
            id => 'int',
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
        __PACKAGE__->has_many('tracks', 'MyApp::Schema::Result::Track', 'album_id');
    }

    {
        package MyApp::Schema::Result::Track;
        use base 'DBIx::Class::Core';
        __PACKAGE__->table('tracks');
        __PACKAGE__->add_columns(
            id => 'int',
            album_id => 'int',
        );
        __PACKAGE__->set_primary_key('id');
        __PACKAGE__->belongs_to('album', 'MyApp::Schema::Result::Album', 'album_id');
    }

    {
        package MyApp::Schema;
        use base 'DBIx::Class::Schema';
        __PACKAGE__->register_class(Artist => 'MyApp::Schema::Result::Artist');
        __PACKAGE__->register_class(Album => 'MyApp::Schema::Result::Album');
        __PACKAGE__->register_class(Track => 'MyApp::Schema::Result::Track');
        __PACKAGE__->load_components('TopoSort');
    }
}

use Test::DBIx::Class qw(:resultsets);

sub is_before {
    my ($list, $first, $second) = @_;
    my $f = first_index { $_ eq $first } @$list;
    my $s = first_index { $_ eq $second } @$list;
    return $f < $s;
}

my @tables = Schema->toposort();
ok(
    is_before(\@tables, 'Artist', 'Album'),
    "Artist is before Album",
);
ok(
    is_before(\@tables, 'Album', 'Track'),
    "Album is before Track",
);

done_testing;
