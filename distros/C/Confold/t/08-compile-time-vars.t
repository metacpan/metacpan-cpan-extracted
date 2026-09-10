#!perl
# A variable declared with `<:` has a value the compiler can read. Perl cannot
# normally do this: a `my` variable is not populated until run time, so code
# running at compile time - a BEGIN block, or a call checker - sees undef.
use 5.038;
use strict;
use warnings;
use Test::More;
use Confold;

plan tests => 15;

my $str = <: "x:Required";
my $num = <: 42;

is $str, "x:Required", 'the variable holds its value at run time';
is $num, 42,           'and so does a numeric one';

is( (<: $str), "x:Required", 'reading it back through the operator' );
is( (<: $num), 42,           'reading a number back' );

# The compile-time half. These BEGIN blocks run before the assignments above
# have executed, so a plain read is undef and the operator read is not.
our ($seen_plain, $seen_confold);
BEGIN { $seen_plain = 'unset' }

{
    my $inner = <: "inner value";
    our $from_begin;
    BEGIN { $from_begin = 'unset' }
    BEGIN { $from_begin = eval q{ <: $inner } }
    is $from_begin, undef, 'a BEGIN block compiled before the declaration sees nothing'
        or diag "got: $from_begin";
}

my $early = <: "early";
our $begin_saw;
BEGIN { $begin_saw = undef }
BEGIN { $begin_saw = (<: $early) }
is $begin_saw, "early", 'a BEGIN block after the declaration reads the value';

our $begin_plain;
BEGIN { $begin_plain = defined $early ? $early : undef }
ok !defined $begin_plain, 'the same BEGIN block reading it plainly sees undef';

# Nested subs capture it the same way, through the outer pad.
sub nested { return (<: $early) }
is nested(), "early", 'a nested sub resolves it too';

# The operator read compiles to a constant, not a variable read.
SKIP: {
    skip 'B::Concise required', 2 unless eval { require B::Concise; 1 };

    my $probe = sub { my $q = <: $early; $q };
    my $out = '';
    open my $fh, '>', \$out or die $!;
    B::Concise::walk_output($fh);
    B::Concise::compile('-exec', $probe)->();
    close $fh;

    # B::Concise brackets a const's SV when it lives in the pad, under
    # ithreads, and parenthesises it when the op carries it directly.
    like   $out, qr/const[\[(]PV "early"[\])]/,
                                  'it compiles to the constant itself';
    unlike $out, qr/\bconfold\b/, 'no runtime operator is left behind';
}

# Passing one to a subroutine hands over the value, not the variable. That is
# what lets a call made during compilation receive it: at that point a plain
# `my` variable is still empty.
my $arg = <: "argument value";

sub echo { return $_[0] }
is echo($arg), "argument value", 'passed to a sub at run time';

our $begin_arg;
BEGIN { $begin_arg = undef }
BEGIN { $begin_arg = echo($arg) }
is $begin_arg, "argument value", 'passed to a sub called during compilation';

# The value is passed, so @_ aliasing cannot write back through it. For a
# variable declared constant that is the point, not a limitation.
sub clobber { $_[0] = "changed"; return }
{
    my $ok = eval { clobber($arg); 1 };
    ok !$ok, 'a sub cannot modify it through @_';
    is $arg, "argument value", 'and the variable is unchanged';
}

# Assigning to one retires it: later reads go back to reading the variable,
# rather than returning a value that is no longer true.
{
    my $reassigned = <: "first";
    $reassigned = "second";
    is( (<: $reassigned), "second", 'assignment retires the recorded value' );
}
