use lib 't/lib';

use strict;
use warnings;

use Test::More;
use Test::Mojo;
use AnyEvent;
use Promises backend => ['EV'];

use Dallycot::AST;

my $ast = Dallycot::AST -> new;

isa_ok $ast->new, 'Dallycot::AST';

is $ast->simplify, $ast, "Default simplification of a node is the same node";

is scalar($ast->check_for_common_mistakes), 0, "No common mistakes by default";

my $promise = $ast -> execute();

ok $promise -> is_failed, "Can't execute the abstract AST node class";

eval {
  $ast -> to_json;
};

ok $@, "Abstract AST can't convert to JSON";

eval {
  $ast -> to_string;
};

ok $@, "Abstract AST can't convert to string";

is scalar(Dallycot::AST -> node_types), 50, "We have the right number of node classes";

done_testing();
