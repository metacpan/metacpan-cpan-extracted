use Test::More;
use Data::Perl;
use Scalar::Util qw/refaddr/;

use strict;

# constructor
is ref(counter(1)), 'Data::Perl::Counter', 'constructor shortcut works';

my $c = counter(5);
is $$c, 5, 'nondefault set works';

# inc
$c->inc;
is $$c, 6, 'inc 1 works';

$c->inc(3);
is $$c, 9, 'inc n works';

# dec
$c = counter(4);
$c->dec;
is $$c, 3, 'dec 1 works';

$c->dec(2);
is $$c, 1, 'dec n works';

# reset
$c->reset;
is $$c, 0, 'reset works';

done_testing();
