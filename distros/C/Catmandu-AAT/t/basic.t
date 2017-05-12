use strict;
use Test::More;

my @pkgs = qw (
    Catmandu::Store::AAT
    Catmandu::Store::AAT::Bag
    Catmandu::AAT::API
    Catmandu::AAT::SPARQL
    Catmandu::Fix::aat_match
    Catmandu::Fix::aat_search
);

require_ok $_ for @pkgs;

done_testing 6;
