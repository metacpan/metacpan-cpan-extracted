#!/usr/bin/perl

use strict;
use Test;
use blib;

BEGIN { plan test => 5 }

use Business::AU::ACN;
ok(1);	# Loaded

ok(Business::AU::ACN::validate('004085616') eq "valid");
ok(Business::AU::ACN::validate('006 749 980') eq "valid");
ok(Business::AU::ACN::validate('006 999 980') eq "valid");
ok(Business::AU::ACN::validate('007 249 989') eq "valid");

