#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal qw( dies_ok );

use Algorithm::Cron;

{
   my $cron = Algorithm::Cron->new(
      base => 'utc',
      crontab => '0 0 0 1 0',
   );

   is_deeply( [ $cron->sec  ], [ 0 ], '$cron->sec for 0 0 0 1 0' );
   is_deeply( [ $cron->min  ], [ 0 ], '$cron->min for 0 0 0 1 0' );
   is_deeply( [ $cron->hour ], [ 0 ], '$cron->hour for 0 0 0 1 0' );
   is_deeply( [ $cron->mday ], [ 0 ], '$cron->mday for 0 0 0 1 0' );
   is_deeply( [ $cron->mon  ], [ 0 ], '$cron->mon for 0 0 0 1 0' );
   is_deeply( [ $cron->wday ], [ 0 ], '$cron->wday for 0 0 0 1 0' );
}

{
   my $cron = Algorithm::Cron->new(
      base => 'utc',
      crontab => '1 3 5 7 9',
   );

   is_deeply( [ $cron->sec  ], [ 0 ], '$cron->sec for 1 3 5 7 9' );
   is_deeply( [ $cron->min  ], [ 1 ], '$cron->min for 1 3 5 7 9' );
   is_deeply( [ $cron->hour ], [ 3 ], '$cron->hour for 1 3 5 7 9' );
   is_deeply( [ $cron->mday ], [ 5 ], '$cron->mday for 1 3 5 7 9' );
   is_deeply( [ $cron->mon  ], [ 6 ], '$cron->mon for 1 3 5 7 9' );
   is_deeply( [ $cron->wday ], [ 9 ], '$cron->wday for 1 3 5 7 9' );
}

{
   my $cron = Algorithm::Cron->new(
      base => 'utc',
      crontab => '* * * * *',
   );

   is_deeply( [ $cron->sec  ], [ 0 ], '$cron->sec for * * * * *' );
   is_deeply( [ $cron->min  ], [], '$cron->min for * * * * *' );
   is_deeply( [ $cron->hour ], [], '$cron->hour for * * * * *' );
   is_deeply( [ $cron->mday ], [], '$cron->mday for * * * * *' );
   is_deeply( [ $cron->mon  ], [], '$cron->mon for * * * * *' );
   is_deeply( [ $cron->wday ], [], '$cron->wday for * * * * *' );
}

{
   my $cron = Algorithm::Cron->new(
      base => 'utc',
      crontab => '*/10 * * * * *',
   );

   is_deeply( [ $cron->sec  ], [ 0, 10, 20, 30, 40, 50 ], '$cron->sec for */10 * * * * *' );
}

{
   my $cron = Algorithm::Cron->new(
      base => 'utc',
      min  => 10,
      hour => 3,
      mday => 15,
      mon  => 2,
   );

   is_deeply( [ $cron->sec  ], [ 0  ], '$cron->sec for named' );
   is_deeply( [ $cron->min  ], [ 10 ], '$cron->min for named' );
   is_deeply( [ $cron->hour ], [ 3  ], '$cron->hour for named' );
   is_deeply( [ $cron->mday ], [ 15 ], '$cron->mday for named' );
   is_deeply( [ $cron->mon  ], [ 1  ], '$cron->mon for named' );
   is_deeply( [ $cron->wday ], [],     '$cron->wday for named' );
}

dies_ok { Algorithm::Cron->new( crontab => '@hourly', base => 'utc' ) }
   "crontab => '\@hourly' dies";

dies_ok { Algorithm::Cron->new( crontab => 'one * * * *', base => 'utc' ) }
   'Unrecognised number dies';

# RT95454
{
   my $cron = Algorithm::Cron->new(
      base => 'utc',
      crontab => ' 20 23 1 1 *'
   );

   is_deeply( [ $cron->min ], [ 20 ], '$cron->min for leading space' );
   is_deeply( [ $cron->sec ], [ 0 ], '$cron->sec for leading space' );

   my $next = $cron->next_time( 0 );

   is( $next, 84000, '->next_time for crontab with space' );
}

done_testing;
