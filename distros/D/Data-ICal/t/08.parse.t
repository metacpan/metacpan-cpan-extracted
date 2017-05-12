#!/usr/bin/perl -w

use warnings;
use strict;

use constant TESTS_IN_TEST_CALENDAR => 16;
use Test::More tests => 9 + 3 * TESTS_IN_TEST_CALENDAR;
use Test::LongString;
use Test::NoWarnings; # this catches our warnings like setting unknown properties

BEGIN { use_ok('Data::ICal') }



my $cal;
$cal = Data::ICal->new(filename => 't/ics/nonexistent.ics');

ok((not $cal), "Caught no file death");

$cal = Data::ICal->new(filename => 't/ics/badlyformed.ics'); 
ok((not $cal), "Caught badly formed ics file death"); 

$cal = Data::ICal->new(filename => 't/ics/noversion.ics');
ok((not $cal), "rejected calendar without required version property"); 

$cal = Data::ICal->new(filename => 't/ics/test.ics');

isa_ok($cal, 'Data::ICal');

test_calendar($cal);

my $data = $cal->as_string;
like($data, qr/^BEGIN:VCALENDAR/, "looks like a calendar");

my $roundtripped_from_data_cal = Data::ICal->new(data => $data);
isa_ok($roundtripped_from_data_cal, 'Data::ICal');

test_calendar($roundtripped_from_data_cal);

SKIP: {
    my $CAL_FILENAME = "t/ics/out.ics";
    skip "Can't create $CAL_FILENAME: $!", 1 + TESTS_IN_TEST_CALENDAR unless open my $fh,'>', $CAL_FILENAME;
    print $fh $cal->as_string;
    close $fh;

    my $roundtripped_cal = Data::ICal->new(filename => $CAL_FILENAME);
    isa_ok($roundtripped_cal, 'Data::ICal');

    test_calendar($roundtripped_cal);

    unlink $CAL_FILENAME;
}

sub test_calendar {
    my $s = shift;
    is($s->ical_entry_type, 'VCALENDAR', "Is a VCALENDAR");
    my $id = $s->property('prodid')->[0]->value;
    my $name = $s->property('x-wr-calname')->[0]->value;
    is($id,'Data::ICal test', 'Got id');
    is($name,'Data::ICal test calendar', 'Got name');

    my @entries = @{$s->entries};
    is(@entries,2,"Correct number of entries");
    
    my ($event, $timezone);

    for (@entries) {
        if ( $_->ical_entry_type eq 'VEVENT' ) {
            $event = $_;
        } elsif ( $_->ical_entry_type eq 'VTIMEZONE' ) {
            $timezone = $_;
        }
    }    
    undef(@entries);

    # Event 
    isa_ok($event, 'Data::ICal::Entry::Event');
    is($event->property('summary')->[0]->value, 'Data::ICal release party,other things with slash\es');
    is($event->property('location')->[0]->value, 'The Restaurant at the End of the Universe', 'Correct location');
    is($event->property('url')->[0]->value, 'http://www.bestpractical.com', 'Correct URL');
    is($event->property('url')->[0]->parameters->{VALUE}, 'URI', 'Got parameter');

    # check sub entries
    @entries = @{$event->entries};
    is(@entries, 1, "Got sub entries");
    isa_ok($entries[0],'Data::ICal::Entry::Alarm::Audio');
    undef(@entries);

    # TimeZone
    isa_ok($timezone, 'Data::ICal::Entry::TimeZone');
    is($timezone->property('tzid')->[0]->value, 'Europe/London', 'Got TimeZone ID');
    
    # check daylight and standard settings
    @entries = @{$timezone->entries};
    is(@entries, 6, 'Got Daylight/Standard Entries');
    is( grep( ($_->ical_entry_type eq 'DAYLIGHT'), @entries), 3, '3 DAYLIGHT');
    is( grep( ($_->ical_entry_type eq 'STANDARD'), @entries), 3, '3 STANDARD');
}
