use strict;
use warnings;
use Test::More;

plan skip_all => 'Author tests not required for installation'
    unless $ENV{AUTHOR_TESTING};

eval 'use Test::Pod 1.22';
plan skip_all => 'Test::Pod 1.22 required' if $@;

all_pod_files_ok();
