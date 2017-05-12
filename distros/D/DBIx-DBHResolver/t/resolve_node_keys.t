use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIx::DBHResolver;

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
        ALIAS_LIST_CLUSTER => +{
            strategy => 'List',
            nodes    => [qw(ALIAS_CLUSTER1 ALIAS_CLUSTER2 ALIAS_CLUSTER3)],
            strategy_config => +{
                ALIAS_CLUSTER1 => [ 1, 5 ],
                ALIAS_CLUSTER2 => [ 2, 7 ],
                ALIAS_CLUSTER3 => [ 3, 4, 6 ],
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
    },
};

sub test_resolve_node_keys {
    my %specs = @_;
    my ( $desc, $resolver, $node, $node_args, $keys, $expects, $is_lives ) =
      @specs{qw/desc resolver node node_args keys expects is_lives/};

    subtest $desc => sub {

        $is_lives = 1 unless defined $is_lives;

        my %node_keys;
        if ($is_lives) {
            lives_ok {
                %node_keys =
                  $resolver->resolve_node_keys( $node, $keys, $node_args );
            }
            'resolve_node_keys lives ok';
            is_deeply( \%node_keys, $expects, $desc );
        }
        else {
            dies_ok {
                %node_keys =
                  $resolver->resolve_node_keys( $node, $keys, $node_args );
            }
            'resolve_node_keys dies ok';
        }
        done_testing;
    };
}

sub run_all_tests {
    my $resolver = shift;

    test_resolve_node_keys(
        desc      => 'node',
        resolver  => $resolver,
        node      => 'LOCAL',
        node_args => undef,
        keys      => [ 1 .. 10 ],
        expects   => +{ LOCAL => [ 1 .. 10 ] },
    );

    test_resolve_node_keys(
        desc      => 'alias',
        resolver  => $resolver,
        node      => 'ALIAS1',
        node_args => undef,
        keys      => [ 1 .. 10 ],
        expects   => +{ SLAVE1 => [ 1 .. 10 ] },
    );

    test_resolve_node_keys(
        desc      => 'Key strategy given from args',
        resolver  => $resolver,
        node      => 'MASTER',
        node_args => +{ strategy => 'Key' },
        keys      => [ 1 .. 10 ],
        expects =>
          +{ MASTER1 => [ 2, 4, 6, 8, 10 ], MASTER2 => [ 1, 3, 5, 7, 9 ] },
    );

    test_resolve_node_keys(
        desc      => 'Key strategy given from config',
        resolver  => $resolver,
        node      => 'MASTER_CLUSTER',
        node_args => undef,
        keys      => [ 1 .. 10 ],
        expects =>
          +{ MASTER1 => [ 2, 4, 6, 8, 10 ], MASTER2 => [ 1, 3, 5, 7, 9 ] },
    );

    test_resolve_node_keys(
        desc      => 'Multi key strategy given from config',
        resolver  => $resolver,
        node      => 'SLAVE_CLUSTER',
        node_args => undef,
        keys      => [
            [ 3, 2 ], [ 3, 4 ], [ 3, 3 ], [ 4, 2 ],
            [ 4, 3 ], [ 4, 7 ], [ 5, 2 ], [ 5, 3 ],
        ],
        expects => +{
            SLAVE1 => [ [ 3, 2 ], [ 3, 4 ] ],
            SLAVE2 => [ [ 3, 3 ] ],
            SLAVE3 => [ [ 4, 2 ] ],
            SLAVE4 => [ [ 4, 3 ], [ 4, 7 ] ],
            SLAVE5 => [ [ 5, 2 ] ],
            SLAVE6 => [ [ 5, 3 ] ]
        },
    );

    test_resolve_node_keys(
        desc => 'List',
        resolver => $resolver,
        node => 'SLAVE_LIST_CLUSTER',
        node_args => undef,
        keys => [ 1 .. 6 ],
        expects => +{
            SLAVE1 => [ 1, 4 ],
            SLAVE3 => [ 2, 3, 6 ],
            SLAVE5 => [ 5 ],
        },
    );

    test_resolve_node_keys(
        desc => 'Range',
        resolver => $resolver,
        node => 'RANGE_CLUSTER',
        node_args => undef,
        keys => [ 3, 5, 14, 18, 20, 22, 37, 44, 50, 51 ],
        expects => +{
            SLAVE1 => [ 3, 5 ],
            SLAVE2 => [ 14, 18 ],
            SLAVE3 => [ 20, 22 ],
            SLAVE4 => [ 37 ],
            SLAVE5 => [ 44 ],
            SLAVE6 => [ 50, 51 ],
        }
    );
}

subtest 'using resolve_node_keys as static class' => sub {
    $DBIx::DBHResolver::CONFIG = +{};
    my $resolver = 'DBIx::DBHResolver';
    $resolver->config($TEST_CONFIG);
    run_all_tests($resolver);
    done_testing;
};

subtest 'using resolve_node_keys as static sub class' => sub {
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
  'using resolve_node_keys as static sub class, store config into parent class'
  => sub {
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

subtest 'using resolve_node_keys as instance' => sub {
    $DBIx::DBHResolver::CONFIG = +{};
    my $resolver = DBIx::DBHResolver->new;
    $resolver->config($TEST_CONFIG);
    run_all_tests($resolver);
    done_testing;
};

subtest 'using resolve_node_keys as instance of sub class' => sub {
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

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
