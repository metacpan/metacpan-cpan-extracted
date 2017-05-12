#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Autocache qw( autocache );

Autocache->initialise( filename => 't/003_refresh.t.conf' );

ok( autocache 'cached_time', 'Autocache function' );

ok( test_refresh(), 'Test refresh' );

Autocache->singleton->get_default_strategy
    ->refresh_age(5);

my $cached_time = cached_time();
Autocache->singleton->run_work_queue;
sleep 2;
is($cached_time, cached_time(), 'Cached result before refresh_age is exceeded');
Autocache->singleton->run_work_queue;
sleep 4;
is($cached_time, cached_time(), 'Cached result before refresh_age is exceeded');
Autocache->singleton->run_work_queue;
isnt($cached_time, cached_time(), 'Refreshed result after refresh_age is exceeded');

exit;

sub test_refresh
{
    my $ok = 1;

    my $finish = time + 10;

    my $cached;
    my $current;

    do
    {
        $current = time();
        $cached = cached_time();

        if( ( $current - $cached ) > 3 )
        {
#            diag( "current: $current - cached: $cached - NOT OK" );
            $ok = 0;
        }

#        diag( "finish: $finish - cached: $cached" );

        Autocache->singleton->run_work_queue;
        sleep 1;
    }
    while( $finish > $cached );

    return $ok;
}

sub cached_time
{
    return time;
}
