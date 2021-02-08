#! /usr/bin/perl -w
# Basic test suite
# Copyright (c) 2007 imacat. All rights reserved. This program is free
# software; you can redistribute it and/or modify it under the same terms
# as Perl itself.

use strict;
use warnings;
use Test;

BEGIN { plan tests => 1 }

our $r;

$r = eval {
    use Acme::GuessNumber;
    guess_number(25, HURRY_UP);
    return 1;
};
# 1
ok($r, 1);
