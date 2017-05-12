#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my @pkgs = qw(
    Catmandu::Store::Solr
    Catmandu::Store::Solr::Bag
    Catmandu::Store::Solr::Searcher
    Catmandu::Store::Solr::CQL
    Catmandu::Importer::Solr
);

require_ok $_ for @pkgs;

done_testing 5;
