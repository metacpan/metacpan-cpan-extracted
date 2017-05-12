#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

eval {
    for my $path ( 'bin/app_dispatch', '../bin/app_dispatch', 'app_dispatch' ) {
        next unless -e $path;
        do $path;
        last;
    }
};

can_ok( 'App::Dispatch', 'new' );

my $one = App::Dispatch->new( 't/sample', 'sample' );

is_deeply(
    $one->programs,
    {
        test => {
            'sample' => 't/sample.pl',
            'bar'    => '/bin/bar',
            'baz'    => '/bin/baz',
            'foo'    => '/bin/foo'
        }
    },
    "Read config"
);

done_testing;
