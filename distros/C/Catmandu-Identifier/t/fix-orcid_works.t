#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::orcid_works';
    use_ok $pkg;
}
require_ok $pkg;

dies_ok {$pkg->new()} "required argument";
lives_ok {$pkg->new('orcid')} "path required";

SKIP: {
    skip("No network. Set NETWORK_TEST to run these tests.", 5)
        unless $ENV{NETWORK_TEST};

    note Dumper $pkg->new('orcid')->fix({orcid => '0000-0002-7635-3473'});
}

done_testing;
