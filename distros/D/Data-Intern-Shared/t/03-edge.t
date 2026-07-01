use strict;
use warnings;
use Test::More;
use Data::Intern::Shared;

# id-space exhaustion
{
    my $in = Data::Intern::Shared->new(undef, 8, 1 << 16);
    my @ids = map { $in->intern("k$_") } 1 .. 8;
    is_deeply \@ids, [0 .. 7], 'first 8 distinct interns get ids 0..7';
    is $in->count, 8, 'count == max_strings';
    ok !defined($in->intern("k9")), 'intern of a new string past max_strings returns undef';
    is $in->intern("k1"), 0, 'an existing string still interns when full (no new id)';
    is $in->count, 8, 'count unchanged after full';
}

# arena exhaustion before id exhaustion
{
    my $in = Data::Intern::Shared->new(undef, 1000, 64);     # tiny arena
    my $n = 0;
    $n++ while $n < 1000 && defined $in->intern("str$n");
    cmp_ok $n, '<', 1000, "arena fills before the id space ($n strings in 64 bytes)";
    ok !defined($in->intern("y" x 1000)), 'a string larger than the remaining arena returns undef';
    cmp_ok $in->count, '>=', 1, 'some strings interned before the arena filled';
}

# a single string larger than the whole arena
{
    my $in = Data::Intern::Shared->new(undef, 10, 64);
    ok !defined($in->intern("a" x 100)), 'string bigger than arena_bytes -> undef';
    is $in->count, 0, 'nothing interned';
    ok defined($in->intern("ok")), 'a fitting string still interns afterward';
}

# clear resets ids and arena
{
    my $in = Data::Intern::Shared->new(undef, 100, 4096);
    $in->intern($_) for qw(a b c);
    is $in->count, 3, 'three interned';
    cmp_ok $in->arena_used, '>', 0, 'arena used';
    $in->clear;
    is $in->count, 0, 'clear: count 0';
    is $in->arena_used, 0, 'clear: arena_used 0';
    ok !defined($in->id_of('a')), 'clear: old strings gone';
    is $in->intern('z'), 0, 'clear: ids restart at 0';
}

# heavy-load probing (collision + fp-skip + full-compare paths) verified by round-trip
{
    my $in = Data::Intern::Shared->new(undef, 2000, 1 << 20);    # hash_slots 4096
    my %id;
    $id{"item-$_-payload"} = $in->intern("item-$_-payload") for 1 .. 1400;   # load ~0.68
    my $ok = 1;
    for my $s (keys %id) { $ok = 0, last unless $in->id_of($s) == $id{$s} && $in->string($id{$s}) eq $s }
    ok $ok, 'round-trip correct under ~0.68 hash load (probe / fp-skip / full-compare)';
    is $in->count, 1400, 'count under heavy load';
}

# stats
{
    my $in = Data::Intern::Shared->new(undef, 1000, 8192);
    $in->intern("x$_") for 1 .. 100;
    my $s = $in->stats;
    is $s->{count}, 100, 'stats: count';
    is $s->{ops}, 100, 'stats: ops counts intern calls';
    is $s->{max_strings}, 1000, 'stats: max_strings';
    cmp_ok $s->{hash_slots}, '>', 1000, 'stats: hash_slots > max_strings';
    ok $s->{hash_load} > 0 && $s->{hash_load} < 1, 'stats: hash_load';
    cmp_ok $s->{arena_used}, '>', 0, 'stats: arena_used';
    is $s->{arena_bytes}, 8192, 'stats: arena_bytes';
    ok $s->{arena_load} > 0 && $s->{arena_load} < 1, 'stats: arena_load';
    cmp_ok $s->{mmap_size}, '>', 0, 'stats: mmap_size';
}

done_testing;
