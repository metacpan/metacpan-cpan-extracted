use lib 't/lib';

use strict;
use warnings;

use Test::More;

use LibraryHelper;

BEGIN { require_ok 'Dallycot::Library::Core::Streams' };

uses 'http://www.dallycot.net/ns/streams/1.0#',
     'http://www.dallycot.net/ns/core/1.0#',
     'http://www.dallycot.net/ns/loc/1.0#';

isa_ok(Dallycot::Library::Core::Streams->instance, 'Dallycot::Library');

my $result;

$result = run("length(range(1,3))");

is_deeply $result, Numeric('inf'), "1..3 has 'inf' elements";

$result = run("upfrom(1)...'");

is_deeply $result, Numeric(2), "Second number starting at 1 is 2";

$result = run("range(3,7)...'");

is_deeply $result, Numeric(4), "Second in [3,7] is 4";

$result = run("(3..7)...'");

is_deeply $result, Numeric(4), "Second in 3..7 is 4";

$result = run("range(1,3).........'");

isa_ok $result, 'Dallycot::Value::Undefined', "Running off the end should result in undef";

done_testing();
