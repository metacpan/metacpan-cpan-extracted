use strict;
use warnings;
use Test::More;
use Data::RuledCluster;

my $dr = Data::RuledCluster->new(
    config   => undef,
    callback => undef,
);

subtest 'Formatted Strategy' => sub {
    my $config = +{
        clusters => +{
            SLAVE_R => +{
                strategy    => 'Formatted',
                nodes       => [qw/SLAVE001_R SLAVE002_R SLAVE100_R/],
                node_format => 'SLAVE%03d_R',
            },
            OOPS_R => +{
                strategy    => 'Formatted',
                nodes       => [qw/OOPS001_R/],
            },
        },
        node => +{
            SLAVE001_R=> ['dbi:mysql:slave001', 'root', '',],
            SLAVE002_R=> ['dbi:mysql:slave002', 'root', '',],
            SLAVE100_R=> ['dbi:mysql:slave100', 'root', '',],
            OOPS001_R => ['dbi:mysql:oops100',  'root', '',],
        },
    };
    $dr->config($config);

    my $node_info;
    $node_info = $dr->resolve('SLAVE_R', 1);
    note explain $node_info;
    is_deeply $node_info, +{node => 'SLAVE001_R', node_info => ['dbi:mysql:slave001', 'root', '',]};
    is_deeply $dr->resolve('SLAVE_R', 2),   +{node => 'SLAVE002_R', node_info => ['dbi:mysql:slave002', 'root', '',]};
    is_deeply $dr->resolve('SLAVE_R', 100), +{node => 'SLAVE100_R', node_info => ['dbi:mysql:slave100', 'root', '',]};
    eval {
        $dr->resolve('SLAVE_R', 3);
    };
    my $e = $@;
    like $e, qr/SLAVE003_R node is not exists/;

    eval {
        $dr->resolve('OOPS_R', 1);
    };
    $e = $@;
    like $e, qr/node_format settings must be required/;

    my $resolve_node_keys = $dr->resolve_node_keys('SLAVE_R', [qw/1 2 100/]);
    note explain $resolve_node_keys;
    is_deeply $resolve_node_keys, +{
        SLAVE001_R => [qw/1/],
        SLAVE002_R => [qw/2/],
        SLAVE100_R => [qw/100/],
    };
};

done_testing;
