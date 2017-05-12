#!/usr/bin/perl -w

# $Id$

use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

use Class::Business::DK::FI;

my $fi;

$fi = Class::Business::DK::FI->new('026840149965328');

is($fi->number(), '026840149965328');
