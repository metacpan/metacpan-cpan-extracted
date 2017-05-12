use strict;
use Test::More;

my @pkgs = qw (
    Catmandu::Store::REST
    Catmandu::Store::REST::API
    Catmandu::Store::REST::Bag
);

require_ok $_ for @pkgs;

done_testing 3;
