use strict;


use Test::More tests => 24;


use Data::ICal::DateTime;
use Data::ICal::Entry::Event;
use DateTime;
use DateTime::Set;
use DateTime::TimeZone;

my $cal;
ok($cal = Data::ICal->new( filename => 't/ics/all_day.ics'), "parse all_day ics");


my $date1 = DateTime->new( year => 2005, month => 8, day => 1, hour => 23, minute => 59, second => 59 );
my $date2 = DateTime->new( year => 2005, month => 10, day => 27, hour => 23, minute => 59, second => 59);

my @events = $cal->events;
is (@events, 2, "2 total events");
my ($e1, $e2) = @events;

is ($e1->summary,"Event 1");
is ($e2->summary,"Event 2");

is("".$e1->end, "".$date1, "E1's end is the correct date");
is("".$e2->end, "".$date1, "E2's end is the correct date");
is($e1->all_day,0,   "E1 is not all day");
is($e2->all_day,1,   "E2 is all day");

$e1->end($date2);
$e2->end($date2);

is("".$e1->end, "".$date2, "E1's end is the correct new date");
is("".$e2->end, "".$date2, "E2's end is the correct new date");
is($e1->all_day, 0,  "E1 is not all day");
is($e2->all_day, 1,  "E2 is all day");

$e2->all_day(0);
is($e2->all_day, 0,  "E2 is not all day");
is("".$e2->end, "".$date2, "E2's end is the correct new date");
$e2->all_day(1);
is($e2->all_day, 1,  "E2 is now all day again ");
is("".$e2->end, "".$date2, "E2's end is the correct new date");
	
$e1->end($date1);
$e2->end($date1);

my @e1 = $e1->split_up('hour');
my @e2 = $e2->split_up('hour');

is(@e1, 14, "e1 14 exploded");
is(@e2, 14, "e2 14 exploded");
is($e1[0]->all_day, 0, "e1 exploded is not all day");
is($e2[0]->all_day, 0, "e2 exploded is all day");
is($e1[0]->original->all_day, 0, "e1 exploded wasn't originally all day");
is($e2[0]->original->all_day, 1, "e2 exploded was originally all day");


# test setting all day without end 
my $new = Data::ICal::Entry::Event->new();

my $new_date = $date1->clone->truncate( to => 'day' );
$new->start($new_date);
$new->all_day(1);

is ($new->all_day, 1, "New is all day");
is ("".$new->end, "".$date1, "New end is the same as start");
