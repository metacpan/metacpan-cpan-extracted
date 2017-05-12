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

# fix current moment
my $now =
  DateTime->new( year => 2012, month => 12, day => 24, time_zone => tz );
$App::JobLog::Time::now = $now;

subtest 'summary with open task' => sub {

    # make a big log
    my $file = File::Spec->catfile( 't', 'data', 'regression1.log' );
    my $io = io $file;
    $io > io log;
    my $result = test_app( 'App::JobLog' => [qw(summary last week)] );
    unlike(
        $result->error // '',
        qr/Error: Can't call method "end" on an undefined value/,
        'no method-called-on-undefined-value error'
    );
};

done_testing();

remove_tree $dir;
