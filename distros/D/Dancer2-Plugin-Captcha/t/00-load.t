#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Dancer2::Plugin::Captcha') || print "Bail out!\n"; }

diag("Testing Dancer2::Plugin::Captcha $Dancer2::Plugin::Captcha::VERSION, Perl $], $^X");
