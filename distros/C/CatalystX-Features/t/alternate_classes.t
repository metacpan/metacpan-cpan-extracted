use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib/TestAppAlternateClasses/lib";

use_ok 'Catalyst::Test', 'TestApp';

{
    my ($resp,$c) = ctx_request('/');

    isa_ok( $c->features, 'TestBackendClass' );
    isa_ok( $_, 'TestFeatureClass' ) for $c->features->list;
}

done_testing;

