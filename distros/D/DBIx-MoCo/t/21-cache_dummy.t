#!/usr/bin/env perl
use strict;
use warnings;

ThisTest->runtests;

package ThisTest;
use base qw/Test::Class/;

use Test::More;
use DBIx::MoCo::Cache::Dummy;

sub singleton : Test(1) {
    is(DBIx::MoCo::Cache::Dummy->instance, DBIx::MoCo::Cache::Dummy->instance);
}

sub methods : Tests {
    my $cache = DBIx::MoCo::Cache::Dummy->instance;
    ok $cache->can($_) for qw/get set clear remove cache_expire/;
}

