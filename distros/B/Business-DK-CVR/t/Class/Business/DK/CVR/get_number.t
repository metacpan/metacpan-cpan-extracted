#!/usr/bin/perl -w

# $Id$

use strict;
use warnings;
use Test::More tests => 1;

use Class::Business::DK::CVR;

my $cvr = Class::Business::DK::CVR->new(27355021);

is($cvr->get_number(), 27355021);
