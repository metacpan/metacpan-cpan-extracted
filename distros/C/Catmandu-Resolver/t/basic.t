use strict;
use Test::More;

my @pkgs = qw (
    Catmandu::Store::Resolver
    Catmandu::Store::Resolver::API
    Catmandu::Store::Resolver::Bag
);

require_ok $_ for @pkgs;

done_testing 3;
