#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;

use strictures 2;
no warnings "experimental::signatures";

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

all_pod_files_ok();
