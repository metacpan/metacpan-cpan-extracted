#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Algorithm::Cron;

my $t = 1364846197;
# $t is 2013-04-01 19:56:37 UTC

# UTC
{
   my $cron = Algorithm::Cron->new(
      base => 'utc',
      crontab => '0 4 * * *',
   );

   is( POSIX::strftime( "%Y-%m-%d %H:%M:%S", gmtime( $cron->next_time( $t ) ) ),
       "2013-04-02 04:00:00",
       'Next time in UTC' );
}

# Local
{
   my $cron = Algorithm::Cron->new(
      base => 'local',
      crontab => '0 4 * * *',
   );

   my $that_day = ( localtime $t )[3];
   my $next_day = $that_day + 1;

   is( POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime( $cron->next_time( $t ) ) ),
       "2013-04-0${next_day} 04:00:00",
       'Next time in localtime' );
}

done_testing;
