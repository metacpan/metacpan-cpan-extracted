#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my @pkgs = qw(
    Catmandu::Store::MongoDB
    Catmandu::Store::MongoDB::Bag
    Catmandu::Store::MongoDB::Searcher
);

require_ok $_ for @pkgs;

done_testing;
