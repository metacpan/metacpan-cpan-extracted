#!perl

use Test::Most;

use lib 't/lib';

use SQL::Abstract::Test import => [qw/ is_same_sql_bind /];

use Test::Schema;

my $schema = Test::Schema->deploy_or_connect('dbi:SQLite::memory:');

subtest 'simple partition' => sub {

    my $rs = $schema->resultset('Artist')->search_rs(
        undef,
        {
            columns   => [qw/ name /],
            '+select' => {
                rank  => [],
                -as   => 'ranking',
                -over => {
                    partition_by => 'fingers',
                },
            },
        }
    );

    my $me = $rs->current_source_alias;

    is_same_sql_bind(
        $rs->as_query,
"( SELECT ${me}.name, RANK() OVER (PARTITION BY fingers) AS ranking FROM artist ${me} )",
        [],
        'sql+bind'
    );

};

subtest 'simple partition' => sub {

    my $rs = $schema->resultset('Artist')->search_rs(
        undef,
        {
            columns   => [qw/ name /],
            '+select' => {
                row_number => [],
                -over      => {
                    order_by => 'fingers',
                },
            },
        }
    );

    my $me = $rs->current_source_alias;

    is_same_sql_bind(
        $rs->as_query,
"( SELECT ${me}.name, ROW_NUMBER() OVER (ORDER BY fingers) FROM artist ${me} )",
        [],
        'sql+bind'
    );

};

subtest 'simple partition + order by' => sub {

    my $rs = $schema->resultset('Artist')->search_rs(
        undef,
        {
            columns   => [qw/ name /],
            '+select' => {
                avg   => [qw/fingers/],
                -as   => 'ranking',
                -over => {
                    partition_by => 'fingers',
                    order_by     => 'name',
                },
            },
        }
    );

    my $me = $rs->current_source_alias;

    is_same_sql_bind(
        $rs->as_query,
"( SELECT ${me}.name, AVG(fingers) OVER (PARTITION BY fingers ORDER BY name) AS ranking FROM artist ${me} )",
        [],
        'sql+bind'
    );

};

subtest 'multiple partitions + order bys' => sub {

    my $rs = $schema->resultset('Artist')->search_rs(
        undef,
        {
            columns   => [qw/ name /],
            '+select' => {
                sum   => [qw/fingers/],
                -over => {
                    partition_by => [qw/ name hats/],
                    order_by     => [ 'name', { -desc => 'id' } ],
                },
            },
        }
    );

    my $me = $rs->current_source_alias;

    is_same_sql_bind(
        $rs->as_query,
"( SELECT ${me}.name, SUM(fingers) OVER (PARTITION BY name, hats ORDER BY name, id DESC) FROM artist ${me} )",
        [],
        'sql+bind'
    );

};

done_testing;
