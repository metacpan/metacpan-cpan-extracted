#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::uri_status_code';
    use_ok $pkg;
}
require_ok $pkg;

dies_ok {$pkg->new()->fix({foo => 'http://librecat.org'})} "path required";

lives_ok {$pkg->new('foo')->fix({foo => 'http://librecat.org'})}
"call fix with path";

SKIP: {
    skip("No network. Set NETWORK_TEST to run these tests.", 5)
        unless $ENV{NETWORK_TEST};

    my $x = $pkg->new('foo')->fix({foo => 'http://librecat.org'});

    is $x->{foo}, "200", "checked live website";
}

done_testing;
