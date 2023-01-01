#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use Test::MockTime::HiRes qw(set_fixed_time);
use DateTime;
use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

set_fixed_time(
    '02.01.2006 00:00:00',
    '%d.%m.%Y %H:%M:%S',
);

my @simple = (
    { '12am'        => '04.01.2006 00:00:00' },
    { 'monday'      => '09.01.2006 00:00:00' },
    { '2nd january' => '02.01.2007 00:00:00' },
);

_run_tests(3, [ [ \@simple ] ], \&compare);

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

#   my $parser = DateTime::Format::Natural->new(prefer_future => true); # must FAIL
    my $parser = DateTime::Format::Natural->new(
        datetime => DateTime->new(
            year   => 2006,
            month  => 1,
            day    => 3,
            hour   => 1,
            minute => 0,
            second => 0,
        ),
        prefer_future => true,
    );
    my $dt = $parser->parse_datetime($string);

    if ($parser->success && $parser->_get_truncated) {
        is(_result_string($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
