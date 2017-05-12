#!/usr/bin/perl -w

# $Id$

use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

use Class::Business::DK::CVR;

my $cvr;

$cvr = Class::Business::DK::CVR->new(27355021);

is($cvr->number(), 27355021);
