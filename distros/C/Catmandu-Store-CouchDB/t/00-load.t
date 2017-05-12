#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

my @pkgs = qw(
    Catmandu::Store::CouchDB
    Catmandu::Store::CouchDB::Bag
);

require_ok $_ for @pkgs;

done_testing 2;
