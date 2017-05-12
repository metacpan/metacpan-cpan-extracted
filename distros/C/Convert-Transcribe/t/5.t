# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 5.t'

#########################

# In this test we'll test whether fromfile() works.

use Test;
BEGIN { plan tests => 4 };
use Convert::Transcribe;
ok(1);

my $t = new Convert::Transcribe;
ok(1);

$t->fromfile('t/testdata');
ok(1);

ok($t->transcribe("abc"), "bca");

