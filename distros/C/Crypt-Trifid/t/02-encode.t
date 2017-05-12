#!perl

use strict; use warnings;
use Crypt::Trifid;
use Test::More tests => 1;

my $crypt = Crypt::Trifid->new;
ok($crypt->encode('TRIFID'));
