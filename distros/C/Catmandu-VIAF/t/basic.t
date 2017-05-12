use strict;
use Test::More;

my @pkgs = qw (
    Catmandu::Fix::viaf_match
    Catmandu::Fix::viaf_search
    Catmandu::Store::VIAF
    Catmandu::Store::VIAF::Bag
    Catmandu::VIAF::API::Extract
    Catmandu::VIAF::API::ID
    Catmandu::VIAF::API::Parse
    Catmandu::VIAF::API::Query
    Catmandu::VIAF::API
);

require_ok $_ for @pkgs;

done_testing 9;

