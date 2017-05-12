#!/usr/bin/perl

use lib 't';
use Test::DB;
use Test::More tests => 9;
use strict;
use warnings;

### Tests for adding relationships -- one-to-one (result_as single)

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

# This is a one-to-one relationship...
$schema->add_relationship(
    from_class     => 'Bloodbowl::Coach',
    to_class       => 'Bloodbowl::Team',
    to_field       => 'coach',
    method         => 'get_team',
    result_as      => 'single',
    inverse_method => 'get_coach',
    inv_result_as  => 'single',
);

can_ok('Bloodbowl::Coach', 'get_team' );
can_ok('Bloodbowl::Team',  'get_coach');

# Database connection
my $mint = Test::DB->connect_db;
ok( DBIx::Mint->instance->has_connector,    'Mint has a database connection');

{
    my $coach = Bloodbowl::Coach->find(1);
    my $team  = $coach->get_team;
    isa_ok($team, 'Bloodbowl::Team');
    is $team->name, 'Tinieblas',            'The relationship works from -> to classes';
}
{
    my $team  = Bloodbowl::Team->find(1);
    my $coach = $team->get_coach;
    is $coach->password, 'xxxx',            'Relationship works to -> from classes';
}

done_testing();
