use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Trap;
use DBIx::Class::ResultSet::RecursiveUpdate;

use lib 't/lib';
use DBSchema;

my $schema = DBSchema->get_test_schema();

# OK, create podcast that belongs_to owner
my $podcast = $schema->resultset('Podcast')->create({
            title => 'Pirates of the Caribbean',
            owner => {name => 'Bob'} });

is( $podcast->title, 'Pirates of the Caribbean', 'podcast name is correct');
is( $podcast->owner->name, 'Bob', 'owner is correct' );
my $owner = $podcast->owner;

# FAIL: trying to update podcast: set owner to NULL
DBIx::Class::ResultSet::RecursiveUpdate::Functions::recursive_update(
    resultset => $schema->resultset('Podcast'),
    updates => {
        title => 'Pirates of the Caribbean II',
        owner => undef
    },
    object => $podcast );
$podcast->discard_changes;

# OK, title updated correctly
is( $podcast->title, 'Pirates of the Caribbean II', 'podcast name is correct');

ok( ! $podcast->owner, 'no podcast owner');

# clear db
$podcast->delete;
$owner->delete;

done_testing;
