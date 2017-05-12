#!/usr/bin/env perl

use Test::More tests => 1;
use Acme::AutoloadAll;

# don't import anything from Scalar::Util
use Scalar::Util ();

# $Acme::AutoloadAll::DEBUG = 1;
ok(looks_like_number(42), 'can use function that was not imported');

