#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @aliases = (
    { '1 sec ago'          => [ '24.11.2006 01:13:07', unaltered ] },
    { '10 secs ago'        => [ '24.11.2006 01:12:58', unaltered ] },
    { '1 min ago'          => [ '24.11.2006 01:12:08', unaltered ] },
    { '5 mins ago'         => [ '24.11.2006 01:08:08', unaltered ] },
    { '1 hr ago'           => [ '24.11.2006 00:13:08', unaltered ] },
    { '3 hrs ago'          => [ '23.11.2006 22:13:08', unaltered ] },
    { '1 yr ago'           => [ '24.11.2005 01:13:08', unaltered ] },
    { '7 yrs ago'          => [ '24.11.1999 01:13:08', unaltered ] },
    { 'yesterday @ noon'   => [ '23.11.2006 12:00:00', truncated ] },
    { 'tues this week'     => [ '21.11.2006 00:00:00', truncated ] },
    { 'final thurs in sep' => [ '28.09.2006 00:00:00', truncated ] },
    { 'tues'               => [ '21.11.2006 00:00:00', truncated ] },
    { 'thurs'              => [ '23.11.2006 00:00:00', truncated ] },
    { 'thur'               => [ '23.11.2006 00:00:00', truncated ] },
);

_run_tests(14, [ [ \@aliases ] ], \&compare);

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

    if ($parser->success && $parser->_get_truncated == $result->[1]) {
        is(_result_string($dt), $result->[0], _message($string));
    }
    else {
        fail(_message($string));
    }
}
