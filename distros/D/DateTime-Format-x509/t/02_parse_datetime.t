#!/usr/bin/env perl

use strict;
use warnings;

use lib qw( ./lib );

use Data::Dump;
use DateTime;
use Test::More;

BEGIN { use_ok( 'DateTime::Format::x509' ); }

my $obj = DateTime::Format::x509->new;

# The dates we'll be using
my $x509_1 = 'Mar 11 03:05:34 2013 UTC';
my $x509_2 = 'Jun 01 11:17:23 2012 UTC';
my $x509_3 = 'Aug 25 13:51:01 2013 UTC';
my $x509_4 = 'Feb 28 23:59:59 2014 UTC';
my $x509_5 = 'Nov 30 00:51:02 2016 UTC';

my $dt1 = DateTime->new(
    year => 2013,
    month => 3,
    day => 11,
    hour => 3,
    minute => 5,
    second => 34,
    time_zone => 'UTC'
);

my $dt2 = DateTime->new(
    year => 2012,
    month => 6,
    day => 1,
    hour => 11,
    minute => 17,
    second => 23,
    time_zone => 'UTC'
);

my $dt3 = DateTime->new(
    year => 2013,
    month => 8,
    day => 25,
    hour => 13,
    minute => 51,
    second => 1,
    time_zone => 'UTC'
);

my $dt4 = DateTime->new(
    year => 2014,
    month => 2,
    day => 28,
    hour => 23,
    minute => 59,
    second => 59,
    time_zone => 'UTC'
);

my $dt5 = DateTime->new(
    year => 2016,
    month => 11,
    day => 30,
    hour => 0,
    minute => 51,
    second => 2,
    time_zone => 'UTC'
);


# Parse a date
my $x509_1_dt = $obj->parse_datetime($x509_1);
my $x509_2_dt = $obj->parse_datetime($x509_2);
my $x509_3_dt = $obj->parse_datetime($x509_3);
my $x509_4_dt = $obj->parse_datetime($x509_4);
my $x509_5_dt = $obj->parse_datetime($x509_5);

is($x509_1_dt->epoch, $dt1->epoch, 'Parsed DateTime matches created one (1)');
is($x509_2_dt->epoch, $dt2->epoch, 'Parsed DateTime matches created one (2)');
is($x509_3_dt->epoch, $dt3->epoch, 'Parsed DateTime matches created one (3)');
is($x509_4_dt->epoch, $dt4->epoch, 'Parsed DateTime matches created one (4)');
is($x509_5_dt->epoch, $dt5->epoch, 'Parsed DateTime matches created one (5)');

# Format a date

is($obj->format_datetime($dt1), $x509_1, 'Formatted DateTime matches original one (1)');
is($obj->format_datetime($dt2), $x509_2, 'Formatted DateTime matches original one (2)');
is($obj->format_datetime($dt3), $x509_3, 'Formatted DateTime matches original one (3)');
is($obj->format_datetime($dt4), $x509_4, 'Formatted DateTime matches original one (4)');
is($obj->format_datetime($dt5), $x509_5, 'Formatted DateTime matches original one (5)');

done_testing;
