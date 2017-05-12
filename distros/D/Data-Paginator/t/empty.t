#!/usr/bin/perl

use strict;
use Test::More;
use_ok('Data::Paginator');

my $pager = Data::Paginator->new(
    current_page => 0,
    entries_per_page => 10,
    total_entries => 0
);

cmp_ok($pager->current_page, '==', 1);

done_testing;