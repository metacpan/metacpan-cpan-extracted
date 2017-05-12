#!/usr/bin/perl
#
# Contributed by: Tatsuhiko Miyagawa <miyagawa@bulknews.net>
#
use strict;
use warnings;
use Data::ICal;
use DateTime;
use DateTime::Format::ISO8601;
use List::Util qw(min max);
use Math::BigInt;

my $axis = 15; # 15 minutes

my @events = map {
    my $cal = Data::ICal->new(filename => $_);
    @{$cal->entries};
} @ARGV;

my $iso8601 = DateTime::Format::ISO8601->new;

my(%dates, %where);

for my $event (@events) {
    next unless $event->ical_entry_type eq 'VEVENT';

    $event->{__dtstart} = $iso8601->parse_datetime( prop($event, 'DTSTART') );
    $event->{__dtend}   = $iso8601->parse_datetime( prop($event, 'DTEND') );

    my $loc = prop($event, 'LOCATION');
    push @{$dates{$event->{__dtstart}->ymd}{$loc}}, $event;
    $where{$loc}++;
}

for my $date (keys %dates) {
    for my $loc (keys %{$dates{$date}}) {
        @{$dates{$date}{$loc}} = sort { $a->{__dtstart} cmp $b->{__dtstart} } @{$dates{$date}{$loc}};
    }

    my @events = values %{$dates{$date}};

    my $start = (sort(map $_->[0]->{__dtstart}, @events))[0];
    my $end   = (sort(map $_->[-1]->{__dtend}, @events))[-1];

    my $unit  = determine_unit(map @$_, @events);

    my $output;
    $output = qq(<h3 class="date-header">) . $start->strftime('%b %d, %Y') . qq(</h3>\n);
    $output .= qq(<table class="timetable">\n<tr><th>Time</th>);

    my $locmap = location_map();
    for my $loc ( sort { $locmap->{$a} <=> $locmap->{$b} } keys %where) {
        $output .= qq(<th class="room">$loc</th>);
    }
    $output .= qq(</tr>\n);

    my $curr = $start->clone;

    my $fill_slots;
    while ($curr < $end) {
        $output .= qq(<tr>);
        if ($curr->delta_ms($start)->minutes % $axis == 0) {
            use integer;
            my $row = $axis / $unit;
            $output .= qq(<td class="hour" rowspan="$row">) . $curr->strftime('%H:%M') . qq(</td>);
        }

        for my $loc ( sort { $locmap->{$a} <=> $locmap->{$b} } keys %where ) {
            my $event_per_loc = $dates{$date}{$loc};
            if ($event_per_loc->[0] && $event_per_loc->[0]->{__dtstart} <= $curr) {
                use integer;
                my $event = shift @$event_per_loc;

                my @stuff = split / \- /, prop($event, 'SUMMARY');
                my $author = pop @stuff if @stuff >= 2;
                my $title  = join " - ", @stuff;

                my $url = prop($event, 'URL');

                my $row  = $event->{__dtend}->delta_ms($event->{__dtstart})->delta_minutes / $unit;
                $output .= qq(<td class="session" rowspan="$row">);
                $output .= qq(<span class="title"><a href="$url">$title</a></span>);
                $output .= qq(<br /><span class="author">$author</span>) if $author;
                $output .= qq(</td>);

                $fill_slots->{$loc} = $row - 1;
            } elsif ($fill_slots->{$loc}) {
                $fill_slots->{$loc}--;
            } else {
                my $next  = $event_per_loc->[0] ? $event_per_loc->[0]->{__dtstart} : $end;
                my $label = $event_per_loc->[0] ? '(break)' : '(empty)';
                my $row  = $next->delta_ms($curr)->delta_minutes / $unit;
                $output .= qq(<td class="empty" rowspan="$row">$label</td>); # break
                $fill_slots->{$loc} = $row - 1;
            }
        }

        $curr->add( minutes => $unit );
        $output .= qq(</tr>\n);
    }
    $output .= qq(</table>\n);

    print $output;
}

sub location_map {
    return {
        'Tsuda Hall' => 0,
        'T101+102'   => 1,
    };
}

sub determine_unit {
    my @events = @_;

    my @dates = sort map { $_->{__dtstart}, $_->{__dtend} } @events;

    my(@diffs, $prev);
    for my $date (@dates) {
        if ($prev) {
            my $diff = $date->delta_ms($prev);
            if ($prev and $diff->delta_minutes) {
                push @diffs, $diff->delta_minutes;
            }
        }

        $prev = $date;
    }

    return Math::BigInt::bgcd(@diffs)->numify;
}

sub prop {
    my($event, $key) = @_;
    my $v = $event->property($key) or return;
    $v->[0]->value;
}

