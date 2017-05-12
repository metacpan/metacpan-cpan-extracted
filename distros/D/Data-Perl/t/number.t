use Test::More;
use Data::Perl;

use strict;

# constructor
is ref(number(1)), 'Data::Perl::Number', 'constructor shortcut works';

my $c = number(5);
is $$c, 5, 'nondefault set works';

# add
$c->add(5);
is $$c, 10, 'add works';

# sub
$c->sub(5);
is $$c, 5, 'sub works';

# mul
$c->mul(6);
is $$c, 30, 'mul works';

# div
$c->div(7);
is $$c, 30/7, 'div works';

# mod
$$c = 12;
$c->mod(5);
is $$c, 2, 'mod works';

$$c = -5;
# abs
$c->abs;
is $$c, 5, 'abs works';

done_testing();
