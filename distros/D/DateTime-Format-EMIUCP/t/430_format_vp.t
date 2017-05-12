#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 5;

BEGIN { use_ok 'DateTime::Format::EMIUCP::VP' }

my $dt = DateTime->new(
    year      => 2012,
    month     => 2,
    day       => 3,
    hour      => 6,
    minute    => 55,
    second    => 30,
    time_zone => 'UTC',
);
isa_ok $dt, 'DateTime';
is $dt->ymd, '2012-02-03', 'date';
is $dt->hms, '06:55:30', 'time';
is(DateTime::Format::EMIUCP::VP->format_datetime($dt), '0302120655', 'format_datetime');
