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
        q{CREATE TABLE books( id integer primary key, title text)},
    ],
});

my $mapper = DBIx::ObjectMapper->new(
    engine => $engine,
);

my $book = $mapper->metadata->table( 'books' => 'autoload' );

$mapper->maps(
    $book => 'MyTest18::Books',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

{
    my $session = $mapper->begin_session( no_cache => 1 );
    do_test($session);
    is $session->uow->{query_cnt}, 11;
};

{
    my $session = $mapper->begin_session();
    do_test($session);
    is $session->uow->{query_cnt}, 1;
};

{
    my $mapper2 = DBIx::ObjectMapper->new(
        engine => $engine,
        session_attr => {
            no_cache => 1
        },
    );
    my $session = $mapper2->begin_session();
    do_test($session);
    is $session->uow->{query_cnt}, 11;
};

sub do_test {
    my $session = shift;
    $session->add( MyTest18::Books->new( title => 'title' . $_ ) ) for 1 .. 10;

    my $it = $session->search('MyTest18::Books')->execute;
    my $loop_cnt = 0;
    while( my $b = $it->next ) {
        ok $b->id;
        $loop_cnt++;
    }
    is $loop_cnt, 10;

    my @books;
    for( 1 .. 10 ) {
        ok my $b = $session->get('MyTest18::Books' => $_);
        push @books, $b;
    }

    $session->delete( $_ ) for @books;
}

done_testing;
