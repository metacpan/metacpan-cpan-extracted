use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# get_or_set returns undef -- ONE undef, not an empty list -- when it cannot
# insert.  t/15 checks that with defined() in scalar context, where an XSUB
# returning nothing also reads as undef.  Bind the result as a list, on every
# variant, so `my %h = (v => $m->get_or_set(...))` keeps its pairing.

my @variants = qw(II IS SI SS I16 I16S I32 I32S SI16 SI32);
my $dir = tempdir(CLEANUP => 1);
for my $v (@variants) {
    my $cls = "Data::HashMap::Shared::$v";
    eval "require $cls; 1" or die $@;
    my $m = $cls->new("$dir/gos-$v.shm", 4);          # tiny, LRU off: fills up
    my $stored = 0;
    for my $k (1 .. 1000) { $m->put($k, $k) or last; $stored++ }
    ok $stored > 0 && $stored < 1000, "$v: non-LRU map filled after $stored inserts";
    ok !$m->put(5000, 5000), "$v: a further put is refused";

    my @r = $m->get_or_set(6000, 6000);
    is scalar @r, 1, "$v: get_or_set on a full map returns exactly one value";
    ok !defined $r[0], "$v: ... and that value is undef";
    is_deeply [$m->get_or_set(1, 99)], [1], "$v: get_or_set on a present key returns its value";
}
done_testing;
