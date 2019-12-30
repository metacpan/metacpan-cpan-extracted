package test_06_ttl;

use strict;
use Test::More;
use CHI::Cascade::Value ':state';

use parent 'Exporter';
use Time::HiRes qw(time);

our @EXPORT = qw(test_cascade);

my $recomputed;

sub test_cascade {
    my $cascade = shift;

    $cascade->rule(
        target          => 'reset',
        code            => sub { 1 }
    );

    $cascade->rule(
        target          => 'big_array',
        depends         => 'reset',
        ttl             => [ 1, 2 ],
        code            => sub {
            return [ 1 .. 1000 ];
        }
    );

    $cascade->rule(
        target          => qr/^one_page_(\d+)$/,
        depends         => 'big_array',
        code            => sub {
            my ($rule) = @_;

            my ($page) = $rule->target =~ /^one_page_(\d+)$/;

            my $ret = [ @{$rule->dep_values->{big_array}}[ ($page * 10) .. (( $page + 1 ) * 10 - 1) ] ];
            $ret;
        }
    );

    my ( $res, $state, $ttl );

    ok( defined( $res = $cascade->run( 'one_page_0' ) ) );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( $cascade->{stats}{recompute} == 3 );
    ok( defined( $res = $cascade->run( 'one_page_1', ttl => \$ttl ) ) );
    is_deeply( $res, [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ] );
    ok( $cascade->{stats}{recompute} == 4 );
    ok( ! defined $ttl );

    $cascade->target_remove('reset');

    ok( defined( $res = $cascade->run( 'one_page_0', state => \$state, ttl => \$ttl ) ) );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( $cascade->{stats}{recompute} == 5 ); # reset is recomputed now but the one_page_0 is not
    ok( $state & CASCADE_TTL_INVOLVED );
    ok( not $state & CASCADE_RECOMPUTED );
    ok( defined $ttl && $ttl > 0 );

    my $prevTTL = $ttl;

    select( undef, undef, undef, 0.2 );

    # Now ttl will be reduced by ~ 0.2 seconds
    ok( defined( $res = $cascade->run( 'one_page_0', state => \$state, ttl => \$ttl ) ) );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( $cascade->{stats}{recompute} == 5 );
    ok( $state & CASCADE_TTL_INVOLVED );
    ok( not $state & CASCADE_RECOMPUTED );
    ok( defined $ttl && $ttl > 0 );

    cmp_ok( $prevTTL - $ttl, '>', 0.1 );
    cmp_ok( $prevTTL - $ttl, '<', 0.3 );

    select( undef, undef, undef, 1.9 );

    # Maximum (2 seconds) ttl has been reached now ( 0.2 + 1.9 time elapsed)
    ok( defined( $res = $cascade->run( 'one_page_0', state => \$state, ttl => \$ttl ) ) );
    ok( ! defined $ttl );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( $cascade->{stats}{recompute} == 7 );
    ok( not $state & CASCADE_TTL_INVOLVED );
    ok( $state & CASCADE_RECOMPUTED );

    ok( defined( $res = $cascade->run( 'one_page_0', state => \$state, ttl => \$ttl ) ) );
    ok( ! defined $ttl );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( $cascade->{stats}{recompute} == 7 );
    ok( not $state & CASCADE_TTL_INVOLVED );
    ok( ( $state & ( CASCADE_ACTUAL_VALUE | CASCADE_FROM_CACHE ) ) == ( CASCADE_ACTUAL_VALUE | CASCADE_FROM_CACHE ) );

    done_testing;
}

1;
