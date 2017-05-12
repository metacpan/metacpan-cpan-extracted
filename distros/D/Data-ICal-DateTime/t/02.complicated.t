use strict;

use Test::More tests => 7;


use Data::ICal::DateTime;
use DateTime;
use DateTime::Set;
use DateTime::TimeZone;

my $cal;
ok($cal = Data::ICal->new( filename => 't/ics/meeting.ics'), "parse meetings ics");


my $date1 = DateTime->new( year => 2005, month => 8, day => 1 );
my $date2 = DateTime->new( year => 2005, month => 10, day => 27 );
my $span  = DateTime::Span->from_datetimes( start => $date1, end => $date2 );

# $set->set_time_zone('Europe/London');


my @events;
@events = $cal->events;
is (@events, 2, "2 total events");


@events = sort { $a->start->epoch <=> $b->start->epoch }$cal->events($span);
is (@events, 4, "4 exploded events");

is($events[0]->summary, "London.pm social", "Got social");
is($events[1]->summary, "London.pm Heretics social", "Got Heretics social");
is($events[2]->summary, "London.pm social", "Got social");
is($events[3]->summary, "London.pm social", "Got social");

