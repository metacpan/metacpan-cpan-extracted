#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 12;

BEGIN { use_ok 'DateTime::Format::EMIUCP::DDT' }

do {
    my $dt = DateTime::Format::EMIUCP::DDT->parse_datetime('0302120655');
    isa_ok $dt, 'DateTime';
    is $dt->ymd, '2012-02-03', 'date';
    is $dt->hms, '06:55:00', 'time';
};

do {
    my $dt = DateTime::Format::EMIUCP::DDT->parse_datetime('0101000101');
    isa_ok $dt, 'DateTime';
    is $dt->year, 2000, 'year';
};

do {
    my $dt = DateTime::Format::EMIUCP::DDT->parse_datetime('0101990101');
    isa_ok $dt, 'DateTime';
    is $dt->year, 1999, 'year';
};

do {
    my $dt = DateTime::Format::EMIUCP::DDT->parse_datetime('0101700101');
    isa_ok $dt, 'DateTime';
    is $dt->year, 1970, 'year';
};

do {
    my $dt = DateTime::Format::EMIUCP::DDT->parse_datetime('0101690101');
    isa_ok $dt, 'DateTime';
    is $dt->year, 2069, 'year';
};
