#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use App::locket::Store;

my ( $store, $query, $found, $result );

$store = App::locket::Store->from({
});

ok( $store );
cmp_deeply( 0+$store->all, 0 );

$result = $store->search( [qw/ a b c d /] );
cmp_deeply( $result->{ query }, [] );
cmp_deeply( $result->{ found }, [] );

$store = App::locket::Store->from({
    a => 1,
    b => 2,
    c => 3,
    d => 4,
    ab => 5,
    bc => 6,
    ac => 7,
});

ok( $store );
cmp_deeply( 0+$store->all, 7 );

$result = $store->search( [qw/ a b c d /] );
cmp_deeply( $result->{ query }, [qw/ a b c /] );
cmp_deeply( $result->{ found }, [] );

$result = $store->search( [qw/ a /] );
cmp_deeply( $result->{ query }, [qw/ a /] );
cmp_deeply( $result->{ found }, [qw/ a ab ac /] );

$result = $store->search( [qw/ a c /] );
cmp_deeply( $result->{ query }, [qw/ a c /] );
cmp_deeply( $result->{ found }, [qw/ ac /] );

$result = $store->search( [qw/ a c d /] );
cmp_deeply( $result->{ query }, [qw/ a c d /] );
cmp_deeply( $result->{ found }, [qw/ /] );

$result = $store->search( [qw/ a i i /] );
cmp_deeply( $result->{ query }, [qw/ a i /] );
cmp_deeply( $result->{ found }, [qw/ /] );

$result = $store->search( [qw/ a i z /] );
cmp_deeply( $result->{ query }, [qw/ a i /] );
cmp_deeply( $result->{ found }, [qw/ /] );

done_testing;
