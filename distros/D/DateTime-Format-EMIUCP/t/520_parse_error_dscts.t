#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 3;

use Test::Exception;

BEGIN { use_ok 'DateTime::Format::EMIUCP::DSCTS' }

throws_ok { my $dt = DateTime::Format::EMIUCP::DSCTS->parse_datetime('010203040599') }
    qr/an integer between 0 and 61/, 'wrong date';

throws_ok { my $dt = DateTime::Format::EMIUCP::DSCTS->parse_datetime('INVALID') }
    qr/Invalid date format/, 'invalid format';
