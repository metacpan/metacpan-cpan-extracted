use strict;

use Test::More tests => 27;


use Data::ICal::DateTime;
use DateTime;
use DateTime::Set;
use DateTime::TimeZone;

# check the import stuff
ok(Data::ICal->can('events'),"Events");
for (qw(start end duration summary description url recurrence explode is_in _normalise)) {
    ok(Data::ICal::Entry::Event->can($_),"Can $_");
}


my $cal;
ok($cal = Data::ICal->new( filename => 't/ics/test.ics'), "parse test ics");


my $date1 = DateTime->new( year => 2005, month => 6, day => 27 );
my $date2 = DateTime->new( year => 2005, month => 10, day => 27 );
my $set   = DateTime::Span->from_datetimes( start => $date1, end => $date2 );

# $set->set_time_zone('Europe/London');

my @events;
@events = $cal->events;
is (@events, 128, "128 total events");

my ($orig_norm, $orig_recur);
for (@events) {
    if ( $_->summary eq 'Potential Alternative London.pm social meet' ) {
        $orig_norm = $_;
    } elsif ( $_->summary eq 'London.pm tech meet') {
        $orig_recur = $_;
    }
}


@events = grep { $_->is_in($set) } @events;
is(@events, 10, "10 eligible events");


@events = $cal->events($set);
is(@events, 15, "15 events if you explode just recurring events");


my ($munged_norm, $munged_recur);
for (@events) {
    if ( $_->summary eq 'Potential Alternative London.pm social meet' ) {
        $munged_norm = $_;
    } elsif ( $_->summary eq 'London.pm tech meet') {          
        $munged_recur = $_;
    }
}



@events = $cal->events($set,'day');
is(@events, 36, "36 events if you explode multi day events to multiple single day events");

ok($orig_norm, "Found normal event");
ok($orig_recur, "Found recurring event");
ok($munged_norm, "Found munged normal event");
ok($munged_recur, "Found munged recurring event");

ok($orig_norm->duration,"Got a duration in the normal one");
ok(!$orig_norm->end,"Not got an end in the normal one");
ok(!$munged_norm->duration,"Not got a duration in the munged one");
ok($munged_norm->end,"Got an end in the munged one");



ok($orig_recur->recurrence,"Got a recurrence in the normal one");
ok(!$munged_recur->recurrence,"Not got a recurrence in the munged one");
ok($munged_recur->end,"Got an end in the munged one");

