use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper;
use DBIx::ObjectMapper::Session::Cache;
use DBIx::ObjectMapper::Engine::DBI;

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
my @names = qw(a b c d e f g);
$artist->insert->values({ name => $_ })->execute for @names;

$mapper->maps(
    $artist => 'MyTest11::Artist',
    constructor => { auto => 1 },
    accessors => { auto => 1 },
);

{ # all
    my $session = $mapper->begin_session( cache => DBIx::ObjectMapper::Session::Cache->new );
    my $attr = $mapper->attribute('MyTest11::Artist');
    my $query
        = $session->search('MyTest11::Artist')->order_by( $attr->p('id') );
    my $it = $query->execute();
    my $count = 0;
    while( my $a = $it->next ) {
        is ref($a), 'MyTest11::Artist';
        is $a->id, ++$count;
        is $a->name, $names[$count - 1];
    }
    is $count, 7;
    is $query->count, 7;
};

{ # where
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');
    my $artist = $session->search('MyTest11::Artist')
        ->filter( $attr->p('name')->like('%a%') )->first;
    is $artist->id, 1;
    is $artist->name, 'a';
};

{ # limit/offset
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');
    my $it      = $session->search('MyTest11::Artist')
        ->order_by( $attr->p('id')->desc )->limit(2)->offset(2)->execute;

    my $loop_cnt = 0;
    my $id = 5;
    while( my $a = $it->next ) {
        is $a->id, $id--;
        $loop_cnt++;
    }
    is $loop_cnt, 2;
};

{ # pager
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');
    my $query   = $session->search('MyTest11::Artist')
        ->order_by( $attr->p('id') )->limit(2);
    my ( $it, $pager ) = $query->page(1);
    is ref($pager), 'Data::Page';
    is $pager->current_page, 1;
    is $pager->total_entries, 7;
    my $loop_cnt = 0;
    while( my $a = $it->next ) {
        is $a->id, ++$loop_cnt;
    }
    is $loop_cnt, 2;
};

{ # first/count
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');
    my $query   = $session->search('MyTest11::Artist')
        ->order_by( $attr->p('id') );
    my $a = $query->first;
    is $a->id, 1;
    is $query->count, 7;
};

{ # or search
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');
    ok my $it = $session->search('MyTest11::Artist')
        ->filter( { or => [ $attr->p('id') == 1, $attr->p('id') == 2 ] })
        ->execute;
    is scalar(@$it), 2;

    ok my $it2 = $session->search('MyTest11::Artist')->filter(
        {
            or => [ $attr->p('id') == 1, $attr->p('id') == 2 ],
        },
        {
            and => [ $attr->p('name')->like('_') ],
        },
    )->execute;
    is scalar(@$it2), 2;

    ok my $it3 = $session->search('MyTest11::Artist')->filter(
        {
            or => [ $attr->p('id') == 1, $attr->p('id') == 2 ],
        },
        $attr->p('name')->like('_'),
    )->execute;
    is scalar(@$it3), 2;
};

{ # scalar search
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');
    ok my $it = $session->search('MyTest11::Artist')
        ->filter( \'id = 2' )
        ->execute;
    is scalar(@$it), 1;
    is $it->[0]->id, 2;
};



done_testing;
__END__
