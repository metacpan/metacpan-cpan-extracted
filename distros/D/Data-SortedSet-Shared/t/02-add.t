use strict;
use warnings;
use Test::More;
use Data::SortedSet::Shared;

# --- randomized add vs a Perl oracle; validate the B+tree periodically ---
my $z = Data::SortedSet::Shared->new(undef, 50000);
srand(20260622);
my %oracle;
my $val_ok = 1;
for my $i (1 .. 30000) {
    my $m = int(rand(1e9));
    next if exists $oracle{$m};
    my $s = int(rand(40)) - 20;          # ties (40 distinct scores) + negatives
    $z->add($m, $s);
    $oracle{$m} = $s;
    $val_ok &&= $z->_validate if $i % 2000 == 0;
}
ok $val_ok, 'B+tree invariants hold across 30k inserts (periodic validate)';
ok $z->_validate, 'final validate (depth/fill/counts/leaf-order/index)';
is $z->count, scalar(keys %oracle), 'count matches oracle';

my $sc_ok = 1;
for my $m (keys %oracle) {
    $sc_ok = 0, last unless defined($z->score($m)) && $z->score($m) == $oracle{$m};
}
ok $sc_ok, 'score() matches oracle for every member';
ok !$z->exists(-12345) && !defined($z->score(-12345)), 'absent member: exists 0, score undef';

# re-add semantics
my ($any) = keys %oracle;
is $z->add($any, $oracle{$any}), 0, 're-add an existing member returns 0';
ok !$z->exists(2_000_000_000), 'fresh member absent before add';
is $z->add(2_000_000_000, 5), 1, 'add of a new member returns 1';

# NaN
eval { $z->add(1, ("NaN" + 0)) }; like $@, qr/NaN/, 'NaN score croaks';

# full pool
my $f = Data::SortedSet::Shared->new(undef, 4);
is $f->add(1, 1), 1, 'add 1/4';
is $f->add(2, 2), 1, 'add 2/4';
is $f->add(3, 3), 1, 'add 3/4';
is $f->add(4, 4), 1, 'add 4/4';
ok !defined($f->add(5, 5)), 'add past max_entries returns undef';
ok $f->_validate, 'small full set is valid';

# reopen persistence (ties across the seam)
my $path = "/tmp/ss-add-$$.bin";
unlink $path;
{
    my $w = Data::SortedSet::Shared->new($path, 100);
    $w->add(7, 1.5); $w->add(3, -2.5); $w->add(9, 1.5);
    $w->sync;
}
{
    my $r = Data::SortedSet::Shared->new($path, 100);
    is $r->count, 3, 'reopened count';
    is $r->score(7), 1.5, 'reopened score';
    is $r->score(3), -2.5, 'reopened negative score';
    ok $r->_validate, 'reopened tree valid';
}
unlink $path;

done_testing;
