#!perl -w
use Test::More tests => 1;

use Acme::USIG;
use strict is cool;

eval q{ $foo = 1 };

ok ($@, "saved ourself some debugging");
