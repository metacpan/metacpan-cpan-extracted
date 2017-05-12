use Test::More;
use Data::Perl;
use strict;

use Scalar::Util qw/refaddr/;

# constructor
is ref(bool(1)), 'Data::Perl::Bool', 'constructor shortcut works';

my $b = bool(5);
is $$b, 1, 'nondefault set reduces to 1';

$b = bool();
is $$b, 0, 'default set reduces to 0';

# set
$b->set();
is $$b, 1, 'set sets to 1';
$b->set();

# unset
$b->unset;
is $$b, 0, 'unset works.';

# toggle
$b->toggle;
is $$b, 1, 'toggle works';
$b->toggle;
is $$b, 0, 'toggle works';

# not
is $b->not, 1, 'not works';
$b->toggle;
is $b->not, '', 'not works';

done_testing();
