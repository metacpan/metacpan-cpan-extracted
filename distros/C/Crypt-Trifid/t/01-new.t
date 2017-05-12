#!perl

use strict; use warnings;
use Crypt::Trifid;
use Test::More tests => 1;

ok(Crypt::Trifid->new);
