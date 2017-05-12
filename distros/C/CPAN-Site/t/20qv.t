#!/usr/bin/env perl
$^W = 0;
use warnings;
use strict;

use Test::More tests => 9;

use version;

# Check that the qv() implementation does not change

ok(qv(1.2.3) > qv(1));
ok(qv(1.2.3) > qv(1.0));
ok(qv(1.2.3) > qv(1.2.0));
ok(qv(1.2.3) > qv(1.2.2.0));
ok(qv(1.2.3) < qv(2));
ok(qv(1.2.3) < qv(1.3));
ok(qv(1.2.3) < qv(1.2.4));
ok(qv(1.2.3) < qv(1.2.3.1));

ok(qv(1.2.3) == qv(1.2.3));
