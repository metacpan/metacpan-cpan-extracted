#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use Test::More tests => 19;

my @ordinal_number = (
    '2d aug',
    '3d aug',
    '11th sep',
    '12th sep',
    '13th sep',
    '21st oct',
    '22nd oct',
    '23rd oct',
);

my @durations = (
    '26 oct 10:00am to 11:00am',
    '26 oct 10:00pm to 11:00pm',
);

my @filtered = (
    'thurs,',
);

my @formatted = (
    '2011-Jan-04',
);

my @rewrite = (
    # \d{1,2}$ -> \d{1,2}:00$
    'feb 28 at 3',
    '28 feb at 3',
    'may 22nd 2011 at 9',
    '22nd may 2011 at 9',
    'saturday 3 months ago at 5',
);

my @spaces = (
    ' now',
    'now ',
);

foreach my $list (\@ordinal_number, \@durations, \@filtered, \@formatted, \@rewrite, \@spaces) {
    check($list);
}

sub check
{
    my $list = shift;
    foreach my $string (@$list) {
        check_success($string);
    }
}

sub check_success
{
    my ($string) = @_;

    my $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime_duration($string);

    if ($parser->success) {
        pass($string);
    }
    else {
        fail($string);
    }
}
