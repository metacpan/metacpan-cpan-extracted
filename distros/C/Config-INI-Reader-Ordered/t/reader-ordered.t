#!perl -Tw
use strict;
use Test::More tests => 4;

my $r = "Config::INI::Reader::Ordered";
use_ok($r);

is_deeply(
  $r->read_string(<<END),
foo = 1

[s1]
bar = 2
baz = 3

[s2]
quux = 4
END
  [
    [ _ => { foo => 1 } ],
    [ s1 => { bar => 2, baz => 3 } ],
    [ s2 => { quux => 4 } ],
  ],
  "simple, with default section",
);

is_deeply(
  $r->read_string(<<END),
foo = 1

[s1]
bar = 2

[s2]
quux = 4

[s1]
baz = 3
END
  [
    [ _ => { foo => 1 } ],
    [ s1 => { bar => 2, baz => 3 } ],
    [ s2 => { quux => 4 } ],
  ],
  "re-open a section",
);

is_deeply(
  $r->read_string(<<END),
[s1]
foo = 1
END
  [
    [ s1 => { foo => 1 } ],
  ],
  "no default",
);
