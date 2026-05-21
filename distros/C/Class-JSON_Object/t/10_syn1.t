#!perl -T

use Test2::V0;
use utf8;
use Object::Pad;

class Action :does(Class::JSON_Object) {
  field $operation :mutator;
  field $args      :mutator;
}

my $op = Action->new;
$op->operation = "copy";
$op->args = [ 'a', 2 ];

is( $op->json, '{"args":["a",2],"operation":"copy"}', "create" );

$op->load('{"operation":"move","args":[2]}');
is( $op->json, '{"args":[2],"operation":"move"}', "load" );

$op = Action->create('{"operation":"move","args":[2]}');
is( $op->json, '{"args":[2],"operation":"move"}', "load" );

$op = Action->create_sparse('{"operation":"move","args":[2],"extra":1}');
is( $op->json, '{"args":[2],"operation":"move"}', "load" );

done_testing();
