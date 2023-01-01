#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @simple = (
    { 'last millisecond'    => '24.11.2006 01:13:07.999' },
    { 'this millisecond'    => '24.11.2006 01:13:08.000' },
    { 'next millisecond'    => '24.11.2006 01:13:08.001' },
    { '10 milliseconds ago' => '24.11.2006 01:13:07.990' },
    { 'in 5 milliseconds'   => '24.11.2006 01:13:08.005' },
    { '06:56:06.001am'      => '24.11.2006 06:56:06.001' },
    { '06:56:06.001pm'      => '24.11.2006 18:56:06.001' },
);

my @complex = (
    { 'yesterday 7 milliseconds ago'    => '23.11.2006 01:13:07.993' },
    { 'today 5 milliseconds ago'        => '24.11.2006 01:13:07.995' },
    { 'tomorrow 3 milliseconds ago'     => '25.11.2006 01:13:07.997' },
    { '2 milliseconds before now'       => '24.11.2006 01:13:07.998' },
    { '4 milliseconds from now'         => '24.11.2006 01:13:08.004' },
    { '6 milliseconds before yesterday' => '22.11.2006 23:59:59.994' },
    { '6 milliseconds before today'     => '23.11.2006 23:59:59.994' },
    { '6 milliseconds before tomorrow'  => '24.11.2006 23:59:59.994' },
    { '3 milliseconds after yesterday'  => '23.11.2006 00:00:00.003' },
    { '3 milliseconds after today'      => '24.11.2006 00:00:00.003' },
    { '3 milliseconds after tomorrow'   => '25.11.2006 00:00:00.003' },
    { '10 milliseconds before noon'     => '24.11.2006 11:59:59.990' },
    { '10 milliseconds before midnight' => '23.11.2006 23:59:59.990' },
    { '5 milliseconds after noon'       => '24.11.2006 12:00:00.005' },
    { '5 milliseconds after midnight'   => '24.11.2006 00:00:00.005' },
);

my @specific = (
    { '3:20:00.001' => '24.11.2006 03:20:00.001' },
);

_run_tests(23, [ [ \@simple ], [ \@complex ], [ \@specific ] ], \&compare);

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
