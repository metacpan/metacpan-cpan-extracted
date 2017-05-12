use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    on_connect_do => [
        q{CREATE TABLE fuga (id INTEGER NOT NULL PRIMARY KEY, t text)},
        q{CREATE TABLE hoge (id INTEGER NOT NULL PRIMARY KEY, type VARCHAR(1) NOT NULL, name TEXT, fuga_id INTEGER REFERENCES fuga(id) ) },

    ],
});

my $mapper = DBIx::ObjectMapper->new( engine => $engine );
my $hoge = $mapper->metadata->table( 'hoge' => 'autoload' );
my $fuga = $mapper->metadata->table( 'fuga' => 'autoload' );

$mapper->maps(
    $hoge => 'MyHoge',
    constructor => { auto => 1 },
    accessors => { auto => 1 },
    polymorphic_on => 'type',
    default_condition => [ $hoge->c('type') != 'Z' ],
    attributes => {
        properties => {
            'fuga' => {
                isa => $mapper->relation(
                    belongs_to => 'MyFuga',
                )
            }
        }
    }
);

$mapper->maps(
    $hoge => 'MyHoge::A',
    inherits => 'MyHoge',
    polymorphic_identity => 'A',
);

$mapper->maps(
    $hoge => 'MyHoge::B',
    inherits => 'MyHoge',
    polymorphic_identity => 'B',
);

$mapper->maps(
    $fuga => 'MyFuga',
    constructor => { auto => 1 },
    accessors => { auto => 1 },
    attributes => {
        properties => {
            hoge => {
                isa => $mapper->relation(
                    has_many => 'MyHoge',
                ),
            },
            hoge_a => {
                isa => $mapper->relation(
                    has_many => 'MyHoge::A',
                ),
            },
            hoge_b => {
                isa => $mapper->relation(
                    has_many => 'MyHoge::B',
                ),
            }
        },
    }
);

my $session = $mapper->begin_session( autocommit => 0 );
my $fuga1 =  MyFuga->new( t => 'abc' );
$session->add($fuga1);

$session->add_all(
    ( map{ MyHoge->new( type => 'A', name => 'A-' . $_, fuga_id => 1 ) } ( 1 .. 3 ) ),
    ( map{ MyHoge->new( type => 'B', name => 'B-' . $_, fuga_id => 1  ) } ( 1 .. 5 ) ),
    ( map{ MyHoge->new( type => 'C', name => 'C-' . $_, fuga_id => 1  ) } ( 1 .. 1 ) ),
    ( map{ MyHoge->new( type => 'Z', name => 'Z-' . $_, fuga_id => 1  ) } ( 1 .. 3 ) ),
);

$session->commit;
$session = $mapper->begin_session( autocommit => 0 );

my $f = $session->get(
    'MyFuga' => 1,
    { eagerload => [ 'hoge', 'hoge_a', 'hoge_b' ] }
);

ok my $hoges = $f->hoge;
ok( !grep{ $_->type eq 'Z' } @$hoges );
is( scalar(@$hoges), 3 + 5 + 1 );

my $hoge_a = $f->hoge_a;
ok( !grep{ $_->type ne 'A' } @$hoge_a );
is( scalar(@$hoge_a), 3);

my $hoge_b = $f->hoge_b;
ok( !grep{ $_->type ne 'B' } @$hoge_b );
is( scalar(@$hoge_b), 5);

done_testing;

