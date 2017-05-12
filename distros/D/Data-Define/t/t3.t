#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 22 }

use Data::Define qw/ define_html brockets /;

ok(define(undef), '<undef>');
ok(define_html(undef), '&lt;undef&gt;');

foreach (1 .. 10) {
  ok(define($_), $_);
  ok(define_html($_), $_);
}

exit;
