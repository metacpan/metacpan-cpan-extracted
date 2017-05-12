use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'AnyEvent::Retry::Interval::Fibonacci';

my $i = AnyEvent::Retry::Interval::Fibonacci->new( scale => 0.1 );

is_deeply [.1, .1, .2, .3, .5], [ map { scalar $i->next } 1..5 ], 'scalar context works';

$i = AnyEvent::Retry::Interval::Fibonacci->new( scale => 1 );

is_deeply [1, 1, 1, 2, 2, 3], [ map { $i->next } 1..3 ], 'list context works';
is_deeply [3, 4, 5, 5, 8, 6], [ map { $i->next } 1..3 ], 'list context works';

$i->reset;
is_deeply [1, 1, 2, 3, 5], [ map { scalar $i->next } 1..5 ], 'reset works';

done_testing;
