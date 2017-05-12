use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $mapper = DBIx::ObjectMapper->new(
    engine => DBIx::ObjectMapper::Engine::DBI->new({
        dsn => 'DBI:SQLite:',
        username => '',
        password => '',
        on_connect_do => [
            q{CREATE TABLE tab1 (id integer primary key)},
            q{CREATE TABLE tab2 (id integer primary key, tab1_id integer REFERENCES tab1(id) UNIQUE)},
        ]
    }),
);

$mapper->metadata->autoload_all_tables;
my $tab1 = $mapper->metadata->t('tab1');
my $tab2 = $mapper->metadata->t('tab2');
$tab1->insert->values(id => 1)->execute();
$tab2->insert->values(id => 2, tab1_id => 1 )->execute();
$tab2->insert->values(id => 1, tab1_id => 2 )->execute();

is_deeply $tab2->foreign_key, [
    {
        table => 'tab1',
        refs => ['id'],
        keys => ['tab1_id'],
    }
];

ok $mapper->maps(
    $tab1 => 'MyTest::Tab1',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
    attributes => {
        properties => {
            tab2 => {
                isa => $mapper->relation( has_one => 'MyTest::Tab2' )
            }
        }
    }
);

ok $mapper->maps(
    $tab2 => 'MyTest::Tab2',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

{
    my $session = $mapper->begin_session;
    my $t1 = $session->get( 'MyTest::Tab1' => 1 );
    is $t1->id, 1;
    ok $t1->tab2;
    is $t1->tab2->id, 2;
    is $t1->tab2->tab1_id, 1;
};

done_testing;

