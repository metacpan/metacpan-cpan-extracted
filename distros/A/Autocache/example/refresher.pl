#!/usr/bin/env perl

use strict;
use warnings;

use lib '../lib';

use Log::Log4perl qw( :easy );

use Autocache qw( autocache );

Log::Log4perl->easy_init( $DEBUG );

Autocache->initialise( filename => './refresher.conf', logger => get_logger() );

autocache 'cached_time';

my $finish = time + 30;

do
{
    printf "finish time: %d - cached time: %d\n",
        $finish,
        cached_time();
    Autocache->singleton->run_work_queue;
    sleep 1;
}
while( $finish > cached_time() );

exit;

sub cached_time
{
    time;
}
