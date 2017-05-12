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
        q{CREATE TABLE emproyee (id integer primary key, name text, post text)},
        q{CREATE TABLE skill (id integer primary key, emproyee_id integer REFERENCES emproyee(id), skill text )},
    ],
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
$mapper->metadata->autoload_all_tables;
my $emproyee = $mapper->metadata->t('emproyee');
my $skill  = $mapper->metadata->t('skill');

$emproyee->insert->values( name => $_->{name}, post => $_->{post} )->execute
    for (
        { name => 'm1', post => 'manager' },
        { name => 'm2', post => 'manager' },
        { name => 'm3', post => 'manager' },
        { name => 'm4', post => 'manager' },
        { name => 'e1', post => undef },
        { name => 'e2', post => undef },
        { name => 'e3', post => undef },
    );

$skill->insert->values( emproyee_id => 1, skill => 'programming' )->execute;
$skill->insert->values( emproyee_id => 2, skill => 'programming' )->execute;
$skill->insert->values( emproyee_id => 6, skill => 'programming' )->execute;

ok $mapper->maps(
    $emproyee => 'MyTest15::Manager',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
    default_condition => [
        $emproyee->c('post') == 'manager'
    ]
);

ok $mapper->maps(
    $skill => 'MyTest15::Skills',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
    attributes => {
        properties => {
            manager => {
                isa => $mapper->relation( 'belongs_to' => 'MyTest15::Manager' ),
            }
        }
    }
);

{
    my $session = $mapper->begin_session;
    my $query = $session->search('MyTest15::Manager');
    is $query->count, 4;
    my $it = $query->execute;

    my $loop_cnt = 0;
    while ( my $e = $it->next ) {
        $loop_cnt++;
        is $e->post, 'manager';
    }
    is $loop_cnt, 4;

    $query->filter( $emproyee->c('id') > 2 );
    my $it2 = $query->execute;
    my $loop_cnt2 = 0;
    while ( my $e = $it2->next ) {
        $loop_cnt2++;
        is $e->post, 'manager';
    }
    is $loop_cnt2, 2;
};

{
    my $session = $mapper->begin_session;
    ok $session->get('MyTest15::Manager' => 1);
    ok !$session->get('MyTest15::Manager' => 5);
};

{
    my $session = $mapper->begin_session;
    my $skill = $session->get( 'MyTest15::Skills' => 1 );
    ok $skill->manager;
};

{
    my $session = $mapper->begin_session;
    my $skill = $session->get( 'MyTest15::Skills' => 3 );
    ok !$skill->manager;
};


done_testing;
