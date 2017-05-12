use strict;
use warnings;
use Test::More;

BEGIN { plan tests => 21 }

use_ok('Date::Remind::Event');
can_ok(
    'Date::Remind::Event', qw/
      new
      date
      duration
      tag
      body
      end
      /
);

my $i = Date::Remind::Event->new('2010/08/15 * * * * Adi away');

isa_ok( $i, 'Date::Remind::Event' );

my $dt = $i->date;
isa_ok( $dt, 'DateTime' );
is( $dt->year,   2010, 'year' );
is( $dt->month,  8,    'month' );
is( $dt->day,    15,   'day' );
is( $dt->hour,   0,    'hour' );
is( $dt->minute, 0,    'minute' );
is( $dt->second, 0,    'seconds' );

my $dur = $i->duration;
isa_ok( $dur, 'DateTime::Duration' );
is( $dur->days,    1, 'day duration' );
is( $dur->minutes, 0, 'minutes' );

my $end = $i->end;
isa_ok( $end, 'DateTime' );

is( "$dt",  '2010-08-15T00:00:00', 'start date' );
is( "$end", '2010-08-16T00:00:00', 'end date' );

# given
# REM 6 July AT 18:00 DURATION 1:00 MSG test

# $ remind -b0 -s test.rem 1 july 2010
$Date::Remind::Event::BFLAG = 0;
$i = Date::Remind::Event->new('2010/07/06 * * 60 1080 6:00-7:00pm test');

is( $i->body, 'test', '-b0' );

# $ remind -b1 -s test.rem 1 july 2010
$Date::Remind::Event::BFLAG = 1;
$i = Date::Remind::Event->new('2010/07/06 * * 60 1080 18:00-19:00 test');
is( $i->body,            'test',     '-b1' );
is( $i->duration->hours, 1,          '1 hour duration' );
is( $i->end->hms,        '19:00:00', 'end time' );

# $ remind -b2 -s test.rem 1 july 2010
$Date::Remind::Event::BFLAG = 2;
$i = Date::Remind::Event->new('2010/07/06 * * 60 1080 test');
is( $i->body, 'test', '-b2' );

