#!perl

use strict;
use warnings;
use utf8;

use Test::More;
eval "use Test::MinimumVersion";
plan skip_all => "Test::MinimumVersion required for testing variables" if $@;

all_minimum_version_from_metayml_ok();
done_testing;
