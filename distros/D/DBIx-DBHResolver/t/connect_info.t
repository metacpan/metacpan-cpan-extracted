use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIx::DBHResolver;
use DBIx::DBHResolver::Strategy::RoundRobin;

our $TEST_CONFIG = +{
    connect_info => +{
        LOCAL => +{
            dsn      => 'dbi:mysql:dbname=test;host=localhost',
            user     => 'root',
            password => "",
        },
        MASTER1 => +{
            dsn      => 'dbi:mysql:dbname=test;host=master1',
            user     => 'root',
            password => "",
        },
        MASTER2 => +{
            dsn      => 'dbi:mysql:dbname=test;host=master2',
            user     => 'root',
            password => "",
        },
        SLAVE1 => +{
            dsn      => 'dbi:mysql:dbname=test;host=slave1',
            user     => 'root',
            password => "",
        },
        SLAVE2 => +{
            dsn      => 'dbi:mysql:dbname=test;host=slave2',
            user     => 'root',
            password => "",
        },
        SLAVE3 => +{
            dsn      => 'dbi:mysql:dbname=test;host=slave3',
            user     => 'root',
            password => "",
        },
        SLAVE4 => +{
            dsn      => 'dbi:mysql:dbname=test;host=slave4',
            user     => 'root',
            password => "",
        },
        SLAVE5 => +{
            dsn      => 'dbi:mysql:dbname=test;host=slave5',
            user     => 'root',
            password => "",
        },
        SLAVE6 => +{
            dsn      => 'dbi:mysql:dbname=test;host=slave6',
            user     => 'root',
            password => "",
        },
        ALIAS1 => 'SLAVE1',
        ALIAS2 => 'SLAVE2',
        ALIAS3 => 'SLAVE3',
        ALIAS4 => 'SLAVE4',
        ALIAS5 => 'SLAVE5',
        ALIAS6 => 'SLAVE6',
    },
    clusters => +{
        MASTER         => [qw(MASTER1 MASTER2)],
        SLAVE          => [qw(SLAVE1 SLAVE2 SLAVE3)],
        MASTER_CLUSTER => +{
            strategy => 'Key',
            nodes    => [qw(MASTER1 MASTER2)]
        },
        SLAVE_CLUSTER1 => +{
            strategy => 'Key',
            nodes    => [qw(SLAVE1 SLAVE2)]
        },
        SLAVE_CLUSTER2 => +{
            strategy => 'Key',
            nodes    => [qw(SLAVE3 SLAVE4)]
        },
        SLAVE_CLUSTER3 => +{
            strategy => 'Key',
            nodes    => [qw(SLAVE5 SLAVE6)]
        },
        SLAVE_CLUSTER4 => +{
            strategy => 'Key',
            nodes    => [qw(SLAVE1 SLAVE2 SLAVE3)]
        },
        SLAVE_CLUSTER => +{
            strategy => 'Key',
            nodes    => [qw(SLAVE_CLUSTER1 SLAVE_CLUSTER2 SLAVE_CLUSTER3)]
        },
        SLAVE_LIST_CLUSTER => +{
            strategy        => 'List',
            nodes           => [qw(SLAVE1 SLAVE3 SLAVE5)],
            strategy_config => +{
                SLAVE1 => [ 1, 4 ],
                SLAVE3 => [ 2, 3, 6 ],
                SLAVE5 => [5],
            },
        },
        SLAVE_FALLBACK_LIST_CLUSTER => +{
            strategy        => 'List',
            nodes           => [qw(SLAVE1 SLAVE3 SLAVE5)],
            strategy_config => +{
                SLAVE1 => [ 1, 4 ],
                SLAVE3 => [ 2, 3, 6 ],
                SLAVE5 => [5],
                ""     => "SLAVE4"
            },
        },
        ALIAS_LIST_CLUSTER => +{
            strategy => 'List',
            nodes    => [qw(ALIAS_CLUSTER1 ALIAS_CLUSTER2 ALIAS_CLUSTER3)],
            strategy_config => +{
                ALIAS_CLUSTER1 => [ 1, 5 ],
                ALIAS_CLUSTER2 => [ 2, 7 ],
                ALIAS_CLUSTER3 => [ 3, 4, 6 ],
            },
        },
        SLAVE_CLUSTER_FALLBACK_LIST_CLUSTER => +{
            strategy => 'List',
            nodes    => [qw(SLAVE1 SLAVE2 SLAVE3 SLAVE4 SLAVE5)],
            strategy_config => +{
                SLAVE4         => [ 3, 5, ],
                SLAVE5         => [ 1, 6, ],
                ""             => 'SLAVE_CLUSTER4',
            },
        },
        ALIAS_CLUSTER1 => +{
            strategy => 'Key',
            nodes    => [qw(ALIAS1 ALIAS2)]
        },
        ALIAS_CLUSTER2 => +{
            strategy => 'Key',
            nodes    => [qw(ALIAS3 ALIAS4)]
        },
        ALIAS_CLUSTER3 => +{
            strategy => 'Key',
            nodes    => [qw(ALIAS5 ALIAS6)]
        },
        ALIAS_CLUSTER => +{
            strategy => 'Key',
            nodes    => [qw(ALIAS_CLUSTER1 ALIAS_CLUSTER2 ALIAS_CLUSTER3)]
        },
        RANGE_CLUSTER => +{
            strategy        => 'Range',
            nodes           => [qw(SLAVE1 SLAVE2 SLAVE3 SLAVE4 SLAVE5 SLAVE6)],
            strategy_config => [
                SLAVE1 => [ '<',  10 ],
                SLAVE2 => [ '>=', 10, '<' => 20, ],
                SLAVE3 => [ '>=', 20, '<' => 30, ],
                SLAVE4 => [ '>=', 30, '<' => 40, ],
                SLAVE5 => [ '>=', 40, '<' => 50, ],
                SLAVE6 => [ '>=', 50, ],
            ],
        },
        ROUND_ROBIN_CLUSTER => +{
            strategy => 'RoundRobin',
            nodes    => [qw(SLAVE1 SLAVE2 SLAVE3 SLAVE4 SLAVE5 SLAVE6)],
        },
    },
};

sub test_connect_info {
    my %specs = @_;
    my ( $desc, $resolver, $node, $node_args, $expects, $is_lives ) =
      @specs{qw/desc resolver node node_args expects is_lives/};

    subtest $desc => sub {
        $is_lives = 1 unless defined $is_lives;

        my $conn_info;
        if ($is_lives) {
            lives_ok {
                $conn_info = $resolver->connect_info( $node, $node_args );
            }
            'connect_info lives ok';
            is_deeply( $conn_info, $expects, $desc );
        }
        else {
            dies_ok {
                $conn_info = $resolver->connect_info( $node, $node_args );
            }
            'connect_info dies ok';
        }
        done_testing;
    };
}

sub run_all_tests {
    my $resolver = shift;

    subtest 'single node' => sub {
        test_connect_info(
            desc     => 'single node',
            resolver => $resolver,
            node     => 'LOCAL',
            expects  => $TEST_CONFIG->{connect_info}{LOCAL},
        );
    };

    subtest 'key strategy' => sub {
        test_connect_info(
            desc      => 'using key strategy (nodes: 2, key: 6)',
            resolver  => $resolver,
            node      => 'MASTER',
            node_args => +{ strategy => 'Key', key => 6, },
            expects   => $TEST_CONFIG->{connect_info}{MASTER1},
        );

        test_connect_info(
            desc      => 'using key strategy (nodes: 2, key: 7)',
            resolver  => $resolver,
            node      => 'MASTER',
            node_args => +{ strategy => 'Key', key => 7, },
            expects   => $TEST_CONFIG->{connect_info}{MASTER2},
        );

        test_connect_info(
            desc => 'using key strategy with scalar args (nodes: 2, key: 6)',
            resolver  => $resolver,
            node      => 'MASTER',
            node_args => 6,
            expects   => $TEST_CONFIG->{connect_info}{MASTER1},
        );

        test_connect_info(
            desc => 'using key strategy with scalar args (nodes: 2, key: 7)',
            resolver  => $resolver,
            node      => 'MASTER',
            node_args => 7,
            expects   => $TEST_CONFIG->{connect_info}{MASTER2},
        );

        test_connect_info(
            desc => 'using key strategy with array ref args (nodes: 2, key: 6)',
            resolver  => $resolver,
            node      => 'MASTER',
            node_args => [6],
            expects   => $TEST_CONFIG->{connect_info}{MASTER1},
        );

        test_connect_info(
            desc => 'using key strategy with array ref args (nodes: 2, key: 7)',
            resolver  => $resolver,
            node      => 'MASTER',
            node_args => [7],
            expects   => $TEST_CONFIG->{connect_info}{MASTER2},
        );

        test_connect_info(
            desc      => 'using key strategy (nodes:3, key: 6)',
            resolver  => $resolver,
            node      => 'SLAVE',
            node_args => +{ strategy => 'Key', key => 6, },
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'using key strategy (nodes:3, key: 7)',
            resolver  => $resolver,
            node      => 'SLAVE',
            node_args => +{ strategy => 'Key', key => 7, },
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc      => 'using key strategy (nodes:3, key: 8)',
            resolver  => $resolver,
            node      => 'SLAVE',
            node_args => +{ strategy => 'Key', key => 8, },
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );
    };

    subtest 'alias' => sub {
        test_connect_info(
            desc     => 'alias node 1',
            resolver => $resolver,
            node     => 'ALIAS1',
            expects  => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc     => 'alias node 2',
            resolver => $resolver,
            node     => 'ALIAS2',
            expects  => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc     => 'alias node 3',
            resolver => $resolver,
            node     => 'ALIAS3',
            expects  => $TEST_CONFIG->{connect_info}{SLAVE3},
        );
    };

    subtest 'using config with scalar key' => sub {
        test_connect_info(
            desc     => 'using config with scalar key (MASTER_CLUSTER, key: 8)',
            resolver => $resolver,
            node     => 'MASTER_CLUSTER',
            node_args => 8,
            expects   => $TEST_CONFIG->{connect_info}{MASTER1},
        );

        test_connect_info(
            desc     => 'using config with scalar key (MASTER_CLUSTER, key: 9)',
            resolver => $resolver,
            node     => 'MASTER_CLUSTER',
            node_args => 9,
            expects   => $TEST_CONFIG->{connect_info}{MASTER2},
        );

        test_connect_info(
            desc => 'using config with array ref key (MASTER_CLUSTER, key: 8)',
            resolver  => $resolver,
            node      => 'MASTER_CLUSTER',
            node_args => [8],
            expects   => $TEST_CONFIG->{connect_info}{MASTER1},
        );

        test_connect_info(
            desc => 'using config with array ref key (MASTER_CLUSTER, key: 9)',
            resolver  => $resolver,
            node      => 'MASTER_CLUSTER',
            node_args => [9],
            expects   => $TEST_CONFIG->{connect_info}{MASTER2},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (SLAVE_CLUSTER, key: [ 3, 10 ])',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER',
            node_args => [ 3, 10 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (SLAVE_CLUSTER, key: [ 3, 11 ])',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER',
            node_args => [ 3, 11 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (SLAVE_CLUSTER, key: [ 4, 10 ])',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER',
            node_args => [ 4, 10 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (SLAVE_CLUSTER, key: [ 4, 11 ])',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER',
            node_args => [ 4, 11 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (SLAVE_CLUSTER, key: [ 5, 10 ])',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER',
            node_args => [ 5, 10 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (SLAVE_CLUSTER, key: [ 5, 11 ])',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER',
            node_args => [ 5, 11 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (ALIAS_CLUSTER, key: [ 3, 10 ])',
            resolver  => $resolver,
            node      => 'ALIAS_CLUSTER',
            node_args => [ 3, 10 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (ALIAS_CLUSTER, key: [ 3, 11 ])',
            resolver  => $resolver,
            node      => 'ALIAS_CLUSTER',
            node_args => [ 3, 11 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (ALIAS_CLUSTER, key: [ 4, 10 ])',
            resolver  => $resolver,
            node      => 'ALIAS_CLUSTER',
            node_args => [ 4, 10 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (ALIAS_CLUSTER, key: [ 4, 11 ])',
            resolver  => $resolver,
            node      => 'ALIAS_CLUSTER',
            node_args => [ 4, 11 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (ALIAS_CLUSTER, key: [ 5, 10 ])',
            resolver  => $resolver,
            node      => 'ALIAS_CLUSTER',
            node_args => [ 5, 10 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc =>
              'using config with array ref key (ALIAS_CLUSTER, key: [ 5, 11 ])',
            resolver  => $resolver,
            node      => 'ALIAS_CLUSTER',
            node_args => [ 5, 11 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );
    };

    subtest 'list strategy' => sub {
        test_connect_info(
            desc      => 'List strategy (key: 1)',
            resolver  => $resolver,
            node      => 'SLAVE_LIST_CLUSTER',
            node_args => 1,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'List strategy (key: 2)',
            resolver  => $resolver,
            node      => 'SLAVE_LIST_CLUSTER',
            node_args => 2,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'List strategy (key: 3)',
            resolver  => $resolver,
            node      => 'SLAVE_LIST_CLUSTER',
            node_args => 3,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'List strategy (key: 4)',
            resolver  => $resolver,
            node      => 'SLAVE_LIST_CLUSTER',
            node_args => 4,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'List strategy (key: 5)',
            resolver  => $resolver,
            node      => 'SLAVE_LIST_CLUSTER',
            node_args => 5,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'List strategy (key: 6)',
            resolver  => $resolver,
            node      => 'SLAVE_LIST_CLUSTER',
            node_args => 6,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );
    };

    subtest 'list strategy with fallback' => sub {
        test_connect_info(
            desc      => 'Fallback List strategy (key: 1)',
            resolver  => $resolver,
            node      => 'SLAVE_FALLBACK_LIST_CLUSTER',
            node_args => 1,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'Fallback List strategy (key: 2)',
            resolver  => $resolver,
            node      => 'SLAVE_FALLBACK_LIST_CLUSTER',
            node_args => 2,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'Fallback List strategy (key: 3)',
            resolver  => $resolver,
            node      => 'SLAVE_FALLBACK_LIST_CLUSTER',
            node_args => 3,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'Fallback List strategy (key: 4)',
            resolver  => $resolver,
            node      => 'SLAVE_FALLBACK_LIST_CLUSTER',
            node_args => 4,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'Fallback List strategy (key: 5)',
            resolver  => $resolver,
            node      => 'SLAVE_FALLBACK_LIST_CLUSTER',
            node_args => 5,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'Fallback List strategy (key: 6)',
            resolver  => $resolver,
            node      => 'SLAVE_FALLBACK_LIST_CLUSTER',
            node_args => 6,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'Fallback List strategy (key: 7)',
            resolver  => $resolver,
            node      => 'SLAVE_FALLBACK_LIST_CLUSTER',
            node_args => 7,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );

        test_connect_info(
            desc      => 'Fallback List strategy (key: 8)',
            resolver  => $resolver,
            node      => 'SLAVE_FALLBACK_LIST_CLUSTER',
            node_args => 8,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );
    };

    subtest 'list and alias' => sub {
        test_connect_info(
            desc      => 'List strategy (key: 1, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 1, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'List strategy (key: 1, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 1, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc      => 'List strategy (key: 2, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 2, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'List strategy (key: 2, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 2, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );

        test_connect_info(
            desc      => 'List strategy (key: 3, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 3, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'List strategy (key: 2, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 3, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );

        test_connect_info(
            desc      => 'List strategy (key: 4, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 4, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'List strategy (key: 4, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 4, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );

        test_connect_info(
            desc      => 'List strategy (key: 5, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 5, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'List strategy (key: 5, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 5, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc      => 'List strategy (key: 6, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 6, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'List strategy (key: 6, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 6, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );

        test_connect_info(
            desc      => 'List strategy (key: 7, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 7, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'List strategy (key: 7, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 7, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );
    };

    subtest 'fallback list and alias' => sub {
        test_connect_info(
            desc      => 'List strategy (key: 1, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 1, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'List strategy (key: 1, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 1, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc      => 'List strategy (key: 2, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 2, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'List strategy (key: 2, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 2, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );

        test_connect_info(
            desc      => 'List strategy (key: 3, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 3, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'List strategy (key: 2, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 3, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );

        test_connect_info(
            desc      => 'List strategy (key: 4, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 4, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'List strategy (key: 4, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 4, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );

        test_connect_info(
            desc      => 'List strategy (key: 5, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 5, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

        test_connect_info(
            desc      => 'List strategy (key: 5, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 5, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc      => 'List strategy (key: 6, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 6, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'List strategy (key: 6, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 6, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );

        test_connect_info(
            desc      => 'List strategy (key: 7, 2)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 7, 2 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'List strategy (key: 7, 3)',
            resolver  => $resolver,
            node      => 'ALIAS_LIST_CLUSTER',
            node_args => [ 7, 3 ],
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );
    };

    subtest 'fallback list and sub strategy' => sub {
        test_connect_info(
            desc      => 'fallback list strategy and sub strategy (key: 3)',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER_FALLBACK_LIST_CLUSTER',
            node_args => 3,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );

        test_connect_info(
            desc      => 'fallback list strategy and sub strategy (key: 5)',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER_FALLBACK_LIST_CLUSTER',
            node_args => 5,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );

        test_connect_info(
            desc      => 'fallback list strategy and sub strategy (key: 1)',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER_FALLBACK_LIST_CLUSTER',
            node_args => 1,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'fallback list strategy and sub strategy (key: 6)',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER_FALLBACK_LIST_CLUSTER',
            node_args => 6,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );

        test_connect_info(
            desc      => 'fallback list strategy and sub strategy (key: 2)',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER_FALLBACK_LIST_CLUSTER',
            node_args => 2,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );

        test_connect_info(
            desc      => 'fallback list strategy and sub strategy (key: 4)',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER_FALLBACK_LIST_CLUSTER',
            node_args => 4,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );

        test_connect_info(
            desc      => 'fallback list strategy and sub strategy (key: 9)',
            resolver  => $resolver,
            node      => 'SLAVE_CLUSTER_FALLBACK_LIST_CLUSTER',
            node_args => 9,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );

    };
    
    for my $seed ( 1 .. 10 ) {
        srand($seed);
        my $expected_index = int( rand(6) );
        my $expected_node =
          $TEST_CONFIG->{clusters}{ROUND_ROBIN_CLUSTER}{nodes}[$expected_index];
        srand($seed);
        test_connect_info(
            desc =>
"RoundRobin strategy (index: $expected_index, node: $expected_node)",
            resolver => $resolver,
            node     => 'ROUND_ROBIN_CLUSTER',
            expects  => $TEST_CONFIG->{connect_info}{$expected_node},
        );
    }

    for my $key ( 0 .. 9 ) {
        test_connect_info(
            desc      => "Range strategy (key: $key)",
            resolver  => $resolver,
            node      => 'RANGE_CLUSTER',
            node_args => $key,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE1},
        );
    }

    for my $key ( 10 .. 19 ) {
        test_connect_info(
            desc      => "Range strategy (key: $key)",
            resolver  => $resolver,
            node      => 'RANGE_CLUSTER',
            node_args => $key,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE2},
        );
    }

    for my $key ( 20 .. 29 ) {
        test_connect_info(
            desc      => "Range strategy (key: $key)",
            resolver  => $resolver,
            node      => 'RANGE_CLUSTER',
            node_args => $key,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE3},
        );
    }

    for my $key ( 30 .. 39 ) {
        test_connect_info(
            desc      => "Range strategy (key: $key)",
            resolver  => $resolver,
            node      => 'RANGE_CLUSTER',
            node_args => $key,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE4},
        );
    }

    for my $key ( 40 .. 49 ) {
        test_connect_info(
            desc      => "Range strategy (key: $key)",
            resolver  => $resolver,
            node      => 'RANGE_CLUSTER',
            node_args => $key,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE5},
        );
    }

    for my $key ( 50 .. 59 ) {
        test_connect_info(
            desc      => "Range strategy (key: $key)",
            resolver  => $resolver,
            node      => 'RANGE_CLUSTER',
            node_args => $key,
            expects   => $TEST_CONFIG->{connect_info}{SLAVE6},
        );
    }
}

subtest 'using connect_info as static class' => sub {
    $DBIx::DBHResolver::CONFIG = +{};
    my $resolver = 'DBIx::DBHResolver';
    $resolver->config($TEST_CONFIG);
    run_all_tests($resolver);
    done_testing;
};

subtest 'using connect_info as static sub class' => sub {
    $DBIx::DBHResolver::CONFIG = +{};

    do {

        package My::Resolver;
        use parent qw(DBIx::DBHResolver);
    };

    my $resolver = 'My::Resolver';
    $resolver->config($TEST_CONFIG);
    run_all_tests($resolver);
    done_testing;
};

subtest
  'using connect_info as static sub class, store config into parent class' =>
  sub {
    $DBIx::DBHResolver::CONFIG = +{};

    do {

        package My::Resolver;
        use parent qw(DBIx::DBHResolver);
    };

    my $resolver = 'My::Resolver';
    DBIx::DBHResolver->config($TEST_CONFIG);
    run_all_tests($resolver);
    done_testing;
  };

subtest 'using connect_info as instance' => sub {
    $DBIx::DBHResolver::CONFIG = +{};
    my $resolver = DBIx::DBHResolver->new;
    $resolver->config($TEST_CONFIG);
    run_all_tests($resolver);
    done_testing;
};

subtest 'using connect_info as instance of sub class' => sub {
    $DBIx::DBHResolver::CONFIG = +{};

    do {

        package My::Resolver2;
        use parent qw(DBIx::DBHResolver);
    };

    my $resolver = My::Resolver2->new;
    $resolver->config($TEST_CONFIG);
    run_all_tests($resolver);
    done_testing;
};

done_testing;
