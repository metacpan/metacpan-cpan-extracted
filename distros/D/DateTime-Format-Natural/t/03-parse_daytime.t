#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @daytime_regular = (
    { 'morning'   => '24.11.2006 08:00:00' },
    { 'afternoon' => '24.11.2006 14:00:00' },
    { 'evening'   => '24.11.2006 20:00:00' },
);

my @daytime_user = (
    { 'morning'   => '24.11.2006 06:00:00' },
    { 'afternoon' => '24.11.2006 13:00:00' },
    { 'evening'   => '24.11.2006 19:00:00' },
);

my %opts = (
    morning   =>  6,
    afternoon => 13,
    evening   => 19,
);

_run_tests(6, [ [ \@daytime_regular ], [ \@daytime_user, \%opts ] ], \&compare);

sub compare
{
    my ($aref, $opts) = @_;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        foreach my $string ($case_strings->($key)) {
            compare_strings($string, $href->{$key}, $opts);
        }
    }
}

sub compare_strings
{
    my ($string, $result, $opts) = @_;

    my $parser = DateTime::Format::Natural->new(daytime => $opts || {});
    $parser->_set_datetime(\%time);

    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
