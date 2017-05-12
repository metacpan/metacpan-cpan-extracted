use strict;
use warnings;

use Test::More;

use Data::PatternCompare qw(any empty);

ok(__PACKAGE__->can('any'), 'any exported');
ok(__PACKAGE__->can('empty'), 'empty exported');

done_testing;
