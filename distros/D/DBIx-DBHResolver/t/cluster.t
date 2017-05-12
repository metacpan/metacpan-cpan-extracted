use strict;
use warnings;

use Test::More;
use DBIx::DBHResolver;

our $CONFIG = +{
    clusters => +{
        NODE => [ qw/NODE1 NODE2/ ],
    },
    connect_info => +{
        NODE1 => +{
            dsn => '', user => '', password => '',
            attrs => +{},
        },
        NODE2 => +{
            dsn => '', user => '', password => '',
            attrs => +{},
        },
    },
};

sub test_cluster {
    my %specs = @_;
    my ( $desc, $resolver, $node_or_cluster, $expects ) = @specs{qw/desc resolver node_or_cluster expects/};

    subtest $desc => sub {
        if ( exists $expects->{cluster} ) {
            is_deeply( [ $resolver->cluster($node_or_cluster) ], $expects->{cluster}, 'cluster deeply test' );
            is( $resolver->is_cluster($node_or_cluster), 1, sprintf('%s is cluster', $node_or_cluster) );
            is( $resolver->is_node($node_or_cluster), 0, sprintf('%s is not node', $node_or_cluster) );
        }
        else {
            is( $resolver->is_cluster($node_or_cluster), 0, sprintf('%s is not cluster', $node_or_cluster) );
            is( $resolver->is_node($node_or_cluster), 1, sprintf('%s is node', $node_or_cluster) );
        }
        done_testing;
    };
}

sub run_all_tests {
    my %specs = @_;
    my ( $resolver, $desc ) = @specs{qw/resolver desc/};
    $resolver->config($CONFIG);

    subtest $desc => sub {
        test_cluster(
            desc => 'NODE',
            resolver => $resolver,
            node_or_cluster => 'NODE',
            expects => +{
                cluster => [qw/NODE1 NODE2/],
            },
        );

       test_cluster(
            desc => 'NODE1',
            resolver => $resolver,
            node_or_cluster => 'NODE1',
            expects => +{},
        );

       test_cluster(
            desc => 'NODE2',
            resolver => $resolver,
            node_or_cluster => 'NODE2',
            expects => +{},
        );

        done_testing;
    };
}

run_all_tests(
    resolver => 'DBIx::DBHResolver',
    desc => 'run as static class'
);

run_all_tests(
    resolver => DBIx::DBHResolver->new,
    desc => 'run as object',
);

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:
