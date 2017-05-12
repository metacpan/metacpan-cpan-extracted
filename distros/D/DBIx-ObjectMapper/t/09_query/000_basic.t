use strict;
use warnings;
use Test::More;
use Test::Exception;

use Scalar::Util qw(blessed);
use DBIx::ObjectMapper::Engine::DBI;
BEGIN { use_ok('DBIx::ObjectMapper::Query') }

my $engine = DBIx::ObjectMapper::Engine::DBI->new({
    dsn => 'DBI:SQLite:',
    username => '',
    password => '',
    on_connect_do => [
        q{CREATE TABLE artist (id integer primary key, name text)},
        q{INSERT INTO artist (name) VALUES('artist1')},
        q{INSERT INTO artist (name) VALUES('artist2')},
        q{INSERT INTO artist (name) VALUES('artist3')},
        q{INSERT INTO artist (name) VALUES('artist4')},
        q{INSERT INTO artist (name) VALUES('artist5')},
    ],
});

my $query = DBIx::ObjectMapper::Query->new($engine);
ok blessed($query->select);
is ref($query->select), 'DBIx::ObjectMapper::Query::Select';
ok blessed($query->update);
is ref($query->update), 'DBIx::ObjectMapper::Query::Update';
ok blessed($query->delete);
is ref($query->delete), 'DBIx::ObjectMapper::Query::Delete';
ok blessed($query->insert);
is ref($query->insert), 'DBIx::ObjectMapper::Query::Insert';

{ # select
    my @artists = @{$query->select->from('artist')->order_by('id')->execute};
    for my $i ( 0 .. $#artists ) {
        is $artists[$i]->[0], $i+1;
        is $artists[$i]->[1], 'artist' . ($i+1);
    }
};

{ # insert
    ok my $a1
        = $query->insert->into('artist')->values( name => 'add1' )->execute();
    ok my $a2
        = $query->insert->into('artist')->values( name => 'add2' )->execute(['id']);
    ok $a2->{id};

    dies_ok {
        $query->insert->into('artist')->values( hoge => 'hoge' )->execute;
    };
};

{ # select with callback
    my $it = $query->select(
        sub { { id => $_[0]->[0], name => $_[0]->[1] } }
    )->from('artist')->order_by('id')->execute();

    while( my $ref = $it->next ) {
        ok $ref->{name};
        ok $ref->{id};
    }

};

{ # pager
    my $query = $query->select->from('artist')->limit(1)->order_by('id');
    my $pager = $query->pager;
    is ref($pager), 'Data::Page';
    is $pager->total_entries, 7;
    is $pager->entries_per_page, 1;
    is $pager->current_page, 1;
    is $pager->first_page, 1;
    is $pager->last_page, 7;
    my $it = $query->execute;
    while( my $a = $it->next ) {
        is $a->[0], 1;
    }

    my $pager2 = $query->pager(2);
    my $it2 = $query->execute;
    is $pager2->current_page, 2;
    is $it2->next->[0], 2;

};

{ # update
    ok $query->update->table('artist')->where( [ id => 1 ] )
        ->set( name => 'artist1-1' )->execute;

    my $it = $query->select->from('artist')->where( [ id => 1 ] )->limit(1)
        ->execute;
    my $result = $it->next;
    is $result->[1], 'artist1-1';
};

{ # delete
    $query->delete->table('artist')->where( [ id => 1 ])->execute;
    my $it = $query->select->from('artist')->where( [ id => 1 ] )->limit(1)
        ->execute;
    is $it->size, 0;
    ok !$it->next;
};

done_testing();
