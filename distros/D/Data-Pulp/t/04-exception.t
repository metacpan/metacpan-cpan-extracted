#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Data::Pulp;

my ($pulper);

$pulper = pulper
    case { $_ eq 'apple' } then { 'APPLE' }
    case { $_ eq 'banana' }
    case { $_ eq 'cherry' } then { 'CHERRY' }
    empty { 'empty' }
    nil { 'nil' }
    case { m/xyzzy/ } then { 'Nothing happens.' }
    default { die "Don't know what to do with $_\n" }
;

throws_ok { $pulper->pulp( '1' ) } qr/Don't know what to do with 1/;
