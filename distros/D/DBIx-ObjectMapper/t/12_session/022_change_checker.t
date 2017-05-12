use strict;
use warnings;
use Test::More;

use DateTime;
use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper::Metadata::Sugar qw(:all);


my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    on_connect_do => [
        q{
CREATE TABLE test_types (
  id INTEGER PRIMARY KEY,
  created DATETIME,
  storable TEXT,
  yaml TEXT,
  uri  TEXT
)
},
    ]
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
my $table = $mapper->metadata->table(
    test_types => [
        Col( storable => Mush() ),
        Col( yaml => Yaml() ),
        Col( uri => Uri() ),
    ],
    { 'autoload' => 1 },
);

my $now = DateTime->now;

$table->insert(
    created => $now,
    storable => { a => 1, b => 2, c => 3 },
    yaml => [ qw(perl python ruby)],
    uri => URI->new('http://example.com/path/to/index.html?a=1&b=2'),
)->execute;

$mapper->maps(
    $table => 'MyTest22::ChangeChecker',
    accessors => { auto => 1 },
    constructor => { auto => 1 },
);

{
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    $session->flush; ## not execute
    is $session->uow->{query_cnt}, 1;
};


{
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    push @{$d->yaml}, 'lisp';
    ok $d->__mapper__->unit_of_work->change_checker->is_changed($d->yaml);
};

{ # check
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    is_deeply $d->yaml, [qw(perl python ruby lisp)];
};

{
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    $d->storable->{d} = 4;
    ok $d->__mapper__->unit_of_work->change_checker->is_changed($d->storable);
};

{ # check
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    is_deeply $d->storable, { a => 1, b => 2, c => 3, d => 4 };
};

{
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    $d->uri->query_form( c => 3, d => 4 );
    $d->uri->path('foo/bar/hoge.html');
    $d->uri->host('example2.com');
    ok $d->__mapper__->unit_of_work->change_checker->is_changed($d->uri);
};

{ # check
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    is $d->uri, 'http://example2.com/foo/bar/hoge.html?c=3&d=4';
};

{
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    $d->created->add( days => 1 );
    ok $d->__mapper__->unit_of_work->change_checker->is_changed($d->created);
};

{ # check
    my $session = $mapper->begin_session;
    ok my $d = $session->get( 'MyTest22::ChangeChecker' => 1 );
    my $check = $now->clone;
    $check->add( days => 1 );
    is $d->created, $check;
};

{ # reflesh
    my $session = $mapper->begin_session( autocommit => 0 );
    my $d = MyTest22::ChangeChecker->new({
        created => $now,
        storable => { a => 1, b => 2, c => 3 },
        yaml => [ qw(perl python ruby)],
        uri => URI->new('http://example.com/path/to/index.html?a=1&b=2'),
    });

    $session->add($d);
    $session->flush;
    ok !$d->__mapper__->is_modified;
    $d->created;
    ok !$d->__mapper__->is_modified;

    $d->storable({ c => 1 });

    ok $d->__mapper__->is_modified;
};

done_testing;
