use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Engine::DBI;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );

my $mapper = DBIx::ObjectMapper->new(
    engine => DBIx::ObjectMapper::Engine::DBI->new({
        dsn => 'DBI:SQLite:',
        username => '',
        password => '',
        on_connect_do => [
            q{CREATE TABLE artist( id integer primary key, name text )},
        ],
    }),
);

my $artist = $mapper->metadata->table( artist => 'autoload' );
$mapper->metadata
    ->t('artist')
    ->insert
    ->values( name => 'Led Zeppelin' )
    ->execute();

$mapper->maps(
    $artist => 'MyTest11::Artist',
    constructor => { auto => 1 },
    accessors => { auto => 1 },
);

{
    my $session = $mapper->begin_session;
    my @artists;
    ok my $artist = $session->get( 'MyTest11::Artist' => 1 );
    push @artists, $artist;
    is $artist->__mapper__->status, 'persistent';

    ok my $artist2 = $session->get( 'MyTest11::Artist' => { id => 1 } );
    push @artists, $artist2;
    is $artist2->__mapper__->status, 'persistent';

    for my $a ( @artists ) {
        is ref $a, 'MyTest11::Artist';
        is $a->name, 'Led Zeppelin';
        is $a->id, 1;
    }

    ok $artist->name('レッドツェッペリン');
    ok $artist->__mapper__->is_modified;
    is $artist->name, 'レッドツェッペリン';
};

{
    my $session = $mapper->begin_session;
    ok my $artist = $session->get( 'MyTest11::Artist' => 1 );
    is $artist->name, 'レッドツェッペリン';
    is $artist->__mapper__->status, 'persistent';
};

{
    my $session = $mapper->begin_session;
    my $obj = MyTest11::Artist->new( name => 'Jimi Hendrix' );
    is $obj->__mapper__->status, 'transient';
    ok $session->add($obj);
    is $obj->__mapper__->status, 'pending';
    $session->flush;
    is $obj->__mapper__->status, 'expired';
    is $obj->name, 'Jimi Hendrix';
    is $obj->id, 2;
    is $obj->__mapper__->status, 'persistent';
    $obj->name('じみへん');
    $session->flush();
    is $obj->__mapper__->status, 'expired';
    my $name = $obj->name;
    is $obj->__mapper__->status, 'persistent';
    $obj->name('jimihen');
};

{
    my $session = $mapper->begin_session;
    ok my $artist = $session->get( 'MyTest11::Artist' => 2 );
    is $artist->id, 2;
    is $artist->name, 'jimihen';
    is $artist->__mapper__->status, 'persistent';
    $session->detach($artist);
    is $artist->__mapper__->status, 'detached';
};

{
    my $session = $mapper->begin_session;
    ok my $artist = $session->get( 'MyTest11::Artist' => 2 );
    $artist->id(3);
    $session->flush;

    ok my $artist3 = $session->get( 'MyTest11::Artist' => 3 );
    is $artist3->name, 'jimihen';
    ok $session->delete($artist3);
    is $artist3->__mapper__->status, 'persistent';
    $session->flush;
    is $artist3->__mapper__->status, 'detached';
};

{ # get on flash
    my $session = $mapper->begin_session;
    $mapper->metadata->t('artist')->delete->execute();
    my $artist  = MyTest11::Artist->new( name => 'Cream' );
    $session->add($artist);
    is $artist->__mapper__->status, 'pending';
    ok my $artist2 = $session->get( 'MyTest11::Artist' => 1 );
    is $artist->__mapper__->status, 'expired';
    is $artist->id, $artist2->id;
    is $artist->name, $artist2->name;
};

{ # add_all
    my $session = $mapper->begin_session;
    $mapper->metadata->t('artist')->delete->execute();
    my @obj = $session->add_all(
        map { MyTest11::Artist->new( name => $_ ) } qw(a b c d e f g)
    );
    is $_->__mapper__->status, 'pending' for @obj;
    $session->flush;
    is $_->__mapper__->status, 'expired' for @obj;
    is $mapper->metadata->t('artist')->count->execute(), 7;
};

{ # auto flush
    my $session = $mapper->begin_session( autoflush => 1 );
    $mapper->metadata->t('artist')->delete->execute();
    my $obj = $session->add( MyTest11::Artist->new( name => 'foo' ) );
    is $obj->__mapper__->status, 'expired';
};

{ # auto commit=false
    $mapper->metadata->t('artist')->delete->execute();
    my $session = $mapper->begin_session( autocommit => 0 );
    my @obj = $session->add_all(
        map { MyTest11::Artist->new( name => $_ ) } qw(a b c d e f)
    );

    ok my $artist = $session->get( 'MyTest11::Artist' => 1 );
    is $artist->id, 1;
    is $artist->name, 'a';
    $session->rollback;
};

{ # auto commit=false check
    my $session = $mapper->begin_session( autocommit => 0 );
    ok !$session->get( 'MyTest11::Artist' => 1 );
};

{ # partial transaction
    $mapper->metadata->t('artist')->delete->execute();
    my $session = $mapper->begin_session( autoflush => 1 );
    $session->add( MyTest11::Artist->new( name => 'hoge' ) );
    eval {
        $session->txn(
            sub {
                my @obj = $session->add_all(
                    map { MyTest11::Artist->new( name => $_ ) } qw(a b c d e f)
                );
                die "died";
            },
        );
    };
    ok $@;
    $session->add( MyTest11::Artist->new( name => 'fuga' ) );
    is $mapper->metadata->t('artist')->count->execute(), 2;
};

{ # another scope
    my $stash = +{};
    {
        my $session = $mapper->begin_session();
        $stash->{artist} = $session->get( 'MyTest11::Artist' => 1 );
        is $stash->{artist}->__mapper__->status, 'persistent';
    };

    is $stash->{artist}->__mapper__->status, 'transient'; # recreate
    is $stash->{artist}->name, 'hoge';
    is $stash->{artist}->id, 1;
    ok $stash->{artist}->name('fuga');
};

{ # check
    my $session = $mapper->begin_session();
    my $artist = $session->get( 'MyTest11::Artist' => 1 );
    is $artist->name, 'hoge';
    is $artist->id, 1;
};

done_testing;
__END__
