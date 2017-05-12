use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'AnyEvent::Retry::Interval::Constant';

my $i = AnyEvent::Retry::Interval::Constant->new( interval => 2 );

is_deeply [2, 2, 2, 2, 2], [ map { scalar $i->next } 1..5 ], 'scalar context works';

is $i->counter, 5, 'counter is at 5';
$i->reset;
is $i->counter, 0, 'back to 0';

is_deeply [2, 1, 2, 2, 2, 3], [ map { $i->next } 1..3 ], 'list context works';
is_deeply [2, 4, 2, 5, 2, 6], [ map { $i->next } 1..3 ], 'list context works';

$i->reset;
is_deeply [2, 1, 2, 2, 2, 3], [ map { $i->next } 1..3 ], 'reset works';

done_testing;
