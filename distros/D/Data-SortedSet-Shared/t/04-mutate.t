use strict;
use warnings;
use Test::More;
use Data::SortedSet::Shared;

# --- interleaved fuzz vs oracle, validating the B+tree periodically ---
my $z = Data::SortedSet::Shared->new(undef, 5000);
srand(20260622);
my %sc;
my $val_ok = 1;
for my $step (1 .. 80000) {
    my $r = rand();
    if    ($r < 0.45) { my $m = int(rand(2000)); my $s = int(rand(20)) - 10; $z->add($m, $s); $sc{$m} = $s; }
    elsif ($r < 0.65) { my $m = int(rand(2000)); $z->remove($m); delete $sc{$m}; }
    elsif ($r < 0.78) { my $m = int(rand(2000)); my $d = int(rand(6)) - 3;
                        $z->incr($m, $d); $sc{$m} = (exists $sc{$m} ? $sc{$m} : 0) + $d; }
    elsif ($r < 0.89 && %sc) { my @p = $z->pop_min; delete $sc{$p[0]} if @p; }
    elsif (%sc)              { my @p = $z->pop_max; delete $sc{$p[0]} if @p; }
    $val_ok &&= $z->_validate if $step % 1000 == 0;
}
ok $val_ok, 'B+tree invariants hold across 80k interleaved mutations';
ok $z->_validate, 'final validate';

my @ord = sort { $sc{$a} <=> $sc{$b} or $a <=> $b } keys %sc;
is $z->count, scalar(@ord), 'count matches oracle after fuzz';
my %rank = map { $ord[$_] => $_ } 0 .. $#ord;
my ($sc_ok, $rk_ok) = (1, 1);
for my $m (keys %sc) { $sc_ok = 0, last unless $z->score($m) == $sc{$m} }
for my $m (@ord)     { $rk_ok = 0, last unless $z->rank($m)  == $rank{$m} }
ok $sc_ok, 'score() correct after fuzz';
ok $rk_ok, 'rank() correct after fuzz';
my @each;
$z->each(sub { push @each, $_[0] });
is_deeply \@each, \@ord, 'each in order after fuzz';

# --- edge cases ---
my $e = Data::SortedSet::Shared->new(undef, 100);
ok !$e->remove(5), 'remove absent returns false';
is_deeply [$e->pop_min], [], 'pop_min on empty returns ()';
is_deeply [$e->pop_max], [], 'pop_max on empty returns ()';

is $e->incr(7, 3),   3,   'incr on absent member creates at delta';
is $e->score(7),     3,   'incr created the member';
is $e->incr(7, 2.5), 5.5, 'incr existing returns new score';
is $e->add(7, 10),   0,   'add existing returns 0 (update)';
is $e->score(7),     10,  'add updated the score';
is $e->rank(7),      0,   'single member rank 0';
is_deeply [$e->pop_min], [7, 10], 'pop_min returns the only element';
is $e->count, 0, 'empty after popping last';
ok $e->_validate, 'empty tree valid';

# NaN-result guards
eval { $e->incr(5, ("NaN" + 0)) }; like $@, qr/NaN/, 'incr with NaN delta croaks';
$e->add(99, ("Inf" + 0));
eval { $e->incr(99, -("Inf" + 0)) }; like $@, qr/NaN/, 'incr to a NaN result croaks';
$e->clear;

# pop ordering with ties
$e->add($_, $_ % 5) for 1 .. 50;
my ($pm, $ps) = $e->pop_min;
is $ps, 0, 'pop_min takes the lowest score';
my ($xm, $xs) = $e->pop_max;
is $xs, 4, 'pop_max takes the highest score';
ok $e->_validate, 'valid after pops';

# reopen after deletes
my $path = "/tmp/ss-mut-$$.bin";
unlink $path;
{
    my $w = Data::SortedSet::Shared->new($path, 1000);
    $w->add($_, $_) for 1 .. 200;
    $w->remove($_) for grep { $_ % 2 } 1 .. 200;
    $w->sync;
}
{
    my $r = Data::SortedSet::Shared->new($path, 1000);
    is $r->count, 100, 'reopen after deletes: count';
    ok $r->_validate, 'reopened tree valid';
    is $r->score(200), 200, 'reopened surviving member score';
}
unlink $path;

done_testing;
