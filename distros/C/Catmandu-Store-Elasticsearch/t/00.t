#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my @pkgs = qw(
    Catmandu::Store::ElasticSearch
    Catmandu::Store::ElasticSearch::Bag
    Catmandu::Store::ElasticSearch::Searcher
    Catmandu::Store::ElasticSearch::CQL
);

require_ok $_ for @pkgs;

done_testing 4;
