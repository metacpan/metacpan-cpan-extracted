use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIx::ObjectMapper::Engine;
use DBIx::ObjectMapper::Engine::DBI;
use DBIx::ObjectMapper::Session::Cache;

ok my $engine = DBIx::ObjectMapper::Engine::DBI->new(
    [
        'DBI:SQLite:',
        undef,
        undef,
        {
            on_connect_do => [
                q{CREATE TABLE test1 (id integer primary key, name text)},
            ],
            cache => DBIx::ObjectMapper::Session::Cache->new,
        },
    ],
);

ok $engine->cache;

$engine->insert(
    $engine->query->insert->into('test1')->values( name => 'name' . $_ )
) for 1 .. 10;

{
    my $single = $engine->select_single(
        $engine->query->select->from('test1')->where([ id => 1 ])
    );

    # cache hit
    $engine->select_single(
        $engine->query->select->from('test1')->where([ id => 1 ])
    );

    is $engine->{sql_cnt}, 12;
};

sub get_it {
    my $it_class = shift;
    my $it = $engine->select(
        $engine->query->select->from('test1')->order_by('id')
    );

    my $loop_cnt = 0;
    is ref $it, $it_class;
    while( my $t = $it->next ) {
        $loop_cnt++;
    }
    is $loop_cnt, 10;
}

{
    get_it('DBIx::ObjectMapper::Engine::DBI::Iterator');
    get_it('DBIx::ObjectMapper::Iterator') for 1 .. 3;
    is $engine->{sql_cnt}, 13;
    $engine->{cache} = DBIx::ObjectMapper::Session::Cache->new;
};

{
    my $it = $engine->select(
        $engine->query->select->from('test1')->order_by('id')
    );
    $it->next for 0 .. 3;
};
{
    get_it('DBIx::ObjectMapper::Iterator');
    is $engine->{sql_cnt}, 14;
    $engine->{cache} = DBIx::ObjectMapper::Session::Cache->new;
};

{
    my $it = $engine->select(
        $engine->query->select->from('test1')->order_by('id')
    );
    ok @$it;

    get_it('DBIx::ObjectMapper::Iterator');
    is $engine->{sql_cnt}, 15;
    $engine->{cache} = DBIx::ObjectMapper::Session::Cache->new;
};

done_testing;
