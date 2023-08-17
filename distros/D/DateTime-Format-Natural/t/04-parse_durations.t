#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use DateTime::Format::Natural;
use DateTime::Format::Natural::Lang::EN;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @absolute = (
    { 'monday to friday' => [ [ '20.11.2006 00:00:00', truncated ], [ '24.11.2006 00:00:00', truncated ] ] },
    { 'march to august'  => [ [ '01.03.2006 00:00:00', truncated ], [ '01.08.2006 00:00:00', truncated ] ] },
    { '1999 to 2006'     => [ [ '01.01.1999 00:00:00', truncated ], [ '01.01.2006 00:00:00', truncated ] ] },
);

my @combined = (
    { 'first day of 2009 to last day of 2009' => [ [ '01.01.2009 00:00:00', truncated ], [ '31.12.2009 00:00:00', truncated ] ] },
    { 'first day of may to last day of may'   => [ [ '01.05.2006 00:00:00', truncated ], [ '31.05.2006 00:00:00', truncated ] ] },
    { 'first to last day of 2008'             => [ [ '01.01.2008 00:00:00', truncated ], [ '31.12.2008 00:00:00', truncated ] ] },
    { 'first to last day of september'        => [ [ '01.09.2006 00:00:00', truncated ], [ '30.09.2006 00:00:00', truncated ] ] },
);

my @relative = (
    { '1999-12-31 to tomorrow'                         => [ [ '31.12.1999 00:00:00',     truncated ], [ '25.11.2006 00:00:00',     truncated ] ] },
    { 'now to 2010-01-01'                              => [ [ '24.11.2006 01:13:08',     unaltered ], [ '01.01.2010 00:00:00',     truncated ] ] },
    { '2009-03-10 {at} 9:00{sec} to 11:00{sec}'        => [ [ '10.03.2009 09:00:{sec}',  truncated ], [ '10.03.2009 11:00:{sec}',  truncated ] ] },
    { '26 oct {at} 10:00{sec}{ }am to 11:00{sec}{ }am' => [ [ '26.10.2006 10:00:{sec}',  truncated ], [ '26.10.2006 11:00:{sec}',  truncated ] ] },
    { 'jan 1 to 2'                                     => [ [ '01.01.2006 00:00:00',     truncated ], [ '02.01.2006 00:00:00',     truncated ] ] },
    { '16:00{sec} nov 6 to 17:00{sec}'                 => [ [ '06.11.2006 16:00:{sec}',  truncated ], [ '06.11.2006 17:00:{sec}',  truncated ] ] },
    { 'may 2nd to 5th'                                 => [ [ '02.05.2006 00:00:00',     truncated ], [ '05.05.2006 00:00:00',     truncated ] ] },
    { '100th day to 200th'                             => [ [ '10.04.2006 00:00:00',     truncated ], [ '19.07.2006 00:00:00',     truncated ] ] },
    { '6{min_sec}{ }am dec 5 to 7{min_sec}{ }am'       => [ [ '05.12.2006 06:{min_sec}', truncated ], [ '05.12.2006 07:{min_sec}', truncated ] ] },
    { '30th to 31st dec'                               => [ [ '30.12.2006 00:00:00',     truncated ], [ '31.12.2006 00:00:00',     truncated ] ] },
    { '30th to dec 31st'                               => [ [ '30.12.2006 00:00:00',     truncated ], [ '31.12.2006 00:00:00',     truncated ] ] },
    { '21:00 to mar 3 22:00'                           => [ [ '03.03.2006 21:00:00',     truncated ], [ '03.03.2006 22:00:00',     truncated ] ] },
    { '21:00 to 22:00 mar 3'                           => [ [ '03.03.2006 21:00:00',     truncated ], [ '03.03.2006 22:00:00',     truncated ] ] },
    { '10th to 20th day'                               => [ [ '10.01.2006 00:00:00',     truncated ], [ '20.01.2006 00:00:00',     truncated ] ] },
    { '1/3 to 2/3'                                     => [ [ '03.01.2006 00:00:00',     truncated ], [ '03.02.2006 00:00:00',     truncated ] ] },
    { '2/3 to in 1 week'                               => [ [ '03.02.2006 00:00:00',     truncated ], [ '01.12.2006 01:13:08',     unaltered ] ] },
    { '3/3 {at} 21:00{sec} to in 5 days'               => [ [ '03.03.2006 21:00:{sec}',  truncated ], [ '29.11.2006 01:13:08',     unaltered ] ] },
    { 'for 4 seconds'                                  => [ [ '24.11.2006 01:13:08',     unaltered ], [ '24.11.2006 01:13:12',     unaltered ] ] },
    { 'for 4 minutes'                                  => [ [ '24.11.2006 01:13:08',     unaltered ], [ '24.11.2006 01:17:08',     unaltered ] ] },
    { 'for 4 hours'                                    => [ [ '24.11.2006 01:13:08',     unaltered ], [ '24.11.2006 05:13:08',     unaltered ] ] },
    { 'for 4 days'                                     => [ [ '24.11.2006 01:13:08',     unaltered ], [ '28.11.2006 01:13:08',     unaltered ] ] },
    { 'for 4 weeks'                                    => [ [ '24.11.2006 01:13:08',     unaltered ], [ '22.12.2006 01:13:08',     unaltered ] ] },
    { 'for 4 months'                                   => [ [ '24.11.2006 01:13:08',     unaltered ], [ '24.03.2007 01:13:08',     unaltered ] ] },
    { 'for 4 years'                                    => [ [ '24.11.2006 01:13:08',     unaltered ], [ '24.11.2010 01:13:08',     unaltered ] ] },
# from to relative category
    { 'jan 1st to 2',                                  => [ [ '01.01.2006 00:00:00',     truncated ], [ '02.01.2006 00:00:00',     truncated ] ] },
    { 'jan 1 to 2nd',                                  => [ [ '01.01.2006 00:00:00',     truncated ], [ '02.01.2006 00:00:00',     truncated ] ] },
    { '26 oct {at} 10:00{sec} to 11{min_sec}{ }am',    => [ [ '26.10.2006 10:00:{sec}',  truncated ], [ '26.10.2006 11:{min_sec}', truncated ] ] },
    { '26 oct {at} 10{min_sec}{ }am to 11:00{sec}',    => [ [ '26.10.2006 10:{min_sec}', truncated ], [ '26.10.2006 11:00:{sec}',  truncated ] ] },
    { '2022-09-01 14:35 to 18',                        => [ [ '01.09.2022 14:35:00',     truncated ], [ '01.09.2022 18:00:00',     truncated ] ] },
    { '2022-09-01 14 to 18:35',                        => [ [ '01.09.2022 14:00:00',     truncated ], [ '01.09.2022 18:35:00',     truncated ] ] },
    { '9/1 14:35 to 18',                               => [ [ '01.09.2006 14:35:00',     truncated ], [ '01.09.2006 18:00:00',     truncated ] ] },
    { '9/1 14 to 18:35',                               => [ [ '01.09.2006 14:00:00',     truncated ], [ '01.09.2006 18:35:00',     truncated ] ] },
);

_run_tests(164, [ [ \@absolute ], [ \@combined ], [ \@relative ] ], \&compare);

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
                from => [ $time_entries->($strings[0], $href->{$key}[0][0]) ],
                to   => [ $time_entries->($strings[1], $href->{$key}[1][0]) ],
            );
            foreach my $from (@{$entries{from}}) {
                foreach my $to (@{$entries{to}}) {
                    push @entries, [ "$from->[0] $timespan_sep $to->[0]", [ [ $from->[1], $href->{$key}[0][1] ], [ $to->[1], $href->{$key}[1][1] ] ] ],
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

    my $parser = DateTime::Format::Natural->new(format => 'm/d');
    $parser->_set_datetime(\%time);

    my @dt = $parser->parse_datetime_duration($string);
    my @truncated = @{$parser->{truncated_duration}};

    my $pass = true;
    foreach my $i (0..$#dt) {
        $pass &= $truncated[$i] == $result->[$i][1];
        $pass &= _result_string($dt[$i]) eq $result->[$i][0];
    }

    if ($parser->success && $pass && @dt == 2) {
        ok($pass, _message($string));
    }
    else {
        fail(_message($string));
    }
}
