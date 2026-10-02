#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# SVt_PVOBJ (class instances) requires Perl 5.38+
BEGIN {
    plan skip_all => 'Perl 5.38+ required for class feature'
        unless $] >= 5.038;
    eval { require Scalar::Util; 1 }
        or plan skip_all => 'Scalar::Util not available';
    eval { require B; 1 }
        or plan skip_all => 'B not available';
    plan tests => 17;
}

use Clone qw(clone);
use Scalar::Util qw(refaddr);

# Tests 1-3: basic field cloning and class preservation
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestPoint {
        field $x :param;
        field $y :param;
        method x { $x }
        method y { $y }
    }

    my $orig = CloneTestPoint->new(x => 3, y => 7);
    my $copy = clone($orig);

    is(ref($copy), 'CloneTestPoint', 'clone preserves class name');
    is($copy->x(), 3, 'clone preserves field x');
    is($copy->y(), 7, 'clone preserves field y');
    1;
} or die "basic field cloning: $@";

# Tests 4-5: field independence (clone mutation does not affect original)
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestCounter {
        field $count :param;
        method count { $count }
        method inc { $count++ }
    }

    my $orig = CloneTestCounter->new(count => 0);
    my $copy = clone($orig);
    $copy->inc();
    $copy->inc();

    is($copy->count(), 2, 'cloned counter incremented independently');
    is($orig->count(), 0, 'original counter unchanged');
    1;
} or die "field independence: $@";

# Tests 6-7: nested class objects are deep-cloned
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestInner {
        field $val :param;
        method val { $val }
    }

    class CloneTestOuter {
        field $child :param;
        method child { $child }
    }

    my $inner = CloneTestInner->new(val => 42);
    my $outer = CloneTestOuter->new(child => $inner);
    my $copy  = clone($outer);

    is($copy->child()->val(), 42, 'nested class field value preserved');
    isnt(refaddr($outer->child()), refaddr($copy->child()),
         'nested class object is a separate instance');
    1;
} or die "nested class: $@";

# Tests 8-9: reference fields are deep-cloned (not shared)
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestWithRef {
        field $data :param;
        method data { $data }
    }

    my $hashref = { a => 1, b => [2, 3] };
    my $orig = CloneTestWithRef->new(data => $hashref);
    my $copy = clone($orig);

    $copy->data()->{a} = 99;
    is($orig->data()->{a}, 1, 'original ref field unchanged after clone mutation');
    is($copy->data()->{a}, 99, 'cloned ref field holds mutated value');
    1;
} or die "ref field isolation: $@";

# Test 10: class object inside a circular hash structure
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestNode {
        field $value :param;
        method value { $value }
    }

    my $node = CloneTestNode->new(value => 'hello');
    my $container = { node => $node, self => undef };
    $container->{self} = $container;

    my $copy = clone($container);
    is($copy->{node}->value(), 'hello',
       'class object inside circular structure cloned correctly');
    1;
} or die "circular structure: $@";

# Test 11: depth-limited clone still produces a blessed object
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestSimple {
        field $v :param;
        method v { $v }
    }

    my $orig = CloneTestSimple->new(v => 10);
    my $copy = clone($orig, 2);
    is(ref($copy), 'CloneTestSimple', 'depth-limited clone preserves class');
    1;
} or die "depth limit: $@";

# Test 12: survives repeated clone/destroy cycles
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestLeak {
        field $x :param;
    }

    my $before = CloneTestLeak->new(x => 1);
    for (1 .. 500) {
        my $tmp = clone($before);
    }
    pass('survives 500 clone/destroy cycles');
    1;
} or die "memory cycles: $@";

# Tests 13-14: an instance referenced twice stays shared in the clone, and
# re-blessing the cached referent must not leak a reference to the stash.
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestShared {
        field $value :param;
        method value { $value }
    }

    my $obj  = CloneTestShared->new(value => 'x');
    my $copy = clone({ a => $obj, b => $obj });
    is(refaddr($copy->{a}), refaddr($copy->{b}),
       'instance referenced twice stays shared in the clone');

    my $stash = B::svref_2object(\%CloneTestShared::);
    clone({ a => $obj, b => $obj }) for 1 .. 5;   # warm up
    my $before = $stash->REFCNT;
    clone({ a => $obj, b => $obj }) for 1 .. 100;
    is($stash->REFCNT, $before,
       'cloning an aliased instance does not leak stash references');
    1;
} or die "shared instance: $@";

# Tests 15-17: a class with no fields at all.  The field-cloning block is
# skipped entirely for these (MAXFIELD is -1), so the clone's field array
# must already be in a valid empty state or freeing it walks garbage.
eval q{
    use feature 'class';
    no warnings 'experimental::class';

    class CloneTestMarker {
        method tag { 'm' }
    }

    my $orig = CloneTestMarker->new;
    my $copy = clone($orig);

    is(ref($copy), 'CloneTestMarker', 'field-less class name preserved');
    is($copy->tag(), 'm', 'field-less clone responds to methods');
    isnt(refaddr($orig), refaddr($copy), 'field-less clone is a new instance');

    undef $copy;                              # free the clone explicitly
    for (1 .. 200) { my $tmp = clone($orig) } # and repeatedly
    1;
} or die "field-less class: $@";
