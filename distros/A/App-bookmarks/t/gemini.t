#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

eval {
    require URI::Find;
};
if ($@)
{
    plan skip_all => "module URI::Find required for this test";
}
else
{
    plan tests => 1;

is(scalar(`"$^X" -Ilib script/bookmarks t/data/test.gmi`), <<'EOF'
gemini://example.org/
An example link gemini://example.org/
Another example link at the same host gemini://example.org/foo
A gopher link gopher://example.org:70/1
EOF
, "bookmarks - gemini");

}
