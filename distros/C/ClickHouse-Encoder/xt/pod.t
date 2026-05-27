#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run author tests'
    unless $ENV{RELEASE_TESTING};

eval 'use Test::Pod 1.22';
plan skip_all => 'Test::Pod 1.22 required' if $@;

all_pod_files_ok();
