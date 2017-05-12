use strict;
use warnings;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? ('no_plan') : (skip_all => 'requires Test::LeakTrace');
use Test::LeakTrace;

use lib 't/lib';
use SuperInheritedGroups;

my $simple = SuperInheritedGroups->new;
no_leaks_ok {
    $simple->basefield('Yess');
    $simple->basefield('Yess2');
} 'no leaks when set accessor over and over';

no_leaks_ok {
    my $o = SuperInheritedGroups->new;
    $o->basefield;
} 'no leaks when read accessor';

