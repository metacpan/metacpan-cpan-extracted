# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2.t'

#########################

# In this test we'll test whether new() can automatically read
# a file.

use Test;
BEGIN { plan tests => 3 };
use Convert::Transcribe;
ok(1);

my $t = new Convert::Transcribe('t/testdata');
ok(1);

ok($t->transcribe("abc"), "bca");

