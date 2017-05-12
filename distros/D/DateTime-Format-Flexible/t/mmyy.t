#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use DateTime::Format::Flexible;

{
    my $dt = DateTime::Format::Flexible->parse_datetime('12/2010');
    is ( $dt->datetime, '2010-12-01T00:00:00', 'MM/YYYY in past works' );
}
{
    my $curr_year = DateTime->now->year;
    my $dt = DateTime::Format::Flexible->parse_datetime('12/13');
    is ( $dt->datetime, $curr_year.'-12-13T00:00:00', 'MM/DD works' );
}
{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '12/13', MMYY => 1
    );
    is ( $dt->datetime, '2013-12-01T00:00:00', 'MM/YY works with MMYY' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '1/10', MMYY => 1
    );
    is ( $dt->datetime, '2010-01-01T00:00:00', 'M/YY works with MMYY' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime(
        '1/1', MMYY => 1
    );
    is ( $dt->datetime, '2001-01-01T00:00:00', 'M/Y works with MMYY' );
}

{
    my $dt = DateTime::Format::Flexible->parse_datetime('1/32');
    is ( $dt->datetime, '2032-01-01T00:00:00', 'M/YY works when year > 31' );
}
