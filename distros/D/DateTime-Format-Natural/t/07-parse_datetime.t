#!/usr/bin/perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @simple = (
    { 'now' => '24.11.2006 01:13:08' },
);

_run_tests(1, [ [ \@simple ] ], \&compare);

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

    my $parser = DateTime::Format::Natural->new(datetime => DateTime->new(%time));
    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
