#! /usr/bin/perl

use lib 't';
use Test::DB;
use DBIx::Mint;
use Test::More tests => 13;
use strict;
use warnings;
use v5.10;

# Tests the examples in DBIx::Mint POD synopsis

# Connect to the database
my $mint = Test::DB->connect_db;
isa_ok $mint, 'DBIx::Mint';

{
    # Without a schema, you can use the DBIx::Mint::ResultSet class
    my $rs = DBIx::Mint::ResultSet->new( table => 'coaches' );
    isa_ok $rs, 'DBIx::Mint::ResultSet';

    # Joins. This will retrieve all the players for coach #3
    my @team_players = $rs->search( { 'me.id' => 1 } )
                       ->inner_join( 'teams',   { 'me.id'    => 'coach' })
                       ->inner_join( 'players', { 'teams.id' => 'team'  })
                       ->all;

    my $count;
    foreach (@team_players) {
        $count++ if ref $_ eq 'HASH' && $_->{team} == 1;
    }
    is $count, 5,      'Returned all records correctly';
}
{
    {
        package Bloodbowl::Team;
        use Moo;
        with 'DBIx::Mint::Table';
        
        has id   => (is => 'rw' );
        has name => (is => 'rw' );
    }
    
    my $schema = $mint->schema;
    isa_ok $schema, 'DBIx::Mint::Schema';
    
    $schema->add_class(
         class      => 'Bloodbowl::Team',
         table      => 'teams',
         pk         => 'id',
         auto_pk => 1,
    );
    isa_ok $schema->for_class('Bloodbowl::Team'), 'DBIx::Mint::Schema::Class';

    $schema->add_class(
         class      => 'Bloodbowl::Player',
         table      => 'players',
         pk         => 'id',
         is_auto_pk => 1,
    );
    isa_ok $schema->for_class('Bloodbowl::Player'), 'DBIx::Mint::Schema::Class';

    # This is a one-to-many relationship
    $schema->add_relationship(
         from_class     => 'Bloodbowl::Team',
         to_class       => 'Bloodbowl::Player',
         to_field       => 'team',
         method         => 'get_players',
         result_as      => 'all',
         inverse_method => 'get_team',
         inv_result_as  => 'single',
    );

    my $team = Bloodbowl::Team->find(1);
    can_ok $team, 'get_players';

    my @team_players = $team->get_players;
    my $count;
    foreach (@team_players) {
        $count++ if ref $_ eq 'Bloodbowl::Player' && $_->{team} == 1;
    }
    is $count, 5,      'Returned all records correctly'; 
}
{
    my $team = Bloodbowl::Team->find(1);
    $team->name('Los Invencibles');
    $team->update;
    
    my $test = Bloodbowl::Team->find(1);
    is $test->name, 'Los Invencibles',   'Record updated correctly';
}
{
    my $rs = DBIx::Mint::ResultSet->new( table => 'coaches' );
    my ($sql) = $rs->inner_join( 'teams', { id => 'coach' } )->select_sql;
    like $sql, qr{SELECT \* FROM coaches AS me},   'Join conditions are correct 1';
    like $sql, qr{INNER JOIN teams AS teams},      'Join conditions are correct 2';
    like $sql, qr{me\.id = teams\.coach},          'Join conditions are correct 3';
}
{
    my $rs = DBIx::Mint::ResultSet->new( table => 'coaches' );
    my ($sql) =$rs->inner_join( ['teams', 't'], { 'me.id' => 't.coach' } )->select_sql;
    like $sql, qr{SELECT \* FROM coaches AS me INNER JOIN teams AS t ON \( me\.id = t\.coach \)},
        'Join with aliased tables works as advertised';
}

done_testing();
