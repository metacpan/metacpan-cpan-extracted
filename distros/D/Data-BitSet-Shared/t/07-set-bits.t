use strict;
use warnings;
use Test::More;
use Data::BitSet::Shared;

for my $cap (1, 63, 64, 65, 127, 128, 129, 1024, 65537) {
    my $b = Data::BitSet::Shared->new(undef, $cap);
    is_deeply [$b->set_bits], [], "$cap: empty list";
    is scalar($b->set_bits), 0, "$cap: empty scalar count";
    my @bits = grep { $_ % 7 == 0 || $_ == $cap - 1 } 0 .. $cap - 1;
    $b->set($_) for reverse @bits;
    is_deeply [$b->set_bits], \@bits, "$cap: sparse bits in ascending order";
    is scalar($b->set_bits), scalar(@bits), "$cap: scalar counts sparse bits";
    $b->set_bits;
    is $b->count, scalar(@bits), "$cap: void context preserves bits";
    $b->fill;
    is_deeply [$b->set_bits], [0 .. $cap - 1], "$cap: full bitset";
    is scalar($b->set_bits), $cap, "$cap: scalar counts full bitset";
    $b->freeze;
    is_deeply [$b->set_bits], [0 .. $cap - 1], "$cap: frozen bitset";
}

{
    package Local::Filtered;
    our @ISA = ('Data::BitSet::Shared');
    sub capacity { 4 }
    sub test { $_[1] % 2 }
}
my $subclass = Local::Filtered->new(undef, 8);
is_deeply [$subclass->set_bits], [1, 3], 'subclass query overrides still apply';
is scalar($subclass->set_bits), 2, 'subclass scalar behavior preserved';

my $destroyed = Data::BitSet::Shared->new(undef, 8);
$destroyed->DESTROY;
eval { my @bits = $destroyed->set_bits };
like $@, qr/destroyed/, 'enumeration rejects a destroyed handle';

done_testing;
