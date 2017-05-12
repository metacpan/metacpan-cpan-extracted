use strict;
use warnings;
use Test::More;

BEGIN {
    eval "require Moose";
    plan skip_all => 'Moose required this test' if $@;
};

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE artist( id integer primary key, name text )},
        q{CREATE TABLE cd( id integer primary key, title text, artist_id integer references artist(id))},
        q{CREATE TABLE track( id integer primary key, cd_id integer not null references cd(id), track_no int, title text)},
        q{CREATE TABLE linernote ( id integer primary key, note text )},
    ],
});


{
    package MyTest300::Moose::Artist;
    use Moose;

    has 'id' => (
        isa => 'Int',
        is  => 'rw',
    );

    has 'name' => (
        isa => 'Str',
        is  => 'rw',
    );

    has 'cds' => (
        isa => 'ArrayRef[MyTest300::Moose::Cd]|Undef',
        is  => 'rw',
    );

    __PACKAGE__->meta->make_immutable;

    1;
};

{
    package MyTest300::Moose::Cd;
    use Moose;

    has 'id' => (
        isa => 'Int',
        is  => 'rw',
    );

    has 'title' => (
        isa => 'Str',
        is  => 'rw',
    );

    has 'artist_id' => (
        isa => 'Int',
        is  => 'rw',
    );

    has 'artist' => (
        isa => 'Str',
        is  => 'rw',
    );

    has 'tracks' => (
        isa => 'ArrayRef[MyTest300::Moose::Track]|Undef',
        is  => 'rw',
    );

    has 'linernote' => (
        isa => 'Object|Undef',
        is  => 'rw',
    );

    __PACKAGE__->meta->make_immutable;

    1;
};

{
    package MyTest300::Moose::Linernote;
    use Moose;

    has 'id' => (
        isa => 'Int',
        is  => 'rw',
    );

    has 'note' => (
        isa => 'Str',
        is  => 'rw',
    );

    has 'cd' => (
        isa => 'Object|Undef',
        is  => 'rw',
    );

    1;
};

{
    package MyTest300::Moose::Track;
    use Moose;

    has 'id' => (
        isa => 'Int',
        is  => 'rw',
    );

    has 'cd_id' => (
        isa => 'Int',
        is  => 'rw',
    );

    has 'track_no' => (
        isa => 'Int',
        is  => 'rw',
    );

    has 'title' => (
        isa => 'Str',
        is  => 'rw',
    );

    has 'cd' => (
        isa => 'Object|Undef',
        is  => 'rw',
    );

    __PACKAGE__->meta->make_immutable;

    1;
};

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
$mapper->metadata->autoload_all_tables;

ok my $artist_mapper = $mapper->maps(
    $mapper->metadata->t('artist') => 'MyTest300::Moose::Artist',
    attributes => {
        properties => {
            cds => {
                isa => $mapper->relation( has_many => 'MyTest300::Moose::Cd' )
            }
        }
    }
);

ok my $cd_mapper = $mapper->maps(
    $mapper->metadata->t('cd') => 'MyTest300::Moose::Cd',
    attributes => {
        properties => {
            artist => {
                isa => $mapper->relation( belongs_to => 'MyTest300::Moose::Artist' ),
            },
            tracks => {
                isa => $mapper->relation( has_many => 'MyTest300::Moose::Track' ),
            },
            linernote => {
                isa => $mapper->relation( has_one => 'MyTest300::Moose::Linernote'),
            }
        }
    }
);

ok my $track_mapper = $mapper->maps(
    $mapper->metadata->t('track') => 'MyTest300::Moose::Track',
    attributes => {
        properties => {
            cd => {
                isa => $mapper->relation( belongs_to => 'MyTest300::Moose::Cd' )
            }
        }
    }
);


ok my $linernote_mapper = $mapper->maps(
    $mapper->metadata->t('linernote') => 'MyTest300::Moose::Linernote',
    attributes => {
        properties => {
            cd => {
                isa => $mapper->relation( has_one => 'MyTest300::Moose::Cd' )
            }
        }
    }
);

{
    ok my $artist = MyTest300::Moose::Artist->new( name => 'artist1' );
    ok $artist->can('id');
    ok $artist->can('name');
    ok $artist->can('cds');
    ok $artist->can('__mapper__');
    ok $artist->meta->is_immutable;

    my $obj = $artist_mapper->mapping(
        {   id   => 10,
            name => 'name',
        }
    );

    is $obj->id, 10;
    is $obj->name, 'name';

};

done_testing;
