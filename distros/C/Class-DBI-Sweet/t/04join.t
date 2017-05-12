use strict;
use warnings;

use Test::More;

eval "use DBD::SQLite";
plan skip_all => 'needs DBD::SQLite for testing' if $@;

plan tests => 17;

use lib 't/lib';

use_ok('SweetTest');

my ($artist) = SweetTest::Artist->search({ name => 'Caterwauler McCrae' });

is($artist->name, 'Caterwauler McCrae', "Artist retrieved by name");

my @cds = SweetTest::CD->search({ artist => $artist }, { order_by => 'year' });

cmp_ok(scalar @cds, '==', 3, "Correct number of CDs returned");

is($cds[0]->title, "Caterwaulin' Blues", "Correct CD returned first");

is(($cds[0]->next_by_artist({ order_by => 'year' }))[0]->title,
    "Spoonful of bees", "next_by operating correctly");

my ($sql) = $cds[0]->_search({ 'artist.name' => 'Spoon' });

is($sql->{from}, "cd me, artist artist", "FROM statement ok");

is($sql->{where}, "artist.name = ? AND me.artist = artist.artistid",
    "WHERE clause ok");

cmp_ok($cds[2]->year, '==', 2001, "Last CD returned correctly");

($artist) = SweetTest::Artist->search({ 'cds.year' => $cds[2] }, { order_by => 'artistid DESC' });

is($artist->name, 'Random Boy Band', "Join search by object ok");

my ($tag) = $cds[0]->tags;

is($tag->tag, "Blue", "Tag retrieved");

is(($cds[0]->retrieve_next(
    { 'tags.tag' => $tag }, { order_by => 'title' } ))[0]->title,
    'Come Be Depressed With Us', 'Retrieve previous by has_many works');

@cds = SweetTest::CD->search({ 'liner_notes.notes' => 'Buy Merch!' });

cmp_ok(scalar @cds, '==', 1, "Single CD retrieved via might_have");

is($cds[0]->title, "Generic Manufactured Singles", "Correct CD retrieved");

is(($cds[0]->retrieve_next(
    { 'liner_notes.notes' => { "!=", undef } },
    { order_by => 'liner_notes.notes' }
        ))[0]->title, "Forkful of bees", "Order by might_have ok");

is(($cds[0]->retrieve_previous)[0]->title, "Caterwaulin' Blues", 
    "retrieve_previous ok");
    
($artist) = SweetTest::Artist->search_like({ name => '%Boy%' });

cmp_ok( $artist->artistid, '==', 2, "search_like ok" );

my @artists = SweetTest::Artist->search({ 'cds.tags.tag' => 'Shiny' });

cmp_ok( @artists, '==', 2, "two-join search ok" );
