#!/usr/bin/env perl
#
# tests for Apache::AuthCookie::Util
#

use strict;
use Test::More tests => 2;

# don't use_ok, this needs to load at compile time.
use_ok 'Apache::AuthCookie::Util' or exit 1;

subtest is_blank => sub {
    plan tests => 8;

    Apache::AuthCookie::Util->import('is_blank');

    ok is_blank(' ');
    ok is_blank('');
    ok is_blank("\t");
    ok is_blank("\n");
    ok is_blank("\r\n");
    ok is_blank(undef);
    ok !is_blank(0);
    ok !is_blank('a');
};
