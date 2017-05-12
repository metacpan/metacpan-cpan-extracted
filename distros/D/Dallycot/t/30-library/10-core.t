use lib 't/lib';

use strict;
use warnings;

use Test::More;

use LibraryHelper;

BEGIN { require_ok 'Dallycot::Library::Core' };

isa_ok(Dallycot::Library::Core->instance, 'Dallycot::Library');

uses 'http://www.dallycot.net/ns/core/1.0#';
uses 'http://www.dallycot.net/ns/loc/1.0#';

ok(Dallycot::Registry->instance->has_namespace('http://www.dallycot.net/ns/core/1.0#'), 'Core namespace is registered');

my $result;

$result = run('y-combinator((self) :> 3)');

isa_ok $result, 'Dallycot::Value::Lambda';

is $result->arity, 0, "y-combinator((self) :> ...) takes no arguments";

$result = run('length("foo")');

is_deeply $result, Numeric(3), "The length of 'foo' is 3";

$result = run("length([1,2,3])");

is_deeply $result, Numeric(3), "[1,2,3] has three elements";

$result = run("([1,2] ::: 3..5)[4]");

is_deeply $result, Numeric(4);

done_testing();
