package tlib;

use utf8;
use strict;
use warnings;
use Test::More;
our $skip_concurrency;
$tlib::skip_concurrency = 0;
sub test_backend {
    my $storage_name = shift;
    my @params = @_;
    my $be = $main::be;
    my $c = $be->new(
        {
            storage   => $storage_name->new( @params ),
            expires => 5,
            prefix  => 'test_2_queue'
        }
    );
    my $oldsize = $c->get_info->{size};
    $c->increment;
    is( $c->get_info(100)->{size}, $oldsize + 1, 'append/size' );
    $c->increment;
    my $info = $c->get_info(100);
    is( $info->{size}, $oldsize + 2, 'yet another' );
    cmp_ok( $info->{timeout}, '>=', 3, 'timeout' );
    sleep 3;
    $c->increment;
    sleep 3;
    is( $c->get_info->{size}, 1, 'expiring' );
    ok( $c->clear, 'clearing' );
SKIP: {
    skip 'Concurrency is not working', 1 if $tlib::skip_concurrency;
    foreach ( 1 .. 15 ) {
        if ( !fork ) {

            my $sub_cache = $be->new(
                {
                    storage   => $storage_name->new( @params ),
                    expires => 60,
                    prefix  => 'test_2_queue'
                }
            );
            foreach ( 1 .. 100 ) {
                $sub_cache->increment;
            }
            exit;
        }
    }
    1 while ( waitpid -1, 0 ) != -1;
    is( $c->get_info->{size}, 1500, 'concurrency' );
}
}

1;
