#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 2 }

use Data::Define qw/ define_html brockets div-class-undef /;

ok(define(undef), '<undef>');
ok(define_html(undef), '<div class="undef"></div>');

exit;
