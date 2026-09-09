#!perl
# `<:` binds as tightly as \ and unary minus, so it takes the smallest term to
# its right. Values do not prove this: (<:$a)+$b and <:($a+$b) agree on every
# obvious input, and so do . - ** and x. Only the optree discriminates, so
# these tests assert where the operator actually sits in the execution order.
use 5.038;
use strict;
use warnings;
use Test::More;
use Confold;

BEGIN {
    plan skip_all => 'B::Concise required' unless eval { require B::Concise; 1 };
}

plan tests => 18;

# Execution-order list of op names for a sub, via B::Concise -exec.
sub exec_ops {
    my ($sub) = @_;
    my $out = '';
    open my $fh, '>', \$out or die $!;
    B::Concise::walk_output($fh);
    B::Concise::compile('-exec', '-src', $sub)->();
    close $fh;
    my @ops;
    for my $line (split /\n/, $out) {
        push @ops, $1 if $line =~ /^\s*\w+\s+<[^>]*>\s+(\w+)/;
    }
    return \@ops;
}

# Index of the confold op, and of the first op named by @$other, in execution
# order. @$other is a list because the peephole renames some ops: a concat with
# a constant operand becomes multiconcat before we ever see it.
sub order {
    my ($sub, $other) = @_;
    my $ops = exec_ops($sub);
    my %want = map { $_ => 1 } @$other;
    my ($ci) = grep { $ops->[$_] eq 'confold' } 0 .. $#$ops;
    my ($oi) = grep { $want{ $ops->[$_] } }     0 .. $#$ops;
    return ($ci, $oi, $ops);
}

# confold runs BEFORE the binop => it applied to the left term only.
sub binds_tight {
    my ($sub, $op, $name) = @_;
    my ($ci, $oi, $ops) = order($sub, $op);
    ok defined $ci, "$name: operator is present in the execution chain"
        or diag "ops: @$ops";
    ok defined $ci && defined $oi && $ci < $oi,
        "$name: binds tighter than @$op"
        or diag "ops: @$ops";
}

# confold runs AFTER the binop => it applied to the whole expression.
sub binds_loose {
    my ($sub, $op, $name) = @_;
    my ($ci, $oi, $ops) = order($sub, $op);
    ok defined $ci && defined $oi && $ci > $oi, "$name: takes the whole @$op"
        or diag "ops: @$ops";
}

my ($a, $b, $c) = (10, 3, 2);
my %h = (k => 5);

binds_tight(sub { my $z = <: $a + $b },   ['add'],                  '<: $a + $b');
binds_tight(sub { my $z = <: $a * $b },   ['multiply'],             '<: $a * $b');
binds_tight(sub { my $z = <: $a . "x" },  ['concat','multiconcat'], '<: $a . "x"');
binds_tight(sub { my $z = <: $a << 2 },   ['left_shift'],           '<: $a << 2');
binds_tight(sub { my $z = <: $h{k} * 2 }, ['multiply'],             '<: $h{k} * 2');

# ** binds tighter than \ and unary minus, so the power is the operand.
binds_loose(sub { my $z = <: $a ** 2 },   ['pow'],                  '<: $a ** 2');

# Parentheses make a term and stop the descent.
binds_loose(sub { my $z = <: ($a + $b) }, ['add'],                  '<: ($a + $b)');
binds_tight(sub { my $z = <: ($a + $b) * $c },
                                          ['multiply'],             '<: ($a + $b) * $c');

# Values still have to come out right.
is( (<: $a + $b),      13,     'value: <: $a + $b' );
is( (<: $a . "x"),     '10x',  'value: <: $a . "x"' );
is( (<: $a ** 2),      100,    'value: <: $a ** 2' );
is( (<: ($a + $b)),    13,     'value: <: ($a + $b)' );
