#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Clone qw(clone);

BEGIN {
    eval 'use Scalar::Util qw( weaken isweak );';
    if ($@) {
        plan skip_all => "Scalar::Util::weaken not available";
        exit;
    }
}

plan tests => 16;

# GH #15 - Weakened refs always clone as undef
# When cloning a structure with weakened references, Clone should
# preserve the weakness and keep referents alive when strong
# references to them exist elsewhere in the clone graph.

{
    package Parent;
    sub new { bless { children => [] }, shift }

    package Child;
    sub new {
        my ($class, $parent) = @_;
        my $child = bless { parent => $parent }, $class;
        Scalar::Util::weaken($child->{parent});
        push @{ $parent->{children} }, $child;
        return $child;
    }
}

# Test 1: Clone from parent side (strong ref to child, weak ref back)
# This is the primary fix: when the referent has strong references
# elsewhere in the clone graph, the weakened ref should survive.
{
    my $p = Parent->new();
    my $c = Child->new($p);

    my $p_clone = clone($p);

    ok(defined $p_clone->{children}[0]{parent},
       'weakened ref survives when cloning from parent side');
    isnt($p_clone, $p, 'cloned parent is a different object');
    is($p_clone->{children}[0]{parent}, $p_clone,
       'cloned child points to cloned parent (not original)');
    ok(Scalar::Util::isweak($p_clone->{children}[0]{parent}),
       'weakened ref is still weak after cloning parent');
}

# Test 2: Multiple children with weakened refs to same parent
{
    my $p = Parent->new();
    my $c1 = Child->new($p);
    my $c2 = Child->new($p);

    my $p_clone = clone($p);

    ok(defined $p_clone->{children}[0]{parent},
       'first child weakened ref survives');
    ok(defined $p_clone->{children}[1]{parent},
       'second child weakened ref survives');
    is($p_clone->{children}[0]{parent}, $p_clone->{children}[1]{parent},
       'both children point to same cloned parent');
    ok(Scalar::Util::isweak($p_clone->{children}[0]{parent}),
       'first child ref is weak');
    ok(Scalar::Util::isweak($p_clone->{children}[1]{parent}),
       'second child ref is weak');
}

# Test 3: Hash with both strong and weak ref to same target
{
    my $data = { value => 42 };
    my $holder = { strong => $data, weak => $data };
    weaken($holder->{weak});

    my $cloned = clone($holder);

    ok(defined $cloned->{weak}, 'weakened hash value survives when strong ref exists');
    is($cloned->{weak}{value}, 42, 'weakened ref points to correct data');
    is($cloned->{strong}, $cloned->{weak},
       'strong and weak refs point to same cloned object');
    ok(!Scalar::Util::isweak($cloned->{strong}),
       'strong ref remains strong');
    ok(Scalar::Util::isweak($cloned->{weak}),
       'weak ref remains weak');
}

# Test 4: Standalone weakened ref with no strong ref in clone graph
# When the referent has no strong references in the clone graph,
# the weakened ref correctly becomes undef (same as Storable::dclone).
{
    my $p = Parent->new();
    my $c = Child->new($p);

    my $c_clone = clone($c);

    ok(!defined $c_clone->{parent},
       'weakened ref to object with no strong ref in clone becomes undef');
    # This is correct: the cloned parent has no independent strong reference,
    # so it gets collected when the weak reference is established.
}

# Test 5: Circular weak reference (existing test from t/06-refcnt.t)
{
    my $a = bless {}, 'Test::Circular';
    my $b = { r => $a };
    $a->{r} = $b;
    weaken($b->{'r'});

    my $c = clone($a);
    ok(defined $c->{r}, 'circular weak reference survives cloning');
}
