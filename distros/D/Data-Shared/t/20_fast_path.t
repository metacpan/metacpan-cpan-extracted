use strict;
use warnings;
use Test::More;
use Data::Shared qw(shared_compile sharedc_get sharedc_set sharedc_exists
                    sharedc_delete sharedc_incr sharedc_push sharedc_pop
                    sharedc_call);

# Every case calls one compiled path more than once: the first call only binds.
my $root = Data::Shared->new;
eval {
    $root->mount('cache', 'hashmap:ii', undef, 1024);
    $root->mount('jobs',  'queue:int',  undef, 64);
    1;
} or plan skip_all => "backend unavailable: $@";

my $cp = shared_compile('/cache/1');

# &sub shares the caller's @_ with the callee.
sub amp_get {
    my $v = &sharedc_get;
    return (scalar(@_), $v);
}
sub amp_set {
    my $v = &sharedc_set;
    return (scalar(@_), $v);
}

sharedc_set($root, $cp, 10);
for my $i (1 .. 3) {
    my ($argc, $v) = amp_get($root, $cp);
    is $v,    10, "ampersand-forwarded get returns the value (pass $i)";
    is $argc, 2,  "ampersand-forwarded get leaves the caller's \@_ intact (pass $i)";
}
for my $i (1 .. 3) {
    my ($argc) = amp_set($root, $cp, 20 + $i);
    is $argc, 3, "ampersand-forwarded set leaves the caller's \@_ intact (pass $i)";
    is sharedc_get($root, $cp), 20 + $i, "ampersand-forwarded set stored (pass $i)";
}

my $ci = shared_compile('/cache/42');
for my $pass (1 .. 2) {
    sharedc_set($root, $ci, 100);
    is sharedc_get($root, $ci),    100, "set/get warm (pass $pass)";
    is sharedc_exists($root, $ci), 1,   "exists warm is 1 (pass $pass)";
    sharedc_incr($root, $ci);
    is sharedc_get($root, $ci),    101, "incr warm (pass $pass)";
    sharedc_delete($root, $ci);
    is sharedc_exists($root, $ci), 0,   "exists warm is 0 after delete (pass $pass)";
}

my $cq = shared_compile('/jobs');
for my $pass (1 .. 2) {
    sharedc_push($root, $cq, 7 + $pass);
    is sharedc_pop($root, $cq), 7 + $pass, "push/pop warm (pass $pass)";
}

# Smoke only: no shipped backend writes its push argument, so this cannot prove a copy.
my $ok = eval { sharedc_push($root, $cq, 99); 1 };
ok $ok, 'pushing a literal does not die' or diag $@;
is sharedc_pop($root, $cq), 99, 'literal push round-trips';

# The cold path returns the same values, so only a bind count shows the fast path ran.
{
    my $cold = 0;
    my $bind = \&Data::Shared::_compiled_code;
    no warnings 'redefine';
    local *Data::Shared::_compiled_code = sub { $cold++; return $bind->(@_) };
    my $cw = shared_compile('/cache/7');
    sharedc_set($root, $cw, 1) for 1 .. 5;
    is $cold, 1, 'five sets through one compiled path bind once';
    sharedc_get($root, $cw) for 1 .. 5;
    is $cold, 2, 'a second verb binds once of its own, then stays warm';
    $root->mount('spare', 'hashmap:ii', undef, 8);
    sharedc_get($root, $cw) for 1 .. 3;
    is $cold, 3, 'a new mount retires the binding exactly once';
}

# The binding slot holds a single root, so alternating two roots misses it.
{
    my $other = Data::Shared->new;
    $other->mount('cache', 'hashmap:ii', undef, 1024);
    {
        my $cm = shared_compile('/cache/5');
        sharedc_set($root,  $cm, 1);
        sharedc_set($other, $cm, 2);
        sharedc_get($root, $cm);
        sharedc_get($other, $cm);
        my $resolved = 0;
        my $resolve = \&Data::Shared::_resolve;
        no warnings 'redefine';
        local *Data::Shared::_resolve = sub { $resolved++; return $resolve->(@_) };
        for (1 .. 5) { sharedc_get($root, $cm); sharedc_get($other, $cm) }
        is $resolved, 0, 'ten warm reads alternating two roots resolve nothing again';
        is sharedc_get($root,  $cm), 1, 'and the first root still answers its own value';
        is sharedc_get($other, $cm), 2, 'and the second root answers its own';
    }
}

# sharedc_call has no fast path; only the binder's memo stops a rebuild per call.
{
    my $rebuilt = 0;
    my $resolve = \&Data::Shared::_resolve;
    no warnings 'redefine';
    local *Data::Shared::_resolve = sub { $rebuilt++; return $resolve->(@_) };
    my $cc = shared_compile('/cache');
    sharedc_call($root, $cc, 'size') for 1 .. 5;
    is $rebuilt, 1, 'five sharedc_calls rebind once, not once per call';
}

{
    my $n = 0;
    my $resolve = \&Data::Shared::Registry::resolve_spec;
    no warnings 'redefine';
    local *Data::Shared::Registry::resolve_spec =
        sub { $n++ if ($_[0] // '') eq 'hashmap:ss'; return $resolve->(@_) };
    # This file mounts no composite, so the first ask here fills the memo.
    Data::Shared::Composite::_index_spec() for 1 .. 5;
    cmp_ok $n, '<=', 1, 'five asks for the composite index spec resolve it at most once';
    ok Data::Shared::Composite::_index_spec()->{class}, 'and it still answers a class';
}

done_testing;
