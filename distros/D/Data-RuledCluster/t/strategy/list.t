use strict;
use warnings;
use Test::More;
use Data::RuledCluster;

my $dr = Data::RuledCluster->new(
    config   => undef,
    callback => undef,
);

subtest 'List Strategy' => sub {
    my $config = +{
        clusters => +{
            SLAVE => +{
                strategy        => 'List',
                nodes           => [qw/SLAVE001 SLAVE002 SLAVE003/],
                strategy_config => +{
                    SLAVE001 => [qw/1 4/],
                    SLAVE002 => [qw/2 3 6/],
                    SLAVE003 => [qw/5/],
                },
            },
        },
        node => +{
            SLAVE001 => ['dbi:mysql:slave001', 'root', '',],
            SLAVE002 => ['dbi:mysql:slave002', 'root', '',],
            SLAVE003 => ['dbi:mysql:slave003', 'root', '',],
        },
    };
    $dr->config($config);

    my $node_info;
    $node_info = $dr->resolve('SLAVE', 1);
    note explain $node_info;
    is_deeply $node_info, +{node => 'SLAVE001', node_info => ['dbi:mysql:slave001', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 4), +{node => 'SLAVE001', node_info => ['dbi:mysql:slave001', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 2), +{node => 'SLAVE002', node_info => ['dbi:mysql:slave002', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 3), +{node => 'SLAVE002', node_info => ['dbi:mysql:slave002', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 6), +{node => 'SLAVE002', node_info => ['dbi:mysql:slave002', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 5), +{node => 'SLAVE003', node_info => ['dbi:mysql:slave003', 'root', '',]};

    my $resolve_node_keys = $dr->resolve_node_keys('SLAVE', [qw/1 2 3 4 5 6/]);
    note explain $resolve_node_keys;
    is_deeply $resolve_node_keys, +{
        SLAVE001 => [qw/1 4/],
        SLAVE002 => [qw/2 3 6/],
        SLAVE003 => [qw/5/],
    };
};

subtest 'List Strategy' => sub {
    my $config = +{
        clusters => +{
            SLAVE => +{
                strategy        => 'List',
                nodes           => [qw/SLAVE001 SLAVE002 SLAVE003/],
                list_map        => +{
                    1 => 'SLAVE001',
                    4 => 'SLAVE001',
                    2 => 'SLAVE002',
                    3 => 'SLAVE002',
                    6 => 'SLAVE002',
                    5 => 'SLAVE003',
                },
            },
        },
        node => +{
            SLAVE001 => ['dbi:mysql:slave001', 'root', '',],
            SLAVE002 => ['dbi:mysql:slave002', 'root', '',],
            SLAVE003 => ['dbi:mysql:slave003', 'root', '',],
        },
    };
    $dr->config($config);

    my $node_info;
    $node_info = $dr->resolve('SLAVE', 1);
    note explain $node_info;
    is_deeply $node_info, +{node => 'SLAVE001', node_info => ['dbi:mysql:slave001', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 4), +{node => 'SLAVE001', node_info => ['dbi:mysql:slave001', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 2), +{node => 'SLAVE002', node_info => ['dbi:mysql:slave002', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 3), +{node => 'SLAVE002', node_info => ['dbi:mysql:slave002', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 6), +{node => 'SLAVE002', node_info => ['dbi:mysql:slave002', 'root', '',]};
    is_deeply $dr->resolve('SLAVE', 5), +{node => 'SLAVE003', node_info => ['dbi:mysql:slave003', 'root', '',]};

    my $resolve_node_keys = $dr->resolve_node_keys('SLAVE', [qw/1 2 3 4 5 6/]);
    note explain $resolve_node_keys;
    is_deeply $resolve_node_keys, +{
        SLAVE001 => [qw/1 4/],
        SLAVE002 => [qw/2 3 6/],
        SLAVE003 => [qw/5/],
    };
};

done_testing;
