use strict;
use warnings;

use Test::More tests => 4;
use t::Test;

my $store_file = t::Test->tmp_sqlite;
my $store = DBIx::NoSQL->connect( $store_file );
ok( $store );

$store->set('Artist' => 'Foo' => { bar => 'baz' } );

my $rs = $store->search('Artist');

my @all = $rs->all;
my @next;

while(my $artist = $rs->next ) {
    push @next, $artist;
}

is @all => 1;
is @next => 1;

is_deeply \@all => \@next;
