#!/usr/bin/perl

# Regression test for:
# https://rt.cpan.org/Ticket/Display.html?id=32339

use strict;
use warnings;

use Cache::Memory;
use Test::More tests => 1;

{
    my $cache = Cache::Memory->new();
    $cache->set('foo','bar');
    $cache->set_namespace("OtherNameSpace");
    # This used to die:
    $cache->set('foo','bar2');
    # TEST
    ok (1, "Program finished successfully.");
}

