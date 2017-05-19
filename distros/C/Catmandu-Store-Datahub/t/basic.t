use strict;
use Test::More;

my @pkgs = qw(
    Catmandu::Store::Datahub
    Catmandu::Store::Datahub::Bag
    Catmandu::Store::Datahub::OAuth
);

require_ok $_ for @pkgs;

done_testing 3;
