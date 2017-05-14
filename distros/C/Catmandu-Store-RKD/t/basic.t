use strict;
use Test::More;
my @pkgs = qw (
    Catmandu::Fix::rkd_name
    Catmandu::Store::RKD
    Catmandu::Store::RKD::Bag
    Catmandu::Store::RKD::API::Extract
    Catmandu::Store::RKD::API::Name
    Catmandu::Store::RKD::API::Parse
);

require_ok $_ for @pkgs;

done_testing 6;
