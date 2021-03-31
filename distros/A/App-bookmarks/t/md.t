#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 1;

is(scalar(`"$^X" -Ilib script/bookmarks t/data/test.md`), <<'EOF'
Link text with [brackets] inside http://www.example.com My \"title\"
EOF
, "bookmarks - md");
