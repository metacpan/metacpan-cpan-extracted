#!/usr/bin/perl

use Test::More;
use File::Path;

eval "use Test::Strict";
plan skip_all => "Test::Strict not installed" if $@;

all_cover_ok( 89, 't/' );

# Clean up
rmtree("cover_db");
