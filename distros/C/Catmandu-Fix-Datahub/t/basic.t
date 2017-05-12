use strict;
use Test::More;

our @pkgs = qw(
    Catmandu::Fix::Datahub
    Catmandu::Fix::Datahub::Util
);

require_ok $_ for @pkgs;

done_testing 2;
