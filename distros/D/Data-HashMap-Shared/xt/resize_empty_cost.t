use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);

plan skip_all => 'author tests' unless $ENV{AUTHOR_TESTING};
my $load = do {
    if (open my $f, '<', '/proc/loadavg') { (split ' ', <$f>)[0] } else { undef }
};
plan skip_all => 'no /proc/loadavg, so a timing ratio cannot be qualified' unless defined $load;
plan skip_all => "machine too loaded for a timing ratio (loadavg $load)" if $load > 4;

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# A resize with next to nothing to move must not scan the whole table slot by
# slot. reserve on a one-entry map is priced against clear (one memset over the
# states); the shrink after the last entry goes against the shrink that leaves
# one entry. Both walk the states bytewise, so the ratio holds under any
# compiler and a sanitizer.

my $n = 1_000_000;
for my $v (qw(II SS)) {
    my $m = "Data::HashMap::Shared::$v"->new(undef, $n);
    my @k = $v eq 'II' ? (1, 2) : ('k1', 'k2');
    my $val = $v eq 'II' ? 1 : 'v';
    my ($reserve, $clear, $empty, $one_left) = (9e9) x 4;
    for (1 .. 5) {
        $m->put($k[0], $val);
        my $t = time; $m->reserve($n) or die 'reserve refused'; my $d = time - $t;
        $reserve = $d if $d < $reserve;
        $t = time; $m->clear; $d = time - $t;
        $clear = $d if $d < $clear;

        $m->put($k[0], $val);
        $m->reserve($n) or die 'reserve refused';
        $t = time; $m->remove($k[0]); $d = time - $t;
        $empty = $d if $d < $empty;

        $m->put($_, $val) for @k;
        $m->reserve($n) or die 'reserve refused';
        $t = time; $m->remove($k[0]); $d = time - $t;
        $one_left = $d if $d < $one_left;
        $m->clear;
    }
    cmp_ok $reserve, '<', 5 * $clear,
        sprintf('%s: reserve takes %.3f ms, clear of the same table %.3f ms', $v, $reserve * 1e3, $clear * 1e3);
    cmp_ok $empty, '<', 0.6 * $one_left,
        sprintf('%s: the shrink after the last entry goes takes %.3f ms, one that leaves an entry %.3f ms',
                $v, $empty * 1e3, $one_left * 1e3);
}

done_testing;
