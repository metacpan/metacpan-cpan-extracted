#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use lib 't/lib';
use lib 't/pvtlib';
use CleanEnv;

use BSON;

my $ts = BSON::Timestamp->new(0x1234, 0x5678);
isa_ok( $ts, 'BSON::Timestamp' );
is( $ts->seconds, 0x1234 );
is( $ts->increment, 0x5678 );
