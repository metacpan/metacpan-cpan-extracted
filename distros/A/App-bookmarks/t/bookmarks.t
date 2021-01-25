#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

is(
scalar(`"$^X" -Ilib script/bookmarks t/data/test.txt`),
<<EOF
plain text example http://example.txt #tag1 #tag2
EOF
,
"bookmarks - test.txt"
);

is(
scalar(`"$^X" -Ilib script/bookmarks t/data/test.md`),
<<EOF
markdown example http://example.md #tag1 #tag2
EOF
,
"bookmarks - test.md"
);
