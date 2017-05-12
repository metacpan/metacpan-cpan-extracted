#!perl

use 5.010;
use strict;
use warnings;

use Data::Sah::Terse qw(terse_schema);
use Test::More 0.98;

is(terse_schema("int"), "int");
is(terse_schema("int*"), "int");
is(terse_schema(["int*"]), "int");
is(terse_schema(["int*", min=>0]), "int");

is(terse_schema(["array*", min_len=>0]), "array");
is(terse_schema(["array*", of=>"int"]), "array[int]");
is(terse_schema(["array*", of=>["array" => of=>"int"]]), "array[array[int]]");

is(terse_schema("any"), "any");
is(terse_schema(["any*", of=>[]]), "any");
is(terse_schema(["any*", of=>["int"]]), "int");
is(terse_schema(["any*", of=>["int", "array*"]]), "int|array");
is(terse_schema(["any*", of=>["int", ["array*"=>of=>"int"]]]),
   "int|array[int]");

is(terse_schema("all"), "all");
is(terse_schema(["all*", of=>[]]), "all");
is(terse_schema(["all*", of=>["int"]]), "int");
is(terse_schema(["all*", of=>["int", "float*"]]), "int & float");

DONE_TESTING:
done_testing;
