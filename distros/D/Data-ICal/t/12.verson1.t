#!/usr/bin/perl -w

use warnings;
use strict;

use constant TESTS_IN_TEST_CALENDAR => 6;
use Test::More tests => 10 + 3 * TESTS_IN_TEST_CALENDAR;
use Test::LongString;
use Test::Warn;

BEGIN { use_ok('Data::ICal') }

my $cal;

warnings_are { $cal = Data::ICal->new(filename => 't/ics/version1.ics') }
    [ {carped => "Unknown property for Data::ICal::Entry::Event: dcreated"},
    {carped => "Unknown property for Data::ICal::Entry::Event: malarm"} ],
    "Got a warning for fake property set";
ok((not $cal), "rejected calendar with version property value 1.0");

warnings_are { $cal = Data::ICal->new(filename => 't/ics/test.ics', vcal10 => 1) }
    [ {carped => "Unknown property for Data::ICal::Entry::Event: duration"} ],
    "Got a warning for fake property set";
ok((not $cal), "rejected calendar with version property value 2.0");

require Test::NoWarnings;

$cal = Data::ICal->new(filename => 't/ics/version1.ics', vcal10 => 1);

isa_ok($cal, 'Data::ICal');

test_calendar($cal);

my $data = $cal->as_string;
like($data, qr/^BEGIN:VCALENDAR/, "looks like a calendar");

my $roundtripped_from_data_cal = Data::ICal->new(data => $data, vcal10 => 1);
isa_ok($roundtripped_from_data_cal, 'Data::ICal');

test_calendar($roundtripped_from_data_cal);

SKIP: {
    my $CAL_FILENAME = "t/ics/out.ics";
    skip "Can't create $CAL_FILENAME: $!", 1 + TESTS_IN_TEST_CALENDAR unless open my $fh,'>', $CAL_FILENAME;
    print $fh $cal->as_string;
    close $fh;

    my $roundtripped_cal = Data::ICal->new(filename => $CAL_FILENAME, vcal10 => 1);
    isa_ok($roundtripped_cal, 'Data::ICal');

    test_calendar($roundtripped_cal);

    unlink $CAL_FILENAME;
}

Test::NoWarnings::had_no_warnings();

sub test_calendar {
    my $s = shift;
    is($s->ical_entry_type, 'VCALENDAR', "Is a VCALENDAR");
    my $id = $s->property('prodid')->[0]->value;
    is($id,'-//Mirapoint Calendar', 'Got id');

    my @entries = @{$s->entries};
    is(@entries,1,"Correct number of entries");

    my $event;

    for (@entries) {
        if ( $_->ical_entry_type eq 'VEVENT' ) {
            $event = $_;
        }
    }
    undef(@entries);

    # Event
    isa_ok($event, 'Data::ICal::Entry::Event');
    is($event->property('summary')->[0]->value, 'cal1');

    # check sub entries
    @entries = @{$event->entries};
    is(@entries, 0, "Got no sub entries");
    undef(@entries);
}
