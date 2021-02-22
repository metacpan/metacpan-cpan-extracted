#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 1;

is(scalar(`"$^X" -Ilib script/bookmarks t/data/test.md`), "markdown example http://example.md #tag1 #tag2\n", "bookmarks - md");
