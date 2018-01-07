use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 2;

use MyComics;
use MyComics::Model::Comic;

my $db = ':memory:';
my $store = MyComics->connect( $db );

my $comic = MyComics::Model::Comic->new(
    series   => 'Wonder Woman: Earth One',
    penciler => 'Yanick Paquette',
    writer   => 'Grant Morisson',
);

$store->set($comic);

my $other_comic = MyComics::Model::Comic->new(
    series   => 'Arkham Asylum',
    penciler => 'Dave McKean',
    writer   => 'Grant Morisson',
);

$other_comic->save($store);

my $count = $store->search('Comic')->where({ writer => { like => 'Grant%' }})->count;

is $count => 2, '2 comics with Grant';

is $store->get( 'Comic', '-Wonder Woman: Earth One' )->penciler 
    => 'Yanick Paquette';

