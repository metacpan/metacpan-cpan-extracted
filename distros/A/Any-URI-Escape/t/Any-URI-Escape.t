#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Any::URI::Escape') }

can_ok('Any::URI::Escape', qw( uri_escape uri_unescape ));

cmp_ok(uri_escape("http://foo.com"), 'eq', 'http%3A%2F%2Ffoo.com');
cmp_ok(uri_unescape("http%3A%2F%2Ffoo.com"), 'eq', 'http://foo.com');

