#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# Individual functions.
BEGIN { use_ok('Data::ID::URL::Shrink', qw(shrink_id)); }
BEGIN { use_ok('Data::ID::URL::Shrink', qw(stretch_id)); }
BEGIN { use_ok('Data::ID::URL::Shrink', qw(random_id)); }
# Export tags.
BEGIN { use_ok('Data::ID::URL::Shrink', qw(:all)); }
BEGIN { use_ok('Data::ID::URL::Shrink', qw(:encoding)); }

done_testing();
