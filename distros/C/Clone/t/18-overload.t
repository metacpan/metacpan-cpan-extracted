use strict;
use warnings;
use Test::More;
use Clone qw(clone);

# Test that overloaded objects preserve their overload behavior after cloning.
# Overload magic is stored on the stash (package), not on individual SVs,
# so sv_bless() on the clone should preserve it — but we test to be sure.

# --- Stringification overload ---
{
    package Stringify;
    use overload '""' => sub { "val=$_[0]{v}" }, fallback => 1;
    sub new { bless { v => $_[1] }, $_[0] }
}

{
    my $orig  = Stringify->new(42);
    my $clone = clone($orig);

    is("$clone", "val=42", "stringification overload preserved");
    isnt(\$clone, \$orig,  "clone is a distinct object");
    is(ref($clone), "Stringify", "clone has correct class");

    # Mutating clone doesn't affect original
    $clone->{v} = 99;
    is("$orig",  "val=42", "original unchanged after mutating clone");
    is("$clone", "val=99", "clone reflects its own mutation");
}

# --- Arithmetic overload ---
{
    package Adder;
    use overload
        '+' => sub {
            my ($self, $other) = @_;
            my $val = ref($other) ? $other->{n} : $other;
            Adder->new($self->{n} + $val);
        },
        '""' => sub { $_[0]{n} },
        fallback => 1;
    sub new { bless { n => $_[1] }, $_[0] }
}

{
    my $orig  = Adder->new(10);
    my $clone = clone($orig);

    my $sum = $clone + 5;
    isa_ok($sum, "Adder", "addition returns an Adder");
    is("$sum", 15, "arithmetic overload works on clone");

    # Verify original is unaffected
    is("$orig", 10, "original unchanged");
}

# --- Comparison overload ---
{
    package Cmp;
    use overload
        '<=>' => sub { $_[0]{x} <=> (ref $_[1] ? $_[1]{x} : $_[1]) },
        'cmp' => sub { $_[0]{x} cmp (ref $_[1] ? $_[1]{x} : $_[1]) },
        '""'  => sub { $_[0]{x} },
        fallback => 1;
    sub new { bless { x => $_[1] }, $_[0] }
}

{
    my $a = Cmp->new(3);
    my $b = Cmp->new(7);
    my $ca = clone($a);
    my $cb = clone($b);

    ok($ca < $cb,   "numeric comparison works on clones");
    ok($cb > $ca,   "reverse comparison works on clones");
    is($ca <=> $cb, -1, "spaceship operator on clones");
}

# --- Bool overload ---
{
    package BoolObj;
    use overload
        'bool' => sub { $_[0]{flag} },
        fallback => 1;
    sub new { bless { flag => $_[1] }, $_[0] }
}

{
    my $true  = BoolObj->new(1);
    my $false = BoolObj->new(0);

    my $ct = clone($true);
    my $cf = clone($false);

    ok($ct,   "bool overload: true clone is true");
    ok(!$cf,  "bool overload: false clone is false");
}

# --- Dereference overload (array deref) ---
{
    package ArrayLike;
    use overload '@{}' => sub { $_[0]{items} }, fallback => 1;
    sub new { bless { items => $_[1] }, $_[0] }
}

{
    my $orig  = ArrayLike->new([10, 20, 30]);
    my $clone = clone($orig);

    is_deeply([@$clone], [10, 20, 30], "array deref overload works on clone");

    # Independence
    push @$clone, 40;
    is(scalar @$orig,  3, "original array not modified");
    is(scalar @$clone, 4, "clone array has new element");
}

# --- Multiple overloads on one class ---
{
    package Multi;
    use overload
        '""'   => sub { "M($_[0]{v})" },
        '0+'   => sub { $_[0]{v} },
        'bool' => sub { 1 },
        '+'    => sub { Multi->new($_[0]{v} + (ref $_[1] ? $_[1]{v} : $_[1])) },
        fallback => 1;
    sub new { bless { v => $_[1] }, $_[0] }
}

{
    my $orig  = Multi->new(7);
    my $clone = clone($orig);

    is("$clone",    "M(7)", "multi: string overload on clone");
    cmp_ok($clone, '==', 7, "multi: numeric overload on clone");
    ok($clone,              "multi: bool overload on clone");

    my $sum = $clone + 3;
    is("$sum", "M(10)", "multi: addition overload on clone");
}

# --- Nested overloaded objects ---
{
    my $inner = Stringify->new("inner");
    my $outer = Stringify->new($inner);

    my $clone = clone($outer);
    is(ref($clone->{v}), "Stringify", "nested overloaded object cloned");
    is("$clone->{v}", "val=inner",    "nested overload stringification works");

    # Independence
    $clone->{v}{v} = "changed";
    is("$inner", "val=inner", "nested: original inner unchanged");
}

# --- Overloaded object in array/hash ---
{
    my @arr = (Stringify->new("a"), Stringify->new("b"));
    my $clone = clone(\@arr);

    is("$clone->[0]", "val=a", "overloaded object in cloned array");
    is("$clone->[1]", "val=b", "overloaded object in cloned array [1]");
}

{
    my %hash = (x => Adder->new(5));
    my $clone = clone(\%hash);

    is("$clone->{x}", 5, "overloaded object in cloned hash");
    my $sum = $clone->{x} + 3;
    is("$sum", 8, "arithmetic works on overloaded obj from cloned hash");
}

done_testing;
