#!/usr/bin/perl

use strict;
use Test;
use Blib;

BEGIN { plan test => 2 }

use Business::AU::TFN;
ok(1);	# Loaded

ok(Business::AU::TFN::validate('123456782') eq "valid");

