#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use DateTime::Format::Natural::Test ':set';
use Test::More;

my @calendar_gregorian = (
    { 'christmas eve'   => '24.12.2006 20:00:00' },
    { 'christmas day'   => '25.12.2006 00:00:00' },
    { 'new years eve'   => '31.12.2006 20:00:00' },
    { 'new years day'   => '01.01.2007 00:00:00' },
    { 'new year\'s eve' => '31.12.2006 20:00:00' },
    { 'new year\'s day' => '01.01.2007 00:00:00' },
);

# these tests will break at the transition to 2100...
my @calendar_julian = (
    { 'christmas eve'   => '06.01.2007 20:00:00' },
    { 'christmas day'   => '07.01.2007 00:00:00' },
    { 'new years eve'   => '13.01.2007 20:00:00' },
    { 'new years day'   => '14.01.2007 00:00:00' },
    { 'new year\'s eve' => '13.01.2007 20:00:00' },
    { 'new year\'s day' => '14.01.2007 00:00:00' },
);

my @tests = ([ \@calendar_gregorian, undef ]);
push @tests, [ \@calendar_julian, 'DateTime::Calendar::Julian' ] if eval { require DateTime::Calendar::Julian; 1 };

my $tests = 0;
$tests += scalar @{$_->[0]} for @tests;
_run_tests($tests, [ @tests ], \&compare);

sub compare
{
    my ($aref, $calendar_class) = @_;

    foreach my $href (@$aref) {
        my $key = (keys %$href)[0];
        foreach my $string ($case_strings->($key)) {
            compare_strings($string, $href->{$key}, $calendar_class);
        }
    }
}

sub compare_strings
{
    my ($string, $result, $calendar_class) = @_;

    my $parser = DateTime::Format::Natural->new(calendar_class => $calendar_class);
    $parser->_set_datetime(\%time);

    my $dt = $parser->parse_datetime($string);

    if ($parser->success) {
        is(_result_string($dt), $result, _message($string));
    }
    else {
        fail(_message($string));
    }
}
