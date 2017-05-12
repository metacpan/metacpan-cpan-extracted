#!/usr/bin/perl
#
# some tests that collect the output of commands via App::Cmd::Tester

use 5.006;
use strict;
use warnings;
use autodie;

use File::Path qw(remove_tree);
use File::Temp ();
use App::JobLog;
use App::JobLog::Config qw(log DIRECTORY);
use App::JobLog::Log::Line;
use App::JobLog::Log;
use App::JobLog::Time qw(tz);
use DateTime;
use File::Spec;
use IO::All -utf8;
use FileHandle;
use DateTime::TimeZone;
use POSIX qw(tzset);

use Test::More;
use App::Cmd::Tester;
use Test::Fatal;

# create a working directory
my $dir = File::Temp->newdir();
$ENV{ DIRECTORY() } = $dir;

# use a constant time zone so as to avoid crafting data to fit various datelight savings time adjustments
$ENV{'TZ'} = 'America/New_York';
tzset();
$App::JobLog::Config::tz =
  DateTime::TimeZone->new( name => 'America/New_York' );

subtest 'basic test' => sub {

   # make a big log
   my $log   = App::JobLog::Log->new;
   my $start = make_date(qw(2011  1  1 0  0 0));
   my $end   = $start->clone->add( months => 1 );
   my $t     = $start->clone;
   my $count = 1;
   while ( $t <= $end ) {
      $log->append_event( time => $t, description => 'foo' . $count++ );
      $t->add( hours => 6 );
   }
   my $result = test_app( 'App::JobLog' => [qw(summary -W 2011/1)] );
   is( $result->error, undef, 'threw no exceptions' );
};

subtest 'note summary' => sub {

   # make a big log
   '' > io log;
   my $log   = App::JobLog::Log->new;
   my $start = make_date(qw(2011  1  1 0  0 0));
   my $end   = $start->clone->add( months => 1 );
   my $t     = $start->clone;
   my $count = 1;
   while ( $t <= $end ) {
      my $method = $count % 2 ? 'append_event' : 'append_note';
      $log->$method( time => $t, description => 'foo' . $count++ );
      $t->add( hours => 6 );
   }
   my $result = test_app( 'App::JobLog' => [qw(summary -W --notes 2011/1)] );
   is( $result->error, undef, 'threw no exceptions' );
   like( $result->stdout, qr/foo/, 'found some notes' );
   test_app( 'App::JobLog' => [qw(note testing)] );
   $result = test_app( 'App::JobLog' => [qw(summary -W --notes today)] );
   like( $result->stdout, qr/testing/, 'found appended note' );
};

subtest 'tags' => sub {

   # make a big log
   '' > io log;
   my $log = App::JobLog::Log->new;
   my $d   = make_date(qw(2011  1  1 0  0 0));
   $log->append_event( time => $d, tags => ['description'] );
   $log->append_event( time => $d->clone->add( minutes => 1 ), done => 1 );
   $d->add( days => 1 );
   $log->append_note( time => $d, tags => ['note'] );
   my $result = test_app( 'App::JobLog' => [qw(tags)] );
   is( $result->error, undef, 'threw no exceptions' );
   like( $result->stdout, qr/description/, 'found description tag' );
   unlike( $result->stdout, qr/note/, 'did not find note tag' );
   $result = test_app( 'App::JobLog' => [qw(tags --all)] );
   like( $result->stdout, qr/description/, 'found description tag' );
   like( $result->stdout, qr/note/,        'found note tag' );
   $result = test_app( 'App::JobLog' => [qw(tags --notes)] );
   unlike( $result->stdout, qr/description/, 'did not find description tag' );
   like( $result->stdout, qr/note/, 'found note tag' );

   # search within range
   note 'searching within range of first date';
   $result = test_app( 'App::JobLog' => [qw(tags 2011/1/1)] );
   is( $result->error, undef, 'threw no exceptions' );
   like( $result->stdout, qr/description/, 'found description tag' );
   unlike( $result->stdout, qr/note/, 'did not find note tag' );
   $result = test_app( 'App::JobLog' => [qw(tags --all 2011/1/1)] );
   like( $result->stdout, qr/description/, 'found description tag' );
   unlike( $result->stdout, qr/note/, 'did not find note tag' );
   $result = test_app( 'App::JobLog' => [qw(tags --notes 2011/1/1)] );
   unlike( $result->stdout, qr/description/, 'did not find description tag' );
   unlike( $result->stdout, qr/note/,        'did not find note tag' );
   note 'searching within range of second date';
   $result = test_app( 'App::JobLog' => [qw(tags 2 January 2011)] );
   is( $result->error, undef, 'threw no exceptions' );
   unlike( $result->stdout, qr/description/, 'did not find description tag' );
   unlike( $result->stdout, qr/note/,        'did not find note tag' );
   $result = test_app( 'App::JobLog' => [qw(tags --all 2 January 2011)] );
   unlike( $result->stdout, qr/description/, 'did not find description tag' );
   like( $result->stdout, qr/note/, 'found note tag' );
   $result = test_app( 'App::JobLog' => [qw(tags --notes 2 January 2011)] );
   unlike( $result->stdout, qr/description/, 'did not find description tag' );
   like( $result->stdout, qr/note/, 'found note tag' );
};

subtest 'last tag test' => sub {

   '' > io log;
   my $log        = App::JobLog::Log->new;
   my $d          = make_date(qw(2011 1 1 1 1 1));
   my @tag_combos = ( [ 1, 2 ], [1], [2] );
   for my $tags (@tag_combos) {
      my @tags = map { "t$_" } @$tags;
      my $description = 0;
      $description += $_ for @$tags;
      $log->append_event(
         time        => $d,
         tags        => \@tags,
         description => "d$description"
      );
      $d->add( minutes => 1 );
   }
   local $App::JobLog::Time::now = $d;
   my @spec = (
      [ 'last --tag t1'                         => 'd1' ],
      [ 'last --tag t1 --tag t2'                => 'd3' ],
      [ 'last --tag t2'                         => 'd2' ],
      [ 'last --any --tag t1'                   => 'd1' ],
      [ 'last --any --tag t1 --tag t2'          => 'd2' ],
      [ 'last --any --tag t2'                   => 'd2' ],
      [ 'last --without t1'                     => 'd2' ],
      [ 'last --without t1 --without t2'        => 'no matching event' ],
      [ 'last --without t2'                     => 'd1' ],
      [ 'last --some --without t1'              => 'd2' ],
      [ 'last --some --without t1 --without t2' => 'd2' ],
      [ 'last --some --without t2'              => 'd1' ],
   );
   for my $s (@spec) {
      my ( $c, $d ) = @$s;
      my $command = [ split /\s+/, $c ];
      my $result = test_app 'App::JobLog' => $command;
      local $" = ' ';
      like $result->stdout, qr/\b$d\b/, "correct description for @$command";
   }
};

SKIP: {
   skip 'developer test', 1 unless $ENV{JOBLOG_TESTING};
   subtest 'last event error message' => sub {
      local $App::JobLog::Time::now;
      local $App::JobLog::Config::tz;
      $App::JobLog::Config::tz =
        DateTime::TimeZone->new( name => 'America/New_York' );
      my $now = DateTime->new(
         year      => 2012,
         month     => 3,
         day       => 3,
         hour      => 12,
         minute    => 16,
         time_zone => tz
      );
      $App::JobLog::Time::now = $now;

      # make a big log
      '' > io log;
      my $log = App::JobLog::Log->new;
      my $then = $now->clone->subtract( days => 1 );
      $log->append_event(
         time        => $then,
         description => 'what happened yesterday'
      );
      my $result = test_app( 'App::JobLog' => ['last'] );
      ok( $result->stdout =~ /ongoing/,
         'properly reported ongoing event spanning day boundary' );
   };
}

done_testing();

remove_tree $dir;

sub make_date {
   my ( $year, $month, $day, $hour, $minute, $second ) = @_;
   return DateTime->new(
      year      => $year,
      month     => $month,
      day       => $day,
      hour      => $hour,
      minute    => $minute,
      second    => $second,
      time_zone => $App::JobLog::Config::tz,
   );
}
