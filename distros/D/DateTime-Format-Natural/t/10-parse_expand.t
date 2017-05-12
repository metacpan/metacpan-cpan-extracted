#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @expanded = (
    { '6am last day'                    => '23.11.2006 06:00:00' },
    { '6pm this day'                    => '24.11.2006 18:00:00' },
    { '18:00 next day'                  => '25.11.2006 18:00:00' },
    { 'last day 6am'                    => '23.11.2006 06:00:00' },
    { 'this day 6pm'                    => '24.11.2006 18:00:00' },
    { 'next day 18:00'                  => '25.11.2006 18:00:00' },
    { '6am last week'                   => '17.11.2006 06:00:00' },
    { '6pm this week'                   => '24.11.2006 18:00:00' },
    { '18:00 next week'                 => '01.12.2006 18:00:00' },
    { 'last week 6am'                   => '17.11.2006 06:00:00' },
    { 'this week 6pm'                   => '24.11.2006 18:00:00' },
    { 'next week 18:00'                 => '01.12.2006 18:00:00' },
    { '1am last month'                  => '01.10.2006 01:00:00' },
    { '1pm this month'                  => '01.11.2006 13:00:00' },
    { '13:00 next month'                => '01.12.2006 13:00:00' },
    { 'last month 1am'                  => '01.10.2006 01:00:00' },
    { 'this month 1pm'                  => '01.11.2006 13:00:00' },
    { 'next month 13:00'                => '01.12.2006 13:00:00' },
    { '5am last year'                   => '01.01.2005 05:00:00' },
    { '5pm this year'                   => '01.01.2006 17:00:00' },
    { '17:00 next year'                 => '01.01.2007 17:00:00' },
    { 'last year 5am'                   => '01.01.2005 05:00:00' },
    { 'this year 5pm'                   => '01.01.2006 17:00:00' },
    { 'next year 17:00'                 => '01.01.2007 17:00:00' },
    { '4am last june'                   => '01.06.2005 04:00:00' },
    { '4pm last june'                   => '01.06.2005 16:00:00' },
    { '16:00 last june'                 => '01.06.2005 16:00:00' },
    { 'next october 10am'               => '01.10.2007 10:00:00' },
    { 'next october 10pm'               => '01.10.2007 22:00:00' },
    { 'next october 22:00'              => '01.10.2007 22:00:00' },
    { '2am tuesday last week'           => '14.11.2006 02:00:00' },
    { '2pm tuesday this week'           => '21.11.2006 14:00:00' },
    { '14:00 tuesday next week'         => '28.11.2006 14:00:00' },
    { 'tuesday last week 2am'           => '14.11.2006 02:00:00' },
    { 'tuesday this week 2pm'           => '21.11.2006 14:00:00' },
    { 'tuesday next week 14:00'         => '28.11.2006 14:00:00' },
    { '3am last week wednesday'         => '15.11.2006 03:00:00' },
    { '3pm this week wednesday'         => '22.11.2006 15:00:00' },
    { '15:00 next week wednesday'       => '29.11.2006 15:00:00' },
    { 'last week wednesday 3am'         => '15.11.2006 03:00:00' },
    { 'this week wednesday 3pm'         => '22.11.2006 15:00:00' },
    { 'next week wednesday 15:00'       => '29.11.2006 15:00:00' },
    { '7am final thursday in april'     => '27.04.2006 07:00:00' },
    { '7pm final thursday in april'     => '27.04.2006 19:00:00' },
    { '19:00 final thursday in april'   => '27.04.2006 19:00:00' },
    { 'last thursday in april 7am'      => '27.04.2006 07:00:00' },
    { 'last thursday in april 7pm'      => '27.04.2006 19:00:00' },
    { 'last thursday in april 19:00'    => '27.04.2006 19:00:00' },
    { '8pm 4th february'                => '04.02.2006 20:00:00' },
    { '2am 11 january last year'        => '11.01.2005 02:00:00' },
    { '2pm 11 january this year'        => '11.01.2006 14:00:00' },
    { '14:00 11 january next year'      => '11.01.2007 14:00:00' },
    { '11 january last year 2am'        => '11.01.2005 02:00:00' },
    { '11 january this year 2pm'        => '11.01.2006 14:00:00' },
    { '11 january next year 14:00'      => '11.01.2007 14:00:00' },
    { '5am 11 january 2 years ago'      => '11.01.2004 05:00:00' },
    { '5pm 11 january 2 years ago'      => '11.01.2004 17:00:00' },
    { '11 january 2 years ago 5am'      => '11.01.2004 05:00:00' },
    { '11 january 2 years ago 5pm'      => '11.01.2004 17:00:00' },
    { '9am 2nd monday'                  => '13.11.2006 09:00:00' },
    { '9pm 2nd monday'                  => '13.11.2006 21:00:00' },
    { '2nd monday 9am'                  => '13.11.2006 09:00:00' },
    { '2nd monday 9pm'                  => '13.11.2006 21:00:00' },
    { '11am 100th day'                  => '10.04.2006 11:00:00' },
    { '11pm 100th day'                  => '10.04.2006 23:00:00' },
    { '100th day 11am'                  => '10.04.2006 11:00:00' },
    { '100th day 11pm'                  => '10.04.2006 23:00:00' },
    { '4am 6 mondays from now'          => '01.01.2007 04:00:00' },
    { '4pm 6 mondays from now'          => '01.01.2007 16:00:00' },
    { '16:00 6 mondays from now'        => '01.01.2007 16:00:00' },
    { '6 mondays from now 4am'          => '01.01.2007 04:00:00' },
    { '6 mondays from now 4pm'          => '01.01.2007 16:00:00' },
    { '6 mondays from now 16:00'        => '01.01.2007 16:00:00' },
    { '9am 4th day last week'           => '16.11.2006 09:00:00' },
    { '9pm 4th day this week'           => '23.11.2006 21:00:00' },
    { '21:00 4th day next week'         => '30.11.2006 21:00:00' },
    { '4th day last week 9am'           => '16.11.2006 09:00:00' },
    { '4th day this week 9pm'           => '23.11.2006 21:00:00' },
    { '4th day next week 21:00'         => '30.11.2006 21:00:00' },
    { '7am 12th day last month'         => '12.10.2006 07:00:00' },
    { '7pm 12th day this month'         => '12.11.2006 19:00:00' },
    { '19:00 12th day next month'       => '12.12.2006 19:00:00' },
    { '12th day last month 7am'         => '12.10.2006 07:00:00' },
    { '12th day this month 7pm'         => '12.11.2006 19:00:00' },
    { '12th day next month 19:00'       => '12.12.2006 19:00:00' },
    { '1am 8th month last year'         => '01.08.2005 01:00:00' },
    { '1pm 8th month this year'         => '01.08.2006 13:00:00' },
    { '13:00 8th month next year'       => '01.08.2007 13:00:00' },
    { '8th month last year 1am'         => '01.08.2005 01:00:00' },
    { '8th month this year 1pm'         => '01.08.2006 13:00:00' },
    { '8th month next year 13:00'       => '01.08.2007 13:00:00' },
    { '3am 1st tuesday last november'   => '01.11.2005 03:00:00' },
    { '3pm 1st tuesday this november'   => '07.11.2006 15:00:00' },
    { '15:00 1st tuesday next november' => '06.11.2007 15:00:00' },
    { '1st tuesday last november 3am'   => '01.11.2005 03:00:00' },
    { '1st tuesday this november 3pm'   => '07.11.2006 15:00:00' },
    { '1st tuesday next november 15:00' => '06.11.2007 15:00:00' },
    { '4am 2nd friday in august'        => '11.08.2006 04:00:00' },
    { '4pm 2nd friday in august'        => '11.08.2006 16:00:00' },
    { '2nd friday in august 4am'        => '11.08.2006 04:00:00' },
    { '2nd friday in august 4pm'        => '11.08.2006 16:00:00' },
    { '8am 1st day last year'           => '01.01.2005 08:00:00' },
    { '8pm 1st day this year'           => '01.01.2006 20:00:00' },
    { '20:00 1st day next year'         => '01.01.2007 20:00:00' },
    { '1st day last year 8am'           => '01.01.2005 08:00:00' },
    { '1st day this year 8pm'           => '01.01.2006 20:00:00' },
    { '1st day next year 20:00'         => '01.01.2007 20:00:00' },
);

_run_tests(107, [ [ \@expanded ] ], \&compare);

sub compare
{
    my $aref = shift;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        foreach my $string ($case_strings->($key)) {
            compare_strings($string, $href->{$key});
        }
    }
}

sub compare_strings
{
    my ($string, $result) = @_;

    my $parser = DateTime::Format::Natural->new;
    $parser->_set_datetime(\%time);

    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
