#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use Test::MockTime qw(set_fixed_time);
use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my $date = join '.', map $time{$_}, qw(day month year);
my $time = join ':', map $time{$_}, qw(hour minute second);

set_fixed_time(
    "$date $time",
    '%d.%m.%Y %H:%M:%S',
);

my @simple = (
    { 'friday'             => '24.11.2006 00:00:00'     },
    { 'monday'             => '27.11.2006 00:00:00'     },
    { 'thursday morning'   => '30.11.2006 08:00:00'     },
    { 'thursday afternoon' => '30.11.2006 14:00:00'     },
    { 'thursday evening'   => '30.11.2006 20:00:00'     },
    { 'november'           => '01.11.2007 00:00:00'     },
    { 'january'            => '01.01.2007 00:00:00'     },
    { 'last january'       => '01.01.2005 00:00:00'     },
    { 'next january'       => '01.01.2007 00:00:00'     },
    { 'next friday'        => '01.12.2006 00:00:00'     },
    { 'last friday'        => '17.11.2006 00:00:00'     },
    { '00:30:15'           => '25.11.2006 00:30:15'     },
    { '00:00{sec}'         => '25.11.2006 00:00:{sec}'  },
    { '12{min_sec}{ }am'   => '25.11.2006 00:{min_sec}' },
    { '12:30{sec}{ }am'    => '25.11.2006 00:30:{sec}'  },
    { '4{min_sec}{ }pm'    => '24.11.2006 16:{min_sec}' },
    { '4:20{sec}{ }pm'     => '24.11.2006 16:20:{sec}'  },
    { '12:56:06{ }am'      => '25.11.2006 00:56:06'     },
    { '12:56:06{ }pm'      => '24.11.2006 12:56:06'     },
);

my @combined = (
    { '4th february'                   => '04.02.2007 00:00:00'     },
    { 'november 3rd'                   => '03.11.2007 00:00:00'     },
    { 'sunday {at} 11:00{sec}'         => '26.11.2006 11:00:{sec}'  },
    { 'sunday {at} 11:00{sec}{ }am'    => '26.11.2006 11:00:{sec}'  },
    { 'sunday {at} 11:00{sec}{ }pm'    => '26.11.2006 23:00:{sec}'  },
    { 'monday {at} 8{min_sec}'         => '27.11.2006 08:{min_sec}' },
    { 'monday {at} 8{min_sec}{ }am'    => '27.11.2006 08:{min_sec}' },
    { 'tuesday {at} 8{min_sec}{ }pm'   => '28.11.2006 20:{min_sec}' },
    { 'wednesday {at} 4{min_sec}{ }pm' => '29.11.2006 16:{min_sec}' },
    { 'friday {at} 03:00{sec}{ }am'    => '24.11.2006 03:00:{sec}'  },
    { 'friday {at} 03:00{sec}{ }pm'    => '24.11.2006 15:00:{sec}'  },
    { 'monday {at} 03:00{sec}{ }am'    => '27.11.2006 03:00:{sec}'  },
    { 'monday {at} 03:00{sec}{ }pm'    => '27.11.2006 15:00:{sec}'  },
    { '4:00{sec} thu'                  => '30.11.2006 04:00:{sec}'  },
    { '4{min_sec}{ }am thu'            => '30.11.2006 04:{min_sec}' },
    { '4{min_sec}{ }pm thu'            => '30.11.2006 16:{min_sec}' },
    { '4:00{sec} on thu'               => '30.11.2006 04:00:{sec}'  },
    { '4{min_sec}{ }am on thu'         => '30.11.2006 04:{min_sec}' },
    { '4{min_sec}{ }pm on thu'         => '30.11.2006 16:{min_sec}' },
);

my @formatted = (
    { '1/3'   => '03.01.2007 00:00:00' },
    { '12/24' => '24.12.2006 00:00:00' },
);

_run_tests(164, [ [ \@simple ], [ \@combined ], [ \@formatted ] ], \&compare);

sub compare
{
    my $aref = shift;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        foreach my $entry ($time_entries->($key, $href->{$key})) {
            foreach my $string ($case_strings->($entry->[0])) {
                compare_strings($string, $entry->[1]);
            }
        }
    }
}

sub compare_strings
{
    my ($string, $result) = @_;

    my $parser = DateTime::Format::Natural->new(prefer_future => true);
    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
