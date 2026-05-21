#!perl -T

use Test2::V0;
use utf8;
use Object::Pad;

class Action :does(Class::JSON_Object) {
  field $operation;
  field $args;
}

my $op = Action->new->load('{"operation":"move","args":[2]}');
is( $op->json, '{"args":[2],"operation":"move"}', "load" );
is( $op->hash, { args => [2], operation => "move" }, "load" );

# Accessors are automatically defined.
is( $op->operation, 'move', "operation  accessor" );
is( $op->args, [2], "args  accessor" );

done_testing();
