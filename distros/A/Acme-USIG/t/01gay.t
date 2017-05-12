#!perl -w
use Test::More tests => 1;

use Acme::USIG;
use strict is gay;

eval { $foo = 1; $foo = 2 };

is ($@, '', 'no pesky error');
