# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 4.t'

#########################

# In this test, we're going to test the function generated_code.
# We only check that it contains the word "while", because we'd
# otherwise have to rewrite this test every time we make any change
# to the code produced.

use Test;
BEGIN { plan tests => 3 };
use Convert::Transcribe;

ok(1);
my $t = new Convert::Transcribe('t/testdata'); ok(1);
ok($t->generated_code =~ "while");
