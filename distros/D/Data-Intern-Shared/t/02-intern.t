use strict;
use warnings;
use Test::More;
use Data::Intern::Shared;

my $in = Data::Intern::Shared->new(undef, 100_000, 8 << 20);
srand(20260623);
my (%id, @rev);
my $next = 0;
my ($dedup, $dense) = (1, 1);
for (1 .. 40_000) {
    my $len = int(rand(24));
    my $s = join "", map { chr(97 + int rand 26) } 1 .. $len;   # random a-z, many repeats
    my $id = $in->intern($s);
    if (exists $id{$s}) { $dedup = 0 unless $id == $id{$s} }
    else { $dense = 0 unless $id == $next; $id{$s} = $id; $rev[$id] = $s; $next++ }
}
ok $dedup, 'intern dedups: same string -> same id';
ok $dense, 'ids are dense and sequential (0 .. count-1)';
is $in->count, $next, 'count == distinct strings';

my ($rt_id, $rt_str, $rt_ex) = (1, 1, 1);
for my $s (keys %id) {
    $rt_id  = 0 unless $in->id_of($s) == $id{$s};
    $rt_str = 0 unless $in->string($id{$s}) eq $s;
    $rt_ex  = 0 unless $in->exists($s);
}
ok $rt_id,  'id_of round-trips for every string';
ok $rt_str, 'string round-trips for every id';
ok $rt_ex,  'exists true for every interned string';

ok !defined($in->id_of("--absent--")),  'id_of of an absent string is undef';
ok !$in->exists("--absent--"),          'exists false for an absent string';
ok !defined($in->string($in->count)),   'string of an out-of-range id is undef';
ok !defined($in->string($in->count + 100)), 'string far out of range is undef';

# byte-accurate keys: empty, embedded NUL, high bytes
my $empty = $in->intern("");
is $in->string($empty), "", 'empty string interns and round-trips';
is $in->intern(""), $empty, 're-intern empty -> same id';
my $nul = $in->intern("a\0b\0c");
is $in->string($nul), "a\0b\0c", 'embedded NULs preserved';
is length($in->string($nul)), 5, 'embedded-NUL length correct';
my $hi = $in->intern("\xff\x00\xfe");
is $in->string($hi), "\xff\x00\xfe", 'high bytes preserved';

# reopen preserves the whole mapping
my $path = "/tmp/intern-rt-$$.bin";
unlink $path;
my @words = qw(alpha beta gamma delta alpha beta);
my @ids;
{
    my $w = Data::Intern::Shared->new($path, 100, 4096);
    push @ids, $w->intern($_) for @words;
    $w->sync;
}
{
    my $r = Data::Intern::Shared->new($path, 100, 4096);
    is $r->count, 4, 'reopen: count (4 distinct of 6)';
    is $r->id_of('gamma'), $ids[2], 'reopen: id_of preserved';
    is $r->string($ids[0]), 'alpha', 'reopen: string preserved';
    is $r->intern('alpha'), $ids[0], 'reopen: re-intern existing -> same id';
    is $r->intern('epsilon'), 4, 'reopen: new string -> next id';
}
unlink $path;

done_testing;
