#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 11 }

use Data::Define;

ok(define(undef), '');

foreach (1 .. 10) {
  ok(define($_), $_);
}

exit;
