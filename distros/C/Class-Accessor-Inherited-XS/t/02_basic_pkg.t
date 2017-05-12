use strict;
use Test::More;

use Class::Accessor::Inherited::XS inherited => [qw/a b/];

$main::__cag_a = 1;
is(main->a, 1);

main->b(2);
is(main->b, 2);
is($main::__cag_b, 2);

done_testing;
