#!/usr/bin/perl -w

# $Id$

use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use English qw(-no_match_vars);

use Class::Business::DK::FI;

ok(my $fi = Class::Business::DK::FI->new('026840149965328'));

isa_ok($fi, 'Class::Business::DK::FI');

dies_ok { $fi = Class::Business::DK::FI->new(); } 'no argument to constructor';

like($EVAL_ERROR, qr/You must provide a FI number/, 'asserting error message');

dies_ok { $fi = Class::Business::DK::FI->new(11111111); } 'invalid argument to constructor';

like($EVAL_ERROR, qr/Invalid FI number parameter/, 'asserting error message');
