#!perl
# -*- perl -*-

use DateTime;
use Data::ICal;
use Test::More;

plan tests => 6;

use_ok('DateTime::TimeZone::ICal');

SKIP: {
    skip 'No iCal file supplied', 5 unless @ARGV;

    my $ical = Data::ICal->new(filename => shift);

    isa_ok($ical, 'Data::ICal::Entry');

    my (%tz, @events);

    for my $entry (@{$ical->entries}) {
        my $type = $entry->ical_entry_type;
        if ($type eq 'VTIMEZONE') {
            my ($tzid) = map { $_->value } @{$entry->property('tzid') || []};
            $tz{$tzid} = $entry;
        }
        elsif ($type eq 'VEVENT') {
            push @events, $entry;
        }
    }

    ok(values %tz > 0, 'At least one VTIMEZONE');
    ok(@events > 0, 'At least one VEVENT');

    # get one timezone entry
    my ($k) = sort keys %tz;
    #diag($tz{$k}->as_string);

    my $tz = DateTime::TimeZone::ICal->from_ical_entry($tz{$k});

    my $now = DateTime->now;

    if (isa_ok($tz, 'DateTime::TimeZone::ICal')) {

        #require Data::Dumper;
        #local $Data::Dumper::Indent = 1;
        #diag(Data::Dumper::Dumper($tz));


        diag($tz->standard->[0]->dtstart);
        diag($tz->daylight->[0]->recurrence->min);

    }
    is($tz->is_dst_for_datetime($now), $now->is_dst, 'DST matches');

    diag($tz->offset_for_datetime($now));

    $now->set_time_zone($tz);
    require DateTime::Format::W3CDTF;
    my $dtf = DateTime::Format::W3CDTF->new;
    diag($dtf->format_datetime($now));

    # for my $entry (@{$tz{$k}->entries}) {
    #     my $rrule = $entry->property('rrule')->[0];
    #     warn $rrule->value;
    # }

    #diag($tz{$k}->entries->[0]->properties('rrule')->[0]);
}
