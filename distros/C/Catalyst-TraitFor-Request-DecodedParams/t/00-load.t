use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Catalyst::TraitFor::Request::DecodedParams';
    use_ok 'Catalyst::TraitFor::Request::DecodedParams::JSON';
}

done_testing;
