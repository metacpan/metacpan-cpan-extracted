# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 8.t'

#########################

# In this test we'll try a really complicated transliteration.

use Test;
BEGIN { plan tests => 3 };
use Convert::Transcribe;
ok(1);

my $t = new Convert::Transcribe(<<"EOF");
\# a comment
a  b > a # another comment
a  c < ! b
a  d
b  a < \$ > \$
b  e
c  f > ! b < ! d
c  g
EOF
ok(1);

ok($t->transcribe('a aa aaa a b bb bbb c bc cb ca ac acb'),
   'c bd bbd c a ee eee f ef ge fc cf cge');
