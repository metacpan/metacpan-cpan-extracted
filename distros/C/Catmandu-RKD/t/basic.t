use strict;
use Test::More;
my @pkgs = qw (
    Catmandu::Fix::rkd_name
    Catmandu::Store::RKD
    Catmandu::Store::RKD::Bag
    Catmandu::RKD::API::Extract
    Catmandu::RKD::API::Name
    Catmandu::RKD::API::Parse
);

require_ok $_ for @pkgs;

done_testing 6;
