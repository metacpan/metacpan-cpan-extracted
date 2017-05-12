use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIx::ObjectMapper::Metadata;
use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper::Mapper;

use Scalar::Util;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{ CREATE TABLE artist (id integer primary key, firstname text not null, lastname text not null)}
    ]
});

my $meta = DBIx::ObjectMapper::Metadata->new( engine => $engine );
my $artist_table = $meta->table( artist => 'autoload' );

{
    my $mapped_class = 'MyTest::Basic::Artist';

    dies_ok {
        DBIx::ObjectMapper::Mapper->new(
            $artist_table => $mapped_class,
            constructor => { auto => 1 },
            accessors => { auto => 1 },
        );
    };

    dies_ok {
        DBIx::ObjectMapper::Mapper->new(
            $artist_table => $mapped_class,
            constructor => { auto => 1 },
        );
    };

    ok my $mapper = DBIx::ObjectMapper::Mapper->new(
        $artist_table => $mapped_class,
        accessors => {
            auto => 1,
            do_replace => 1,
        },
    );

    ok( DBIx::ObjectMapper::Mapper->is_initialized($mapped_class) );
    ok $mapped_class->can('firstname');
    ok $mapped_class->can('lastname');
    ok $mapped_class->can('id');

    ok my $obj = $mapped_class->new(
        { id => 1, firstname => 'f', lastname => 'l' } );
    is $obj->firstname, 'f';
    is $obj->lastname, 'l';
    is $obj->id, 1;
};

done_testing;

