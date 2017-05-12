#!perl
#
# This file is part of Catalyst-Controller-ElasticSearch
#
# This software is Copyright (c) 2013 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use Test::More;

eval "use Test::Pod 1.41";
plan skip_all => "Test::Pod 1.41 required for testing POD" if $@;

all_pod_files_ok();
