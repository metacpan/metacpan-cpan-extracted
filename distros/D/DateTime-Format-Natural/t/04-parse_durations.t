#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use DateTime::Format::Natural;
use DateTime::Format::Natural::Lang::EN;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @absolute = (
    { 'monday to friday' => [ '20.11.2006 00:00:00', '24.11.2006 00:00:00' ] },
    { 'march to august'  => [ '01.03.2006 00:00:00', '01.08.2006 00:00:00' ] },
    { '1999 to 2006'     => [ '01.01.1999 00:00:00', '01.01.2006 00:00:00' ] },
);

my @combined = (
    { 'first day of 2009 to last day of 2009' => [ '01.01.2009 00:00:00', '31.12.2009 00:00:00' ] },
    { 'first day of may to last day of may'   => [ '01.05.2006 00:00:00', '31.05.2006 00:00:00' ] },
    { 'first to last day of 2008'             => [ '01.01.2008 00:00:00', '31.12.2008 00:00:00' ] },
    { 'first to last day of september'        => [ '01.09.2006 00:00:00', '30.09.2006 00:00:00' ] },
);

my @relative = (
    { '1999-12-31 to tomorrow'                         => [ '31.12.1999 00:00:00',     '25.11.2006 00:00:00'     ] },
    { 'now to 2010-01-01'                              => [ '24.11.2006 01:13:08',     '01.01.2010 00:00:00'     ] },
    { '2009-03-10 {at} 9:00{sec} to 11:00{sec}'        => [ '10.03.2009 09:00:{sec}',  '10.03.2009 11:00:{sec}'  ] },
    { '26 oct {at} 10:00{sec}{ }am to 11:00{sec}{ }am' => [ '26.10.2006 10:00:{sec}',  '26.10.2006 11:00:{sec}'  ] },
    { 'jan 1 to 2'                                     => [ '01.01.2006 00:00:00',     '02.01.2006 00:00:00'     ] },
    { '16:00{sec} nov 6 to 17:00{sec}'                 => [ '06.11.2006 16:00:{sec}',  '06.11.2006 17:00:{sec}'  ] },
    { 'may 2nd to 5th'                                 => [ '02.05.2006 00:00:00',     '05.05.2006 00:00:00'     ] },
    { '100th day to 200th'                             => [ '10.04.2006 00:00:00',     '19.07.2006 00:00:00'     ] },
    { '6{min_sec}{ }am dec 5 to 7{min_sec}{ }am'       => [ '05.12.2006 06:{min_sec}', '05.12.2006 07:{min_sec}' ] },
    { '30th to 31st dec'                               => [ '30.12.2006 00:00:00',     '31.12.2006 00:00:00'     ] },
    { '30th to dec 31st'                               => [ '30.12.2006 00:00:00',     '31.12.2006 00:00:00'     ] },
    { '21:00 to mar 3 22:00'                           => [ '03.03.2006 21:00:00',     '03.03.2006 22:00:00'     ] },
    { '21:00 to 22:00 mar 3'                           => [ '03.03.2006 21:00:00',     '03.03.2006 22:00:00'     ] },
    { '10th to 20th day'                               => [ '10.01.2006 00:00:00',     '20.01.2006 00:00:00'     ] },
    { '1/3 to 2/3'                                     => [ '03.01.2006 00:00:00',     '03.02.2006 00:00:00'     ] },
    { '2/3 to in 1 week'                               => [ '03.02.2006 00:00:00',     '01.12.2006 01:13:08'     ] },
    { '3/3 {at} 21:00{sec} to in 5 days'               => [ '03.03.2006 21:00:{sec}',  '29.11.2006 01:13:08'     ] },
    { 'for 4 seconds'                                  => [ '24.11.2006 01:13:08',     '24.11.2006 01:13:12'     ] },
    { 'for 4 minutes'                                  => [ '24.11.2006 01:13:08',     '24.11.2006 01:17:08'     ] },
    { 'for 4 hours'                                    => [ '24.11.2006 01:13:08',     '24.11.2006 05:13:08'     ] },
    { 'for 4 days'                                     => [ '24.11.2006 01:13:08',     '28.11.2006 01:13:08'     ] },
    { 'for 4 weeks'                                    => [ '24.11.2006 01:13:08',     '22.12.2006 01:13:08'     ] },
    { 'for 4 months'                                   => [ '24.11.2006 01:13:08',     '24.03.2007 01:13:08'     ] },
    { 'for 4 years'                                    => [ '24.11.2006 01:13:08',     '24.11.2010 01:13:08'     ] },
# from to relative category
    { 'jan 1st to 2',                                  => [ '01.01.2006 00:00:00',     '02.01.2006 00:00:00'     ] },
    { 'jan 1 to 2nd',                                  => [ '01.01.2006 00:00:00',     '02.01.2006 00:00:00'     ] },
    { '26 oct {at} 10:00{sec} to 11{min_sec}{ }am',    => [ '26.10.2006 10:00:{sec}',  '26.10.2006 11:{min_sec}' ] },
    { '26 oct {at} 10{min_sec}{ }am to 11:00{sec}',    => [ '26.10.2006 10:{min_sec}', '26.10.2006 11:00:{sec}'  ] },
);

_run_tests(160, [ [ \@absolute ], [ \@combined ], [ \@relative ] ], \&compare);

sub compare
{
    my $aref = shift;

    my $timespan_sep = $DateTime::Format::Natural::Lang::EN::timespan{literal};

    foreach my $href (@$aref) {
        my @entries;
        my $key = (keys %$href)[0];
        if ($key =~ /$timespan_sep/) {
            my @strings = split /\s $timespan_sep \s/x, $key;
            my %entries = (
                from => [ $time_entries->($strings[0], $href->{$key}[0]) ],
                to   => [ $time_entries->($strings[1], $href->{$key}[1]) ],
            );
            foreach my $from (@{$entries{from}}) {
                foreach my $to (@{$entries{to}}) {
                    push @entries, [ "$from->[0] $timespan_sep $to->[0]", [ $from->[1], $to->[1] ] ],
                }
            }
        }
        else {
            @entries = ([ $key, $href->{$key} ]);
        }
        foreach my $entry (@entries) {
            foreach my $string ($case_strings->($entry->[0])) {
                compare_strings($string, $entry->[1]);
            }
        }
    }
}

sub compare_strings
{
    my ($string, $result) = @_;

    my $parser = DateTime::Format::Natural->new;
    $parser->_set_datetime(\%time);

    my @dt = $parser->parse_datetime_duration($string);

    my $pass = true;
    foreach my $i (0..$#dt) {
        $pass &= _result_string($dt[$i]) eq $result->[$i];
    }

    if ($parser->success && $pass && @dt == 2) {
        ok($pass, _message($string));
    }
    else {
        fail(_message($string));
    }
}
