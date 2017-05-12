# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 7.t'

#########################

# In this test we'll see whether we can nest transcriptors.

use Test;
BEGIN { plan tests => 4 };
use Convert::Transcribe;
ok(1);

my $t1 = new Convert::Transcribe(<<"EOF");
a  A
b  B
c  C
EOF
ok(1);

my $t2 = new Convert::Transcribe('t/testdata');
ok(1);

ok($t1->transcribe($t2->transcribe('abc')), "BCA");

