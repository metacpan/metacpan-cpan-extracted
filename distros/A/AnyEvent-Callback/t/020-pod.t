#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

BEGIN {
    use Test::More;
    eval 'use Test::Pod 1.00';
    plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
};
all_pod_files_ok( all_pod_files );

