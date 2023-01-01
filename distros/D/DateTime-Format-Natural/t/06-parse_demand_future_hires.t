#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true);

use Test::MockTime::HiRes qw(set_fixed_time);
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
    { '01:13:07.999' => '25.11.2006 01:13:07.999' },
    { '01:13:08.000' => '25.11.2006 01:13:08.000' },
    { '01:13:08.001' => '24.11.2006 01:13:08.001' },
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

    my $parser = DateTime::Format::Natural->new(demand_future => true);
    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string_hires($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
