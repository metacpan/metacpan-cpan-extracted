use strict;
use warnings;
use Test::More;
use Capture::Tiny;
use Try::Tiny;
use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TEMP TABLE books( id integer primary key, title text)},
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
    my $session = $mapper->begin_session();
    is $session->autocommit, 1;
    is $session->autoflush, 0;
    try {
        $session->txn(
            sub{
                is $session->autoflush, 1;
                $session->add( MyTest18::Books->new( title => 'title' . $_ ) )
                    for 1 .. 5;
                die;
                $session->add( MyTest18::Books->new( title => 'title' . $_ ) )
                    for 6 .. 10;
            }
        );
    };
    is $session->autoflush, 0;
    my ($stdout, $stderr) = Capture::Tiny::capture { $session->rollback };
    ok $stderr =~ /Can't rollback/;
};

{
    my $session = $mapper->begin_session;
    is $session->search('MyTest18::Books')->count, 0;
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->add( MyTest18::Books->new( title => 'title' . $_ ) ) for 1 .. 10;
    $session->commit;

    ok my $b1 = $session->get('MyTest18::Books' => 1);
    $b1->title('title1-update');
    $session->commit;
};

{
    $book->delete->execute;
    my $session = $mapper->begin_session( autocommit => 0 );
    is $session->autoflush, 0;

    try {
        $session->txn(
            sub{
                is $session->autoflush, 1;
                $session->add( MyTest18::Books->new( title => 'title' . $_ ) )
                    for 1 .. 5;
                $session->add( MyTest18::Books->new( title => 'title' . $_ ) )
                    for 6 .. 10;
            }
        );
    };

    is $session->autoflush, 0;
    $session->commit;
};

{
    my $session = $mapper->begin_session;
    is $session->search('MyTest18::Books')->count, 10;
};

{
    $book->delete->execute;
    my $session = $mapper->begin_session( autocommit => 0 );
    is $session->autoflush, 0;

    try {
        $session->txn(
            sub{
                is $session->autoflush, 1;
                $session->add( MyTest18::Books->new( title => 'title' . $_ ) )
                    for 1 .. 5;
                die 'died';
                $session->add( MyTest18::Books->new( title => 'title' . $_ ) )
                    for 6 .. 10;
                $session->commit;
            }
        );
    };

    is $session->autoflush, 0;
    is $session->search('MyTest18::Books')->count, 0;

    $session->add( MyTest18::Books->new( title => 'title' . $_ ) ) for 6 .. 10;
    $session->commit;
};

{
    my $session = $mapper->begin_session;
    is $session->search('MyTest18::Books')->count, 5;
};

{
    $book->delete->execute;
    my $session1 = $mapper->begin_session( autocommit => 0 );
    $session1->add( MyTest18::Books->new( title => 'title' . $_ ) ) for 1 .. 5;
    $session1->commit;

    my $session2 = $mapper->begin_session( autocommit => 0 );
    $session2->add( MyTest18::Books->new( title => 'title' . $_ ) ) for 6 .. 10;
    $session2->commit;

    $session1->add( MyTest18::Books->new( title => 'title' . $_ ) ) for 11 .. 15;
    $session1->commit;
};

{
    my $session = $mapper->begin_session;
    is $session->search('MyTest18::Books')->count, 15;
};

{
    $book->delete->execute;
    my $session1 = $mapper->begin_session( autocommit => 0 );
    $session1->add( MyTest18::Books->new( title => 'title' . $_ ) ) for 1 .. 5;

    {
        my $session2 = $mapper->begin_session( autocommit => 0 );
        $session2->add(
            MyTest18::Books->new( title => 'title' . $_ ) ) for 6 .. 10;
        $session2->commit;
    };

    $session1->add( MyTest18::Books->new( title => 'title' . $_ ) ) for 11 .. 15;
    $session1->rollback;
};

{
    my $session = $mapper->begin_session;
    is $session->search('MyTest18::Books')->count, 0;
};

{
    $book->delete->execute;
    my $session1 = $mapper->begin_session( autocommit => 0 );
    $session1->add(
        MyTest18::Books->new( id => $_, title => 'title' . $_ ) ) for 1 .. 5;
    $session1->flush;

    eval {
        my $session2 = $mapper->begin_session( autocommit => 0 );
        $session2->add(
            MyTest18::Books->new( id => $_, title => 'title-x-' . $_ )
            ) for 1 .. 5;
        $session2->commit;
    };
    ok $@;
    ok $@ =~ /PRIMARY KEY must be unique/, 'PRIMARY KEY must be unique';

    $session1->add(
        MyTest18::Books->new( id => $_, title => 'title' . $_ ) ) for 11 .. 15;
    $session1->rollback;
};

{
    my $session = $mapper->begin_session;
    is $session->search('MyTest18::Books')->count, 0;
};

{
    $book->delete->execute;
    my $session1 = $mapper->begin_session( autocommit => 0 );
    $session1->add(
        MyTest18::Books->new( id => $_, title => 'title' . $_ ) ) for 1 .. 5;
    $session1->flush;

    my $session2 = $mapper->begin_session( autocommit => 0 );
    eval {
        $session2->add(
            MyTest18::Books->new( id => $_, title => 'title' . $_ )
            ) for 1 .. 5;
        $session2->commit;
    };
    $session2 = undef;
    ok $@;
    ok $@ =~ /PRIMARY KEY must be unique/, 'PRIMARY KEY must be unique';

    $session1->add(
        MyTest18::Books->new( id => $_, title => 'title' . $_ ) ) for 11 .. 15;
    $session1->commit;
};

{
    my $session = $mapper->begin_session;
    is $session->search('MyTest18::Books')->count, 10;
};

# XXX SQLite's bug? BegunWork is still true.
$mapper->engine->disconnect;


{
    my $session = $mapper->begin_session( autocommit => 0 );
    $session->add( MyTest18::Books->new( title => 'title', id => 1 ) );
    $session->commit;
    my $book = $session->get( 'MyTest18::Books' => 1 );
    $session->rollback;
    $book->title( 'title title' );
    $session->commit;
};


{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $book = $session->get( 'MyTest18::Books' => 1 );
    is $book->title, 'title title';
    $session->rollback;
    $book->title('title');
    # rollback
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $book = $session->get( 'MyTest18::Books' => 1 );
    is $book->title, 'title title';
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $book = $session->get( 'MyTest18::Books' => 1 );
    $session->delete($book);
    $session->add( MyTest18::Books->new( title => 't', id => 1 ) );
    $session->commit;
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $book = $session->get( 'MyTest18::Books' => 1 );
    is $book->title, 't';
};

done_testing;
