#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test qw(_result_string);
use Test::More tests => 9;

my @iso8601 = (
    { '2016T12'             => '01.01.2016 12:00:00' },
    { '2016T12:12'          => '01.01.2016 12:12:00' },
    { '2016T12:12:11'       => '01.01.2016 12:12:11' },
    { '2016-06T12'          => '01.06.2016 12:00:00' },
    { '2016-06T12:12'       => '01.06.2016 12:12:00' },
    { '2016-06T12:12:11'    => '01.06.2016 12:12:11' },
    { '2016-06-19T12'       => '19.06.2016 12:00:00' },
    { '2016-06-19T12:12'    => '19.06.2016 12:12:00' },
    { '2016-06-19T12:12:11' => '19.06.2016 12:12:11' },
);

compare(\@iso8601);

sub compare
{
    my $aref = shift;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        compare_strings($key, $href->{$key});
    }
}

sub compare_strings
{
    my ($string, $result) = @_;

    my $parser = DateTime::Format::Natural->new;

    my $dt = $parser->parse_datetime($string);

    if ($parser->success && $parser->_get_truncated) {
        is(_result_string($dt), $result, $string);
    }
    else {
        fail($string);
    }
}
