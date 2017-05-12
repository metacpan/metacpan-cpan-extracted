#!perl

use 5.010001;
use strict;
use warnings;

use Data::Sah::Util::Subschema qw(extract_subschemas);
use Test::More 0.98;

is_deeply(
    [extract_subschemas([any => of=>["int*", ["array*", of=>"int"]]])],
    ["int*", ["array*", of=>"int"], "int"],
);

is_deeply(
    [extract_subschemas(["array", "of|" => ["int", "float"]])],
    ["int", "float"],
);

DONE_TESTING:
done_testing;
