use strict;
use warnings;
use Test::More;

use ok 'AnyEvent::Retry::Interval::Multi';

my $m = AnyEvent::Retry::Interval::Multi->new(
    first => { Constant => { interval => .5 } },
    after => -2,
    then  => { Multi => {
        first => 'Fibonacci',
        after => 10,
        then  => { Multi => {
            first => { Constant => { interval => 10 } },
            after => -6,
            then  => { Constant => { interval => 60 } },
        }},
    }},
);

for(1..2){
    is_deeply
        [map { scalar $m->next } 1..22],
        [.5, .5,                          # constant .5
         1, 1, 2, 3, 5, 8,                # fib
         10, 10, 10, 10, 10, 10,          # constant 10
         60, 60, 60, 60, 60, 60, 60, 60], # constant 60
      'multi works in scalar context';
    $m->reset;
}

for(1..2){
    is_deeply
        [map { $m->next } 1..22],
        [.5, 1, .5, 2,
         1, 3, 1, 4, 2, 5, 3, 6, 5, 7, 8, 8,
         10, 9, 10, 10, 10, 11, 10, 12, 10, 13, 10, 14,
         60, 15, 60, 16, 60, 17, 60, 18, 60, 19, 60, 20, 60, 21, 60, 22],
      'multi works in list context';
    $m->reset;
}

done_testing;
