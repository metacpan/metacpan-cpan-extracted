#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my @pkgs = qw(
    Catmandu::Store::MongoDB
    Catmandu::Store::MongoDB::Bag
    Catmandu::Store::MongoDB::Searcher
);

require_ok $_ for @pkgs;

# Connect to a non-existing host
my $store = Catmandu->store(
    'MongoDB',
    database_name => 'test',
    host          => 'mongodb://localhost:0'
);

dies_ok { $store->first } 'expecting to die';

done_testing;
