use strict;
use warnings;
use Test::More;
use Data::Queue::Shared::Str;

my $q = Data::Queue::Shared::Str->new(undef, 64, 1 << 16);
my ($a10, $b10, $c10, $d30) = ('a' x 10, 'b' x 10, 'c' x 10, 'd' x 30);

for my $pop ([pop_multi => sub { $q->pop_multi(@_) }],
             [pop_wait_multi => sub { my $n = shift; $q->pop_wait_multi($n, 1, @_) }]) {
    my ($name, $code) = @$pop;
    $q->push($_) for $a10, $b10, $c10, $d30, 'e';
    is_deeply [ $code->(10, 25) ], [$a10, $b10], "$name: stops before the element that would exceed max_bytes";
    is_deeply [ $code->(10, 5) ], [$c10], "$name: the first element comes even if it alone exceeds it";
    is_deeply [ $code->(10, 30) ], [$d30], "$name: a batch may fill max_bytes exactly";
    is_deeply [ $code->(10, undef) ], ['e'], "$name: undef means no byte limit";
    $q->push($_) for $a10, $b10, $c10;
    is_deeply [ $code->(2, 1000) ], [$a10, $b10], "$name: the count limit still applies";
    is_deeply [ $code->(10) ], [$c10], "$name: no byte limit by default";
}

my $euro = chr(0x20ac) x 3;    # 9 bytes stored
$q->push($_) for $euro, $euro;
is_deeply [ $q->pop_multi(10, 17) ], [$euro], 'max_bytes counts stored UTF-8 bytes, not characters';
is_deeply [ $q->pop_multi(10, 9) ], [$euro], '  and the rest stays queued';

done_testing;
