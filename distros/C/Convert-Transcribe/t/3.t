# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 3.t'

#########################

# In this test we'll test whether new() can automatically read
# a transcription definition from a string.

use Test;
BEGIN { plan tests => 3 };
use Convert::Transcribe;
ok(1);

my $t = new Convert::Transcribe(<<"EOF");
tz'     c
tz      z
t'      t
t       d
u       wu    < \$
i       yi    < \$
EOF
ok(1);

ok($t->transcribe("tz'u uta"), "cu wuda");

