#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @aliases = (
    { '1 msec ago'  => '24.11.2006 01:13:07.999' },
    { '4 msecs ago' => '24.11.2006 01:13:07.996' },
);

_run_tests(2, [ [ \@aliases ] ], \&compare);

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
        is(_result_string_hires($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
