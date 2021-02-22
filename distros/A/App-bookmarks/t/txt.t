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
	
    is(scalar(`"$^X" -Ilib script/bookmarks t/data/test.txt`), "plain text example http://example.txt #tag1 #tag2\n", "bookmarks - txt");
}
