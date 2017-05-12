use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE player (id integer primary key, name text, play text)},
    ],
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
$mapper->metadata->autoload_all_tables;
my $player = $mapper->metadata->t('player');

ok $mapper->maps(
    $player => 'MyTest17::Player',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

ok $mapper->maps(
    $player => 'MyTest17::BaseballPlayer',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
    default_condition => [ $player->c('play') == 'baseball' ],
    default_value => { play => 'baseball' },
);

ok $mapper->maps(
    $player => 'MyTest17::FootballPlayer',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
    default_condition => [ $player->c('play') == 'football' ],
    default_value => { play => 'football' },
);

{
    my $session = $mapper->begin_session;
    my $bp = MyTest17::BaseballPlayer->new( name => 'bp1' );
    $session->add($bp);
    $session->flush;

    my $query = $session->search('MyTest17::BaseballPlayer');
    is $query->count, 1;
    my $bp1 = $query->first;
    is $bp1->name, 'bp1';
    is $bp1->play, 'baseball';

};

{
    my $session = $mapper->begin_session;
    my $bp = MyTest17::FootballPlayer->new( name => 'fp1' );
    $session->add($bp);
    $session->flush;

    my $query = $session->search('MyTest17::FootballPlayer');
    is $query->count, 1;
    my $fp1 = $query->first;
    is $fp1->name, 'fp1';
    is $fp1->play, 'football';
};

{
    my $session = $mapper->begin_session;
    my $query = $session->search('MyTest17::Player');
    is $query->count, 2;
};

done_testing;
