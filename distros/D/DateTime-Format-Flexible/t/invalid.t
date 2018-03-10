#!/usr/bin/perl

use strict;
use warnings;
use lib '.';

use Test::More tests => 2;
use DateTime;
use Test::NoWarnings;
use Test::Exception;

use DateTime::Format::Flexible;

my $dff = DateTime::Format::Flexible->new;

throws_ok { $dff->parse_datetime('not a date') } qr/Invalid date format:/, 'not a date is an invalid date';
