use Test::More;

use lib 't/lib';

use Caller::First qw/all/;

is([caller_first(1)]->[0], 'main', 'main');
is(caller_first(1), 'main', 'main');
is(caller_first, undef, 'main');
use Bar;
ok(my $b = Bar->new);

is($b->test, 'Foo', 'Foo');
is($b->testing, 'Bar', 'Bar');

done_testing;
