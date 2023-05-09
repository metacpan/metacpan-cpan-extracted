#!perl

use v5.14;
use warnings;

use lib 't/lib';

use Test::Roo;

with 'Test::TableSample::Role';

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => 5,
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE(5)},
};

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => \ '5 percent',
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE(5 PERCENT)},
};

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => \ '100 rows',
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE(100 ROWS)},
};

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => {
            fraction => 0.5,
            type     => 'system',
        },
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE SYSTEM (0.5)},
};

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => {
            fraction => 0.5,
            method   => 'system',
        },
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE SYSTEM (0.5)},
};

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => {
            method  => 'bernoulli',
            fraction => 0.5,
        },
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE BERNOULLI (0.5)},
};

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => {
            type     => 'bernoulli',
            fraction => 0.5,
        },
        rows => 100,
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE BERNOULLI (0.5) LIMIT ?},
    bind => [ [ { sqlt_datatype => 'integer' }, 100 ] ],
};

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => {
            fraction   => '20',
            repeatable => '1234',
        },
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE(20) REPEATABLE (1234)},
};

run_me {
    table_class => 'Artist',
    attr => {
        columns => [qw/ id /],
        tablesample => {
            fraction   => \ '20',
            repeatable => \ '1234',
        },
    },
    sql => q{SELECT me.id FROM artist me TABLESAMPLE(20) REPEATABLE (1234)},
};

done_testing;
