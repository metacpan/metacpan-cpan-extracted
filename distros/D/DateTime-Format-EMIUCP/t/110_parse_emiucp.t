#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 12;

BEGIN { use_ok 'DateTime::Format::EMIUCP' }

do {
    my $dt = DateTime::Format::EMIUCP->parse_datetime('030212065530');
    isa_ok $dt, 'DateTime';
    is $dt->ymd, '2012-02-03', 'date';
    is $dt->hms, '06:55:30', 'time';
};

do {
    my $dt = DateTime::Format::EMIUCP->parse_datetime('010100010101');
    isa_ok $dt, 'DateTime';
    is $dt->year, 2000, 'year';
};

do {
    my $dt = DateTime::Format::EMIUCP->parse_datetime('010199010101');
    isa_ok $dt, 'DateTime';
    is $dt->year, 1999, 'year';
};

do {
    my $dt = DateTime::Format::EMIUCP->parse_datetime('010170010101');
    isa_ok $dt, 'DateTime';
    is $dt->year, 1970, 'year';
};

do {
    my $dt = DateTime::Format::EMIUCP->parse_datetime('010169010101');
    isa_ok $dt, 'DateTime';
    is $dt->year, 2069, 'year';
};
