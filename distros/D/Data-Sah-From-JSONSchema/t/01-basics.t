#!perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;

use Data::Sah::From::JSONSchema qw(convert_json_schema_to_sah);

dies_ok { convert_json_schema_to_sah() };
dies_ok { convert_json_schema_to_sah([]) };

dies_ok { convert_json_schema_to_sah({}) } "currently type is required";

is_deeply(convert_json_schema_to_sah({type=>"string"}),
          [str => {req=>1}]);
# XXX more tests

done_testing;
