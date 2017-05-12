#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
    exit;
}
plan tests => 110;

use_ok('Config::Crontab');

my $event;

## empty object
$event = new Config::Crontab::Event;
is( $event->dump, '' );
undef $event;

## setting via datetime
$event = new Config::Crontab::Event( -datetime => '@hourly',
                                     -command  => '/usr/sbin/backup_everything' );
is( $event->datetime, '@hourly' );
is( $event->command, '/usr/sbin/backup_everything' );
is( $event->dump, '@hourly /usr/sbin/backup_everything' );
undef $event;

## setting via datetime
$event = new Config::Crontab::Event( -datetime => '@hourly',
                                     -command  => '/usr/sbin/backup_everything' );
is( $event->datetime, '@hourly' );
is( $event->datetime, '@hourly' );
is( $event->command, '/usr/sbin/backup_everything' );
is( $event->dump, '@hourly /usr/sbin/backup_everything' );
undef $event;

## setting via datetime
$event = new Config::Crontab::Event( -datetime => '5 0 * * *',
                                     -command  => '/usr/sbin/backup_everything' );
is( $event->datetime, '5 0 * * *' );
is( $event->special, '' );
is( $event->minute, 5 );
is( $event->hour, 0 );
undef $event;

## setting via datetime
$event = new Config::Crontab::Event( -datetime => '*/5 0 * * *',
                                     -command  => '/usr/sbin/backup_everything' );
is( $event->datetime, '*/5 0 * * *' );
is( $event->special, '' );
is( $event->minute, '*/5' );
is( $event->hour, 0 );
undef $event;

## setting via datetime
$event = new Config::Crontab::Event( -datetime => '*/2,*/5 0 * * *',
                                     -command  => '/bin/echo' );
is( $event->datetime, '*/2,*/5 0 * * *', 'multiple wildcards (rus)' );

## setting via special
$event = new Config::Crontab::Event( -special => '@monthly',
                                     -command => '/usr/sbin/backup_everything' );
is( $event->datetime, '@monthly' );
is( $event->special, '@monthly' );
is( $event->minute, '*' );
is( $event->hour, '*' );
undef $event;

## FIXME: currently no checks for bogus 'special' strings
## FIXME: if we ever do checking on -special, these tests will have
## FIXME: to be changed
## setting via special
$event = new Config::Crontab::Event( -special => '5 0 1 * *',
                                     -command => '/usr/sbin/backup_everything' );
is( $event->datetime, '5 0 1 * *' );
is( $event->special, '5 0 1 * *' );
is( $event->minute, '*' );
is( $event->hour, '*' );
undef $event;

## setting via -data
$event = new Config::Crontab::Event( -data => '@reboot /usr/sbin/food' );
is( $event->special, '@reboot' );
is( $event->datetime, '@reboot' );
is( $event->command, '/usr/sbin/food' );
undef $event;

## setting via -data: -data overrides all other attributes
$event = new Config::Crontab::Event( -data     => '@reboot /usr/sbin/food',
                                     -active   => 0,  ## ignored
                                     -hour     => 5,  ## ignored
                                     -special  => '@daily',  ## ignored
                                     -datetime => '5 2 * * Fri',  ## ignored
                                   );
is( $event->special, '@reboot' );
is( $event->datetime, '@reboot' );
is( $event->command, '/usr/sbin/food' );
is( $event->hour, '*' );
is( $event->dump, '@reboot /usr/sbin/food' );
undef $event;

## setting via -data
$event = new Config::Crontab::Event( -data => '6 1 * * Fri /usr/sbin/backup' );
is( $event->special, '' );
is( $event->datetime, '6 1 * * Fri' );
is( $event->command, '/usr/sbin/backup' );
undef $event;

## try some disabled events
$event = new Config::Crontab::Event( -data => '## 7 2 * * Mon /bin/monday' );
is( $event->active, 0 );
is( $event->datetime, '7 2 * * Mon' );
is( $event->command, '/bin/monday' );
undef $event;

## setting via attributes
$event = new Config::Crontab::Event( -minute  => 0,
                                     -hour    => 4,
                                     -command => '/usr/sbin/foo' );
is( $event->hour, 4 );
is( $event->minute, 0 );
is( $event->command, '/usr/sbin/foo' );
is( $event->special, '' );
is( $event->dump, '0 4 * * * /usr/sbin/foo' );
is( $event->active(0), 0 );
is( $event->dump, '#0 4 * * * /usr/sbin/foo' );
is( $event->data, '0 4 * * * /usr/sbin/foo' );
undef $event;

## setting via attributes: datetime takes precedence over fields
$event = new Config::Crontab::Event( -minute   => 5,
                                     -datetime => '@reboot',
                                     -command  => '/usr/sbin/doofus' );
is( $event->minute, '*' );
is( $event->hour, '*' );
is( $event->special, '@reboot' );
is( $event->datetime, '@reboot' );
is( $event->command, '/usr/sbin/doofus' );
# do not undef $event here

## resetting object via methods
is( $event->datetime('6 8 * Mar Fri,Sat,Sun'), '6 8 * Mar Fri,Sat,Sun' );
is( $event->special, '' );
is( $event->dump, '6 8 * Mar Fri,Sat,Sun /usr/sbin/doofus' );
# do not undef $event here

## resetting object via methods
$event->datetime([6, 9, '*', 'Mar', 'Fri,Sun'], '6 9 * Mar Fri,Sun');
is( $event->special, '' );
is( $event->dump, '6 9 * Mar Fri,Sun /usr/sbin/doofus' );
# do not undef here

## resetting object via methods
$event->datetime([6, '*/2', '*', 'Mar', 'Fri,Sun'], '6 */2 * Mar Fri,Sun');
is( $event->special, '' );
is( $event->dump, '6 */2 * Mar Fri,Sun /usr/sbin/doofus', "event set by datetime" );
# do not undef here

## resetting object via methods
$event->datetime(['@daily'], '@daily');
is( $event->special, '@daily' );
is( $event->dump, '@daily /usr/sbin/doofus' );
undef $event;

## set pieces via methods
$event = new Config::Crontab::Event( -minute => 5 );
is( $event->hour(0), 0 );
is( $event->command('/usr/bin/foo'), '/usr/bin/foo' );
is( $event->data, '5 0 * * * /usr/bin/foo' );
is( $event->dump, '5 0 * * * /usr/bin/foo' );
is( $event->active(0), 0 );
is( $event->data, '5 0 * * * /usr/bin/foo' );
is( $event->dump, '#5 0 * * * /usr/bin/foo' );
undef $event;

## try some more esoteric values
$event = new Config::Crontab::Event;
is( $event->minute('23,53'), '23,53' );
is( $event->hour('*/2'), '*/2' );
is( $event->month('1,3,Apr,Aug'), '1,3,Apr,Aug' );
is( $event->dow('Fri,Sat,Sun'), 'Fri,Sat,Sun' );
is( $event->command('/bin/foo'), '/bin/foo' );
is( $event->dump, '23,53 */2 * 1,3,Apr,Aug Fri,Sat,Sun /bin/foo' );
is( $event->minute('5-55/3'), '5-55/3' );
is( $event->hour('0-4,8-12'), '0-4,8-12' );
is( $event->dump, '5-55/3 0-4,8-12 * 1,3,Apr,Aug Fri,Sat,Sun /bin/foo' );
undef $event;

## failure via -data
ok( ! defined($event = new Config::Crontab::Event( -data => 'foo' )) );
undef $event;

## failure via -data
ok( ! defined($event = new Config::Crontab::Event( -data => 1 )) );
undef $event;

## test system (user) syntax via -data
$event = new Config::Crontab::Event( -data => '3 2 1 * Fri joe foo bar',
                                     -system => 1 );
is( $event->minute, 3 );
is( $event->dow, 'Fri' );
is( $event->user, 'joe' );
is( $event->command, 'foo bar', "event set via -data" );
undef $event;

## test system (user) syntax via methods
$event = new Config::Crontab::Event;
is( $event->system, 0 );
$event->hour('5');
$event->minute('26');
$event->user('joe');
ok( $event->system );
$event->command('/bin/bash');
is( $event->dump, "26\t5\t*\t*\t*\tjoe\t/bin/bash" );
undef $event;

## test system (user) syntax via -data and methods
$event = new Config::Crontab::Event( -data => '3 2 1 * Fri foo bar' );
is( $event->system, 0 );
$event->user('joe');
is( $event->system, 1 );
is( $event->dump, "3\t2\t1\t*\tFri\tjoe\tfoo bar" );
undef $event;

## test system (user) syntax via -data and methods
$event = new Config::Crontab::Event;
$event->system(1);
$event->data( "3\t2\t1\t*\tFri\tfoo\tbar" );
is( $event->user, 'foo' );
is( $event->command, 'bar' );
undef $event;

## test system (user) syntax (REMEMBER: -data always overrides all other params except 'system'!)
$event = new Config::Crontab::Event( -data   => '3 2 1 * Fri foo bar',
				     -user   => 'joe', );  ## ignored
is( $event->system, 0 );
is( $event->user, '' );
is( $event->command, 'foo bar' );
is( $event->dump, "3 2 1 * Fri foo bar" );
undef $event;

## test system (user) syntax
$event = new Config::Crontab::Event( -data   => '3 2 1 * Fri foo bar',
				     -system => 1 );
is( $event->system, 1 );
is( $event->user, 'foo' );
is( $event->command, 'bar' );
is( $event->dump, "3\t2\t1\t*\tFri\tfoo\tbar" );
undef $event;

## test system (user) syntax
$event = new Config::Crontab::Event;
$event->data('3 2 1 * Fri foo bar');
$event->user('joe');
is( $event->system, 1 );
is( $event->command, 'foo bar');
is( $event->dump, "3\t2\t1\t*\tFri\tjoe\tfoo bar" );
$event->user('zelda');
is( $event->data, "3\t2\t1\t*\tFri\tzelda\tfoo bar" );

$event->system(0);
$event->data('1 3 5 * Wed blech winnie');
is( $event->dump, '1 3 5 * Wed blech winnie' );
is( $event->user, '' );
undef $event;

## test nolog option (SuSE-specific syntax)
$event = new Config::Crontab::Event;
$event->data('5 10 * * * /bin/echo "quietly now"');
$event->nolog(1);
is( $event->dump, '-5 10 * * * /bin/echo "quietly now"' );
$event->minute(50);
is( $event->dump, '-50 10 * * * /bin/echo "quietly now"' );
$event->nolog(0);
is( $event->dump, '50 10 * * * /bin/echo "quietly now"' );

## make it into a system event
$event->user('joe');
$event->nolog(1);
is( $event->dump, qq!-50\t10\t*\t*\t*\tjoe\t/bin/echo "quietly now"! );
