#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::cmd';
    use_ok $pkg;
}

done_testing 1;
