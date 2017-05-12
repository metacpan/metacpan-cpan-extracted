use strict;
use warnings;
use Test::More tests => 20;

use Data::Transpose::Iterator::Scalar;


my $iter = Data::Transpose::Iterator::Scalar->new([1, 2, 3, 4, 5]);
isa_ok($iter, 'Data::Transpose::Iterator::Scalar');
isa_ok($iter, 'Data::Transpose::Iterator::Base');

ok($iter->count == 5);

isa_ok($iter->next, 'HASH', "First record is an hash");

is_deeply $iter->next, { value => 2 }, "The second too";

$iter->seed([ 666, 555 ]);

is_deeply $iter->next, { value => 666 }, "After seeding we're ok";

ok($iter->count == 2);

is $iter->key, 'value';

$iter->key('pippo');

is_deeply($iter->next, { pippo => 555 });


diag "Checking synopsis";

$iter = Data::Transpose::Iterator::Scalar->new([1, 2, 3, 4, 5]);
is_deeply $iter->next, { value => 1 };
# return { value => 1 };
$iter->key('string');
is_deeply $iter->next, { string => 2 };
# return { string => 2 };

$iter->records([qw/pinco pallino/]);

is_deeply $iter->next, { string => 'pinco' };

$iter->seed(qw/a b c d/);

is $iter->count, 4, "Count matches";

is $iter->key, 'string';

is_deeply $iter->next, { string => 'a' };

is $iter->count, 4, "Count matches";

is_deeply $iter->next, { string => 'b' };

$iter->key('ciao');

is_deeply $iter->next, { ciao => 'c' };

$iter = Data::Transpose::Iterator::Scalar->new(records => [qw/e f g h/],
                                               key => 'chiave');

is_deeply $iter->next, { chiave => 'e' };

is $iter->count, 4;

