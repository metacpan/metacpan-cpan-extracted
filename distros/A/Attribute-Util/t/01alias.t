#!/usr/bin/perl

use warnings;
use strict;
use Test;

BEGIN { plan tests => 1 }

use Attribute::Util;
sub color :Alias(colour) { return 'red' }

ok(colour(), color());
