#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

eval 'use Test::Code::TidyAll';
plan skip_all => "Test::Code::TidyAll required to check files." if $@;
tidyall_ok(
    no_backups => 1,
    no_cache   => 1
);

done_testing;
