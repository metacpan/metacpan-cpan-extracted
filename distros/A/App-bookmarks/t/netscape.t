#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

eval {
    require Netscape::Bookmarks;
};
if ($@)
{
    plan skip_all => "module Netscape::Bookmarks required for this test";
}
else
{
    plan tests => 1;

is(scalar(`"$^X" -Ilib script/bookmarks t/data/test.html`), <<'EOF'
netscape example http://example.org/
EOF
, "bookmarks - gemini");

}
