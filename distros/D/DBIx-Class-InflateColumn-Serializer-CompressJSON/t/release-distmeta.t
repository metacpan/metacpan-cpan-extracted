#!perl
#
# This file is part of DBIx-Class-InflateColumn-Serializer-CompressJSON
#
# This software is copyright (c) 2012 by Weborama.  No
# license is granted to other entities.
#

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing META.yml" if $@;
meta_yaml_ok();
