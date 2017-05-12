#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Catmandu::Fix::Date');

my %main = do { no strict; %{"main::"} };

foreach (qw(datetime_format end_day end_week end_year split_date
            start_day start_week start_year timestamp)) {
    ok defined $main{$_}, "$_ exported";
}

my $item = { date => '2001-11-09' };
split_date($item, 'date');
is_deeply $item,
    { date => { year => 2001, month => 11, day => 9 } },
    'exported function usable';

done_testing;
