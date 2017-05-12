use strict;
use warnings;

use Test::More;
use DBIx::DBHResolver;

my $resolver = DBIx::DBHResolver->new();
$resolver->config(+{
    connect_info => +{
        MASTER001 => +{},
        MASTER002 => +{},
        MASTER003 => +{},
        MASTER004 => +{},
        MASTER101 => +{},
    },
    clusters => +{
        MASTER => +{
            strategy => 'List',
            nodes => [qw/MASTER101 MASTER_KBC/],
            strategy_config => +{
                MASTER101 => [ 3, 12 ],
                '' => 'MASTER_KBC',
            },
        },
        MASTER_KBC => +{
            strategy => 'Key',
            nodes => [qw/MASTER001 MASTER002 MASTER003 MASTER004/],
        },
    }
});

subtest 'resolve' => sub {
    my $i = 0;
    is $resolver->resolve('MASTER', $i++), 'MASTER001';
    is $resolver->resolve('MASTER', $i++), 'MASTER002';
    is $resolver->resolve('MASTER', $i++), 'MASTER003';
    is $resolver->resolve('MASTER', $i++), 'MASTER101';
    is $resolver->resolve('MASTER', $i++), 'MASTER001';
    is $resolver->resolve('MASTER', $i++), 'MASTER002';
    is $resolver->resolve('MASTER', $i++), 'MASTER003';
    is $resolver->resolve('MASTER', $i++), 'MASTER004';
    is $resolver->resolve('MASTER', $i++), 'MASTER001';
    is $resolver->resolve('MASTER', $i++), 'MASTER002';
    is $resolver->resolve('MASTER', $i++), 'MASTER003';
    is $resolver->resolve('MASTER', $i++), 'MASTER004';
    is $resolver->resolve('MASTER', $i++), 'MASTER101';
    is $resolver->resolve('MASTER', $i++), 'MASTER002';
    is $resolver->resolve('MASTER', $i++), 'MASTER003';
    is $resolver->resolve('MASTER', $i++), 'MASTER004';
};

subtest 'resolve_node_keys' => sub {
    my $node_keys = $resolver->resolve_node_keys('MASTER', [ 0 .. 15 ]);
    is_deeply(
        $node_keys,
        +{
            MASTER001 => [ 0, 4, 8 ],
            MASTER002 => [ 1, 5, 9, 13, ],
            MASTER003 => [ 2, 6, 10, 14 ],
            MASTER004 => [ 7, 11, 15 ],
            MASTER101 => [ 3, 12 ],
        }
    );
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
