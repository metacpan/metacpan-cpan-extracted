#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use DateTime::TimeZone;
use Test::More;

my @simple = (
    { 'now'                          => [ '24.11.2006 01:13:08',     unaltered ] },
    { 'today'                        => [ '24.11.2006 00:00:00',     truncated ] },
    { 'yesterday'                    => [ '23.11.2006 00:00:00',     truncated ] },
    { 'tomorrow'                     => [ '25.11.2006 00:00:00',     truncated ] },
    { 'morning'                      => [ '24.11.2006 08:00:00',     truncated ] },
    { 'afternoon'                    => [ '24.11.2006 14:00:00',     truncated ] },
    { 'evening'                      => [ '24.11.2006 20:00:00',     truncated ] },
    { 'noon'                         => [ '24.11.2006 12:00:00',     truncated ] },
    { 'midnight'                     => [ '24.11.2006 00:00:00',     truncated ] },
    { 'yesterday {at} noon'          => [ '23.11.2006 12:00:00',     truncated ] },
    { 'yesterday {at} midnight'      => [ '23.11.2006 00:00:00',     truncated ] },
    { 'today {at} noon'              => [ '24.11.2006 12:00:00',     truncated ] },
    { 'today {at} midnight'          => [ '24.11.2006 00:00:00',     truncated ] },
    { 'tomorrow {at} noon'           => [ '25.11.2006 12:00:00',     truncated ] },
    { 'tomorrow {at} midnight'       => [ '25.11.2006 00:00:00',     truncated ] },
    { 'this morning'                 => [ '24.11.2006 08:00:00',     truncated ] },
    { 'this afternoon'               => [ '24.11.2006 14:00:00',     truncated ] },
    { 'this evening'                 => [ '24.11.2006 20:00:00',     truncated ] },
    { 'yesterday morning'            => [ '23.11.2006 08:00:00',     truncated ] },
    { 'yesterday afternoon'          => [ '23.11.2006 14:00:00',     truncated ] },
    { 'yesterday evening'            => [ '23.11.2006 20:00:00',     truncated ] },
    { 'today morning'                => [ '24.11.2006 08:00:00',     truncated ] },
    { 'today afternoon'              => [ '24.11.2006 14:00:00',     truncated ] },
    { 'today evening'                => [ '24.11.2006 20:00:00',     truncated ] },
    { 'tomorrow morning'             => [ '25.11.2006 08:00:00',     truncated ] },
    { 'tomorrow afternoon'           => [ '25.11.2006 14:00:00',     truncated ] },
    { 'tomorrow evening'             => [ '25.11.2006 20:00:00',     truncated ] },
    { 'march'                        => [ '01.03.2006 00:00:00',     truncated ] },
    { '4th february'                 => [ '04.02.2006 00:00:00',     truncated ] },
    { 'november 3rd'                 => [ '03.11.2006 00:00:00',     truncated ] },
    { 'saturday'                     => [ '25.11.2006 00:00:00',     truncated ] },
    { 'last wednesday'               => [ '15.11.2006 00:00:00',     truncated ] },
    { 'last june'                    => [ '01.06.2005 00:00:00',     truncated ] },
    { 'last month'                   => [ '01.10.2006 00:00:00',     truncated ] },
    { 'last year'                    => [ '01.01.2005 00:00:00',     truncated ] },
    { 'next friday'                  => [ '01.12.2006 00:00:00',     truncated ] },
    { 'next october'                 => [ '01.10.2007 00:00:00',     truncated ] },
    { 'next month'                   => [ '01.12.2006 00:00:00',     truncated ] },
    { 'next year'                    => [ '01.01.2007 00:00:00',     truncated ] },
    { 'this thursday'                => [ '23.11.2006 00:00:00',     truncated ] },
    { 'this month'                   => [ '01.11.2006 00:00:00',     truncated ] },
    { '5{min_sec}{ }am'              => [ '24.11.2006 05:{min_sec}', truncated ] },
    { '5{min_sec}{ }am yesterday'    => [ '23.11.2006 05:{min_sec}', truncated ] },
    { '5{min_sec}{ }am today'        => [ '24.11.2006 05:{min_sec}', truncated ] },
    { '5{min_sec}{ }am tomorrow'     => [ '25.11.2006 05:{min_sec}', truncated ] },
    { '4{min_sec}{ }pm'              => [ '24.11.2006 16:{min_sec}', truncated ] },
    { '4{min_sec}{ }pm yesterday'    => [ '23.11.2006 16:{min_sec}', truncated ] },
    { '4{min_sec}{ }pm today'        => [ '24.11.2006 16:{min_sec}', truncated ] },
    { '4{min_sec}{ }pm tomorrow'     => [ '25.11.2006 16:{min_sec}', truncated ] },
    { 'sunday {at} 11:00{sec}'       => [ '26.11.2006 11:00:{sec}',  truncated ] },
    { 'mon {at} 2:35{sec}'           => [ '20.11.2006 02:35:{sec}',  truncated ] },
    { '13:45{sec}'                   => [ '24.11.2006 13:45:{sec}',  truncated ] },
    { 'may 2002'                     => [ '01.05.2002 00:00:00',     truncated ] },
    { '2nd monday'                   => [ '13.11.2006 00:00:00',     truncated ] },
    { '100th day'                    => [ '10.04.2006 00:00:00',     truncated ] },
    { '6 in the morning'             => [ '24.11.2006 06:00:00',     truncated ] },
    { 'sat 7 in the evening'         => [ '25.11.2006 19:00:00',     truncated ] },
    { 'this second'                  => [ '24.11.2006 01:13:08',     truncated ] },
    { 'yesterday {at} 4:00{sec}'     => [ '23.11.2006 04:00:{sec}',  truncated ] },
    { 'last january'                 => [ '01.01.2005 00:00:00',     truncated ] },
    { 'last friday {at} 20:00{sec}'  => [ '17.11.2006 20:00:{sec}',  truncated ] },
    { 'tomorrow {at} 6:45{sec}{ }pm' => [ '25.11.2006 18:45:{sec}',  truncated ] },
    { 'yesterday afternoon'          => [ '23.11.2006 14:00:00',     truncated ] },
    { 'thursday last week'           => [ '16.11.2006 00:00:00',     truncated ] },
);

_run_tests(260, [ [ \@simple ] ], \&compare);

sub compare
{
    my $aref = shift;

    foreach my $tz ('Asia/Tokyo', DateTime::TimeZone->new(name => 'Asia/Tokyo')) {
        foreach my $href (@$aref) {
            my $key = (keys %$href)[0];
            foreach my $entry ($time_entries->($key, $href->{$key})) {
                foreach my $string ($case_strings->($entry->[0])) {
                    compare_strings($string, $entry->[1], $tz);
                }
            }
        }
    }
}

sub compare_strings
{
    my ($string, $result, $tz) = @_;

    my $parser = DateTime::Format::Natural->new(time_zone => 'UTC');
    $parser->_set_datetime(\%time, $tz);

    my $dt = $parser->parse_datetime($string);

    if ($parser->success && $parser->_get_truncated == $result->[1]) {
        is(_result_string($dt), $result->[0], _message($string));
    }
    else {
        fail(_message($string));
    }
}
