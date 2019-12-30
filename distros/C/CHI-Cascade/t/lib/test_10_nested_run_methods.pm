package test_10_nested_run_methods;

use strict;
use Test::More;
use CHI::Cascade::Value ':state';

use parent 'Exporter';

our @EXPORT = qw(test_cascade);

my $recomputed;

sub test_cascade {
    my $cascade = shift;

    $cascade->rule(
        target          => 'big_array',
        code            => sub {
            return [ 1 .. 1000 ];
        },
        recomputed      => sub { $recomputed++ }
    );

    $cascade->rule(
        target          => 'get_depends',
        code            => sub {
            my $rule = shift;
            ok( $rule->stash->{a} == 2, 'get_depends stash' );
            return 'big_array';
        },
        recomputed      => sub { $recomputed++ }
    );

    $cascade->rule(
        target          => qr/^one_page_(\d+)$/,
        depends         => [ sub { $_[0]->cascade->run('get_depends', stash => { a => 2 } ) } ],
        code            => sub {
            my ($rule) = @_;

            my ($page) = $rule->target =~ /^one_page_(\d+)$/;

            ok( $page != 0 || $rule->stash->{a} == 1, 'one_page stash' );

            my $ret = [ @{$rule->dep_values->{big_array}}[ ($page * 10) .. (( $page + 1 ) * 10 - 1) ] ];
            $ret;
        },
        recomputed      => sub { $recomputed++ }
    );

    $cascade->rule(
        target          => 'actual_test',
        actual_term     => 2.0,
        depends         => 'one_page_0',
        code            => sub {
            $_[2]->{one_page_0}
        }
    );

    ok( $cascade->{stats}{recompute} == 0, 'recompute stats - 1');

    is_deeply( $cascade->run('one_page_0', stash => { a => 1 } ), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache');
    ok( $cascade->{stats}{recompute} == 3 && $recomputed == 3, 'recompute stats - 2');

    is_deeply( $cascade->run('one_page_1'), [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ], '1th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 4, 'recompute stats - 3');

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 4, 'recompute stats - 4');

    select( undef, undef, undef, 0.5 );

    # To force recalculate dependencied
    $cascade->touch('big_array');

    is_deeply( $cascade->run('one_page_0', stash => { a => 1 } ), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache after touching');
    cmp_ok( $cascade->{stats}{recompute}, '==', 5, 'recompute stats - 5');

    is_deeply( $cascade->run('one_page_1'), [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ], '1th page from cache after touching');
    cmp_ok( $cascade->{stats}{recompute}, '==', 6, 'recompute stats - 6');

    is_deeply( $cascade->run('one_page_0'), [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], '0th page from cache');
    cmp_ok( $cascade->{stats}{recompute}, '==', 6, 'recompute stats - 7');

    ok( $cascade->{stats}{recompute} == $recomputed, 'recompute stats - 8');
}

1;
