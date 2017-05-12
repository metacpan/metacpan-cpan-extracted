#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

eval "use Test::NoTabs";
plan skip_all => "Test::NoTabs required for testing" if $@;
all_perl_files_ok(qw(lib t tools));
