use strict;
use warnings;
use Test::More;
use DateTime;
use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE lazyload( id integer primary key, comment text, add_comment1 text, add_comment2 text, add_comment3 text, created datetime, tag text )},
    ],
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );

my $lazy = $mapper->metadata->table( 'lazyload' => 'autoload' );
my $now = DateTime->now;
$lazy->insert->values($_)->execute for(
    { comment => 'first', add_comment1 => 'first add_comment1', add_comment2 => 'first add_comment2', add_comment3 => 'first add_comment3', created => $now, tag => 'hoge' },
    { comment => 'second', add_comment1 => 'second add_comment1', tag => 'hoge2' },
);

ok $mapper->maps(
    $lazy => 'MyTest13::Lazy',
    constructor => { auto => 1 },
    accessors   => { auto => 1 },
    attributes  => {
        properties => {
            comment => {
                lazy => 1,
            },
            add_comment1 => {
                lazy => 'add_comment',
            },
            add_comment2 => {
                lazy => 'add_comment',
            },
            add_comment3 => {
                lazy => 'add_comment',
            },
            created => {
                lazy => 1,
            }
        }
    }
);


{
    my $session = $mapper->begin_session;
    my $d = $session->get( 'MyTest13::Lazy' => 1 );
    is $d->id, 1;
    is $d->comment, 'first'; # execute query
    is $d->add_comment1, 'first add_comment1';
    is $d->add_comment2, 'first add_comment2';
    is $d->add_comment3, 'first add_comment3';
    ok $d->created;
    is $session->uow->query_cnt, 4;
    ok !$d->__mapper__->is_modified;
};

{
    my $session = $mapper->begin_session;
    my $it = $session->search('MyTest13::Lazy')->execute;
    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        ok $c->id;
        ok $c->comment;
        $loop_cnt++;
    }
    ok $loop_cnt;
    is $session->uow->query_cnt, 1 + $loop_cnt;
};

{
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest13::Lazy');

    my $it = $session->search('MyTest13::Lazy')
        ->lazy( $attr->p('tag') )->execute;
    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        ok $c->id;
        ok $c->tag;
        $loop_cnt++;
    }
    ok $loop_cnt;
    is $session->uow->query_cnt, $loop_cnt + 1;
};


{
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest13::Lazy');
    my $it = $session->search('MyTest13::Lazy')
        ->eager( $attr->p('comment') )->execute;
    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        ok $c->id;
        ok $c->comment;
        $loop_cnt++;
    }
    ok $loop_cnt;
    is $session->uow->query_cnt, 1;
};

{
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest13::Lazy');
    my $it = $session->search('MyTest13::Lazy')
        ->eager( $attr->p('comment') )->lazy( $attr->p('comment') )->execute;
    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        ok $c->id;
        ok $c->comment;
        $loop_cnt++;
    }
    ok $loop_cnt;
    is $session->uow->query_cnt, 1 + $loop_cnt;
};

{
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest13::Lazy');
    my $it = $session->search('MyTest13::Lazy')
        ->eager( $attr->p('add_comment1') )->execute;
    my $loop_cnt = 0;
    while( my $c = $it->next ) {
        ok $c->id;
        ok $c->add_comment1;
        $loop_cnt++;
    }
    ok $loop_cnt;
    is $session->uow->query_cnt, 1;
};



done_testing;
