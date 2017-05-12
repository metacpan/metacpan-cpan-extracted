#!/usr/bin/env perl

use Test::More;
eval { require Test::NoTabs; };

if ($@) {
    plan skip_all => 'Need Test::NoTabs installed for no-tabs tests';
    exit 0;
}

Test::NoTabs::all_perl_files_ok();

