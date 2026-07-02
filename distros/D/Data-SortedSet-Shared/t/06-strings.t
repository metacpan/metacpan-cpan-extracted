use strict;
use warnings;
use Test::More;
BEGIN {
    eval { require Data::Intern::Shared; 1 }
        or plan skip_all => 'Data::Intern::Shared is required for string-keyed sets';
}
use Data::SortedSet::Shared::Strings;

my $z = Data::SortedSet::Shared::Strings->new(max => 1000);
isa_ok $z, 'Data::SortedSet::Shared::Strings';
isa_ok $z->set, 'Data::SortedSet::Shared';
isa_ok $z->key_table, 'Data::Intern::Shared';

is $z->add("alice", 1550), 1, 'add new returns 1';
is $z->add("bob", 1000),   1, 'add bob';
is $z->add("carol", 100),  1, 'add carol';
is $z->add("alice", 1550), 0, 're-add same key returns 0 (update)';
is $z->count, 3, 'count';
is $z->score("alice"), 1550, 'score';
ok !defined($z->score("nobody")), 'score of absent key is undef';
ok $z->exists("bob"), 'exists';
ok !$z->exists("nobody"), 'absent key not exists';

# order by score: carol(100) < bob(1000) < alice(1550)
is $z->rank("carol"), 0, 'rank carol = 0';
is $z->rank("alice"), 2, 'rank alice = 2';
is $z->rev_rank("alice"), 0, 'rev_rank alice = 0';
ok !defined($z->rank("nobody")), 'rank of absent key undef';
is $z->at_rank(0),  "carol", 'at_rank 0';
is $z->at_rank(-1), "alice", 'at_rank -1 (top)';
ok !defined($z->at_rank(99)), 'at_rank out of range undef';

is_deeply [$z->range_by_rank(0, -1)],       [qw(carol bob alice)], 'range_by_rank all';
is_deeply [$z->rev_range_by_rank(0, 1)],    [qw(alice bob)],       'rev_range_by_rank top 2';
is_deeply [$z->range_by_score(0, 1000)],    [qw(carol bob)],       'range_by_score';
is_deeply [$z->rev_range_by_score(1000, 0)],[qw(bob carol)],       'rev_range_by_score';
is $z->count_in_score(0, 1000), 2, 'count_in_score';
is_deeply [$z->range_by_rank(0, 1, withscores => 1)], ['carol', 100, 'bob', 1000], 'withscores pairs';
is_deeply [$z->range_by_score(0, 2000, limit => 1, offset => 1)], ['bob'], 'limit/offset';

is $z->incr("alice", 50), 1600, 'incr returns new score';
is $z->incr("dave", 7),   7,    'incr creates an absent key';
is $z->score("dave"), 7, 'incr created';

is_deeply [$z->peek_min], ['dave', 7],  'peek_min';
is $z->count, 4, 'peek does not remove';
is_deeply [$z->pop_min], ['dave', 7],   'pop_min';
is $z->count, 3, 'pop removed';
is_deeply [$z->pop_max], ['alice', 1600], 'pop_max';
is_deeply [$z->peek_min], ['carol', 100], 'peek_min after pops';
is_deeply [$z->peek_max], ['bob', 1000], 'peek_max';

my $st = $z->stats;
ok exists $st->{set} && exists $st->{keys}, 'stats has set + keys sections';
is $st->{set}{count}, $z->count, 'stats set count matches';
cmp_ok $st->{keys}{count}, '>=', $z->count, 'stats keys count >= members (permanent interning)';

my @each;
$z->each(sub { push @each, [@_] });
is scalar(@each), $z->count, 'each visits every member';
is_deeply [map { $_->[0] } @each], [qw(carol bob)], 'each in score order, decoded to strings';

ok $z->remove("bob"), 'remove returns true';
ok !$z->exists("bob"), 'removed';
ok !$z->remove("bob"), 'remove absent returns false';

# add_many + clear
is $z->add_many([ ['m1', 5], ['m2', 6], 'bad', ['m3', 7] ]), 3, 'add_many counts new (skips malformed)';
$z->clear;
is $z->count, 0, 'clear empties the set';
ok !$z->exists("carol"), 'clear forgot the keys too';

# reopen (file-backed): both backing stores reopen
my $d = "/tmp/sss-$$";
unlink "$d.set", "$d.keys";
{
    my $w = Data::SortedSet::Shared::Strings->new(set => "$d.set", keys => "$d.keys", max => 100);
    $w->add("foo", 5); $w->add("bar", 3);
    $w->sync;
}
{
    my $r = Data::SortedSet::Shared::Strings->new(set => "$d.set", keys => "$d.keys", max => 999);
    is $r->count, 2, 'reopen count';
    is $r->score("foo"), 5, 'reopen score';
    is_deeply [$r->range_by_rank(0, -1)], [qw(bar foo)], 'reopen preserves order + keys';
    $r->unlink;
}
ok !-e "$d.set" && !-e "$d.keys", 'unlink removed both backing files';

# wrap two existing objects
my $w = Data::SortedSet::Shared::Strings->wrap(
    Data::SortedSet::Shared->new(undef, 10),
    Data::Intern::Shared->new(undef, 10),
);
$w->add("zed", 1);
is $w->score("zed"), 1, 'wrap() composes existing objects';

# the parent class's new_strings() convenience constructor (delegates to Strings->new)
{
    require Data::SortedSet::Shared;
    my $z2 = Data::SortedSet::Shared->new_strings(max => 1000);
    isa_ok $z2, 'Data::SortedSet::Shared::Strings', 'new_strings returns a Strings object';
    is $z2->add("x", 10), 1, 'new_strings: add works';
    is $z2->score("x"), 10, 'new_strings: score round-trip';
    is $z2->count, 1, 'new_strings: count';
}

# add_many skips a NaN-scored row WITHOUT interning its key (no ghost slot)
{
    my $z3 = Data::SortedSet::Shared::Strings->new(max => 100);
    my $before = $z3->key_table->count;
    my $n = $z3->add_many([ ["good", 5], ["bad", "NaN"+0], ["good2", 7] ]);
    is $n, 2, 'add_many: NaN-scored row not added';
    ok !$z3->exists("bad"), 'add_many: NaN-row member absent';
    is $z3->key_table->count, $before + 2, 'add_many: NaN-row key not interned (no ghost slot)';
}

done_testing;
