#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('Catmandu::Fix::File');

my %main = do { no strict; %{"main::"} };

foreach (qw(basename dirname file_size human_byte_size)) {
    ok defined $main{$_}, "$_ exported";
}

done_testing;
