use strict;

use Test::More tests => 8;


use Data::ICal::DateTime;
use DateTime;
use DateTime::Set;
use DateTime::TimeZone;

my $cal;
ok($cal = Data::ICal->new( filename => 't/ics/recurrence-id.ics'), "parse recurrence-id ics");


my $date1 = DateTime->new( year => 2005, month => 8, day => 1 );
my $date2 = DateTime->new( year => 2005, month => 10, day => 27 );
my $span  = DateTime::Span->from_datetimes( start => $date1, end => $date2 );

# $set->set_time_zone('Europe/London');


my @events;
@events = $cal->events;
is (@events, 2, "2 total events");


@events = sort { $a->start->epoch <=> $b->start->epoch }$cal->events($span);
is (@events, 4, "4 exploded events");

is($events[0]->summary, "Test event", "Test Event");
is($events[1]->summary, "This is on a Tuesday", "Got note");
is($events[2]->summary, "Test event", "Test Event");
is($events[3]->summary, "Test event", "Test Event");

is($events[0]->uid, $events[1]->uid, "UIDs the same");
