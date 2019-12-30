package test_07_deprecated_stash;

use strict;
use Test::More;

use parent 'Exporter';
use Time::HiRes qw(time);

our @EXPORT = qw(test_cascade);

my $recomputed;

sub test_cascade {
    my $cascade = shift;

    plan tests => 6;

    $cascade->rule(
        target          => 'big_array',
        code            => sub {
            my $rule = shift;

            ok( $rule->cascade->stash && $rule->cascade->stash->{key1} == 1 );
            return [ 1 .. 1000 ];
        }
    );

    $cascade->rule(
        target          => qr/^one_page_(\d+)$/,
        depends         => 'big_array',
        code            => sub {
            my ( $rule, $target ) = @_;

            ok( $target eq 'one_page_0'
                ?
                    $rule->cascade->stash && $rule->cascade->stash->{key2} == 2
                :
                    ref $rule->cascade->stash eq 'HASH' && ! exists $rule->cascade->stash->{key2}
            );
            my ($page) = $rule->target =~ /^one_page_(\d+)$/;

            my $ret = [ @{$rule->dep_values->{big_array}}[ ($page * 10) .. (( $page + 1 ) * 10 - 1) ] ];
            $ret;
        }
    );

    my $res;

    ok( defined( $res = $cascade->run( 'one_page_0', stash => { key1 => 1, key2 => 2 } ) ) );
    is_deeply( $res, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] );

    ok( defined( $res = $cascade->run( 'one_page_1' ) ) );
}

1;
