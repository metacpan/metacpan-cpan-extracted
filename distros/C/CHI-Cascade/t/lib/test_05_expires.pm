package test_05_expires;

use strict;
use Test::More;

use parent 'Exporter';
use Time::HiRes qw(time);

our @EXPORT = qw(test_cascade);

my $recomputed;

sub test_cascade {
    my $cascade = shift;

    $cascade->rule(
        target          => 'big_array',
        code            => sub {
            $_[0]->value_expires( '2s' );
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

    my $res;

    ok( defined( $res = $cascade->run( 'one_page_0' ) ) );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( $cascade->{stats}{recompute} == 2 );
    ok( defined( $res = $cascade->run( 'one_page_1' ) ) );
    is_deeply( $res, [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ] );
    ok( $cascade->{stats}{recompute} == 3 );

    sleep 3;

    ok( defined( $res = $cascade->run( 'one_page_0' ) ) );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );
    ok( $cascade->{stats}{recompute} == 5 );
    ok( defined( $res = $cascade->run( 'one_page_1' ) ) );
    is_deeply( $res, [ 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 ] );
    ok( $cascade->{stats}{recompute} == 6 );

    done_testing;
}

1;
