#!perl -T
#
# This file is part of DBIx-Class-InflateColumn-Serializer-CompressJSON
#
# This software is copyright (c) 2012 by Weborama.  No
# license is granted to other entities.
#

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
