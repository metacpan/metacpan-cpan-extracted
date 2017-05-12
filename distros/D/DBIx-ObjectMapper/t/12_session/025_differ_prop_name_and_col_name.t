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
            q{CREATE TABLE artist( id integer primary key, name text, gender integer )},
        ],
    }),
);

my $artist = $mapper->metadata->table( artist => 'autoload' );
$mapper->metadata
    ->t('artist')
    ->insert
    ->values( name => 'Led Zeppelin', gender => 1 )
    ->execute();


{
    package MyTest25::Artist;
    use strict;
    use warnings;

    sub new {
        my ( $class, $attr ) = @_;
        bless $attr, $class;
    }

    my $class = __PACKAGE__;
    for my $meth ( qw(code namae seibetu)) {
        no strict 'refs';
        *{"$class\::$meth"} = sub {
            my $self = shift;
            $self->{$meth} = shift if @_;
            return $self->{$meth};
        };
    }

    1;
};

$mapper->maps(
    $artist => 'MyTest25::Artist',
    attributes => {
        properties => {
            code => { isa => $artist->c('id') },
            namae => { isa => $artist->c('name') },
            seibetu => { isa => $artist->c('gender') },
        }
    }
);

{
    my $session = $mapper->begin_session;
    my $a = $session->get( 'MyTest25::Artist' => 1 );
    is $a->code, 1;
    is $a->namae, 'Led Zeppelin';
    is $a->seibetu, 1;
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $jimi = MyTest25::Artist->new({
        code => 2,
        namae => 'Jimi Hendrix',
        seibetu => 1,
    });
    ok $session->add($jimi);
    ok $session->commit;
};

{
    my $session = $mapper->begin_session( autocommit => 0 );
    my $a = $session->get( 'MyTest25::Artist' => 2 );
    is $a->code, 2;
    is $a->namae, 'Jimi Hendrix';
    is $a->seibetu, 1;

    $a->seibetu(0);
    ok $session->commit;
};

done_testing;
