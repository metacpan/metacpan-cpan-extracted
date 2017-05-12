use strict;
use warnings;

use lib 't/lib';

use Test::More;
use File::Temp qw/ tempdir /;

use MyComics;

plan tests => 7;

my $store = MyComics->new;

is_deeply [ sort $store->model_names ], [ 'Comic' ], "all_models";
is_deeply [ sort $store->model_classes ], [ 'MyComics::Model::Comic' ], "all_model_classes";

my $db = 't/db/comics.sqlite';
unlink $db;   # to start fresh

$store = MyComics->connect( $db );

my $x = $store->create( 'Comic', 
    penciler => 'Yanick Paquette',
    writer => 'Alan Moore',
    issue => 2,
    series => 'Terra Obscura',
)->store;


$store->create( 'Comic', 
    penciler => 'Michel Lacombe',
    writer => 'Michel Lacombe',
    issue => 1,
    series => 'One Bloody Year',
)->store;

ok $store->exists( Comic => 'One Bloody Year-1' ), 'OBY';
ok $store->exists( Comic => 'Terra Obscura-2' ), 'TO';

is_deeply [ sort { $a->[0] cmp $b->[0] } MyComics::Model::Comic->indexes ] 
    => [ [ 'penciler'], ['writer'] ], 'indexes';

subtest 'search' => sub {
    my @comics = $store->search('Comic')->all;

    is @comics => 2;

    @comics = $store->search('Comic', { writer => { like => '%Lacombe' } })->all;

    is @comics => 1, 'OBY';

    is $comics[0]->series => 'One Bloody Year', 'right one';
};

subtest 'next' => sub {
    plan tests => 2;
    my $rs = $store->search('Comic');

    while( my $e = $rs->next ) {
        pass $e->writer;
    }
};
