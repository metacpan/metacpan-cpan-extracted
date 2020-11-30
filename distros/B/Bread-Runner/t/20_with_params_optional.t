#!/usr/bin/env perl
use strict;
use warnings;
use 5.012;
use Test::Most;
use lib ('t');

use Bread::Runner;

@ARGV=qw(--string bar --noflag --int 13 --array x --array y --hash foo=bar --hash answer=42);
my ( $bb, $service ) = Bread::Runner->setup( 'BreadRunTest',
        { service => 'some_script' } );

is($service->string,'bar','param: string');
is( $service->flag, 0, 'param: flag' );
is( $service->int, 13, 'param: int' );
cmp_deeply( $service->array, [qw(x y)], 'param: array' );
is ( $service->hash->{foo}, 'bar', 'param: hash->foo');
is ( $service->hash->{answer}, '42', 'param: hash->answer');

done_testing();

