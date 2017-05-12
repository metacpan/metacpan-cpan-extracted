use strict;
use warnings;
use utf8;
use Test::More;

eval "use Test::Synopsis";
plan skip_all => "Test::Synopsis is not installed." if $@;

all_synopsis_ok();

