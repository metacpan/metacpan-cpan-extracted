#!/usr/bin/perl

use lib 't';
use Test::DB;
use Test::More tests => 8;
use strict;
use warnings;

### Tests for adding relationships -- using iterators

BEGIN {
    use_ok 'DBIx::Mint';
    use_ok 'DBIx::Mint::Schema';
}

{
    package Bloodbowl::Coach; use Moo;
    with 'DBIx::Mint::Table';
    
    has id           => ( is => 'rw', predicate => 1 );
    has name         => ( is => 'rw' );
    has email        => ( is => 'rw' );
    has password     => ( is => 'rw' );
}
{
    package Bloodbowl::Team; use Moo;
    with 'DBIx::Mint::Table';

    has id           => ( is => 'rw' );
    has name         => ( is => 'rw' );
    has coach        => ( is => 'rw' );
}
{
    package Bloodbowl::Player; use Moo;
    with 'DBIx::Mint::Table';

    has id           => ( is => 'rw' );
    has name         => ( is => 'rw' );
    has position     => ( is => 'rw' );
    has team         => ( is => 'rw' );
}

my $schema = DBIx::Mint::Schema->instance;
isa_ok( $schema, 'DBIx::Mint::Schema');

$schema->add_class(
    class    => 'Bloodbowl::Coach',
    table    => 'coaches',
    pk       => 'id',
    auto_pk  => 1
);

$schema->add_class(
    class    => 'Bloodbowl::Team',
    table    => 'teams',
    pk       => 'id',
    auto_pk  => 1
);

$schema->add_class(
    class    => 'Bloodbowl::Player',
    table    => 'players',
    pk       => 'id',
    auto_pk  => 1
);

# This is a one-to-one relationship...
$schema->add_relationship(
    from_class     => 'Bloodbowl::Team',
    to_class       => 'Bloodbowl::Player',
    to_field       => 'team',
    method         => 'get_players',
    result_as      => 'as_iterator',
);

can_ok('Bloodbowl::Team',    'get_players' );

# Database connection
my $mint = Test::DB->connect_db;
ok( DBIx::Mint->instance->has_connector,    'Mint has a database connection');

{
    my $team = Bloodbowl::Team->find(1);
    isa_ok($team, 'Bloodbowl::Team');
    my $iter = $team->get_players;
    isa_ok $iter, 'DBIx::Mint::ResultSet';
    
    my $count = 0;
    while (my $player = $iter->next) {
        $count++ if ref $player eq 'Bloodbowl::Player' && $player->team == 1;
    }
    is $count, 5,                           'Relationship returns an iterator that works';
}

done_testing();
