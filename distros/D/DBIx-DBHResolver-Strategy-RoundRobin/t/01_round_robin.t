use strict;
use warnings;
use Test::More;
use DBIx::DBHResolver;

DBIx::DBHResolver->config(+{
    connect_info => +{
        MASTER => +{
            dsn      => 'dbi:mysql:dbname=test;host=master',
            user     => 'root',
            password => '',
        },
        SLAVE1 => +{
            dsn      => 'dbi:mysql:dbname=test;host=slave1',
            user     => 'root',
            password => '',
        },
        SLAVE2 => +{
            dsn      => 'dbi:mysql:dbname=test;host=slave2',
            user     => 'root',
            password => '',
        },
    },
    clusters => +{
        SLAVE  => [ qw(SLAVE1  SLAVE2) ],
    },
});

subtest 'RR test' => sub {
    is +DBIx::DBHResolver->connect_info('SLAVE', +{ strategy => 'RoundRobin' }), 'SLAVE1';
    is +DBIx::DBHResolver->connect_info('SLAVE', +{ strategy => 'RoundRobin' }), 'SLAVE2';
    is +DBIx::DBHResolver->connect_info('SLAVE', +{ strategy => 'RoundRobin' }), 'SLAVE1';

    done_testing;
};

subtest 'no cluster' =>sub{
    is_deeply +DBIx::DBHResolver->connect_info('MASTER'), +{
        dsn      => 'dbi:mysql:dbname=test;host=master',
        user     => 'root',
        password => '',
    };

    is_deeply +DBIx::DBHResolver->connect_info('SLAVE1'), +{
        dsn      => 'dbi:mysql:dbname=test;host=slave1',
        user     => 'root',
        password => '',
    };

    done_testing;
};

subtest 'Remainder' => sub{
    is_deeply +DBIx::DBHResolver->connect_info(
        'SLAVE',
        +{ strategy => 'Remainder', key => 1 },
    ), +{
        dsn      => 'dbi:mysql:dbname=test;host=slave1',
        user     => 'root',
        password => '',
    };

    is_deeply +DBIx::DBHResolver->connect_info(
        'SLAVE',
        +{ strategy => 'Remainder', key => 2 },
    ), +{
        dsn      => 'dbi:mysql:dbname=test;host=slave2',
        user     => 'root',
        password => '',
    };
    done_testing;
};

done_testing;

