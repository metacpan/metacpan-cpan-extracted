#!/usr/bin/perl -w

# $Id$

use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use English qw(-no_match_vars);

use Class::Business::DK::CVR;

my $cvr = Class::Business::DK::CVR->new(27355021);

ok($cvr->set_number(30947460));

dies_ok { $cvr->set_number(); } 'no argument to mutator';

like($EVAL_ERROR, qr/You must provide a CVR number/, 'asserting error message');

dies_ok { $cvr->set_number(1234567890); } 'invalid argument to mutator';

like($EVAL_ERROR, qr/Invalid CVR number parameter/, 'asserting error message');
