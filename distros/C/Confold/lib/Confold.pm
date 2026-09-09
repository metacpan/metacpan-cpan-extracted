package Confold;

use 5.038;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

sub import   { _hint_on() }
sub unimport { _hint_off() }

1;

__END__

=encoding utf8

=head1 NAME

Confold - the C<< <: >> compile time constant operator

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Confold;

    my $x = <: 42;         # folded at compile time
    my $y = <: "hello";    # folded at compile time
    my $z = <: $variable;  # runtime: creates immutable copy

=head1 DESCRIPTION

Introduces the C<< <: >> prefix operator, which marks an expression as a
compile-time constant. When the operand is a literal value, the operator is
folded away entirely at compile time, leaving a plain constant with no runtime
overhead at all. For non-constant operands, a runtime path creates an immutable
copy.

The operator exists to say something to the compiler that a function call
cannot. By the time an ordinary subroutine call has been built, the expression
is wrapped in an C<entersub> and every call checker and optimisation pass
downstream has lost sight of what it contains. C<< <: >> is visible earlier, so
a value marked with it can still be recognised as simple.

    my $a = <: 42;      # compiles to: my $a = 42;

The immutable copy is the same promise enforced at run time. Perl aliases
C<@_> to the caller's variables, so an ordinary argument can be modified by
the subroutine it is passed to; an argument marked with C<< <: >> cannot.

    sub clobber { $_[0] = "changed" }

    my $open = "original";
    clobber($open);            # $open is now "changed"

    my $shut = "original";
    clobber(<: $shut);         # dies: Modification of a read-only value

=head2 Compile-time variables

A variable declared with C<< <: >> has a value the compiler can read:

    my $slot = <: 'age:Int';

Perl cannot normally do this. A C<my> variable is not populated until run
time, so anything running while the program is still being compiled sees
nothing there. That is why a class definition has to be repeated as a literal
inside C<BEGIN>, rather than named once and reused. With C<< <: >> it does not:

    use Object::Proto;

    my $class = <: 'Person';
    my $slot  = <: 'age:Int';

    BEGIN { Object::Proto::define($class, $slot) }   # both are readable here

The value is passed on rather than the variable, both to subroutines and to
anything inspecting the code as it compiles. So a module that examines its
arguments during compilation - a call checker - sees an actual value and can
act on it. Object::Proto uses this to settle a typed slot's check once instead
of on every assignment:

    my $age = <: 42;

    Person::age($p, $age);      # the type check is resolved while compiling

Assigning to such a variable retires it: later reads go back to reading the
variable, so they never return a value that has stopped being true. Because
the value rather than the variable is passed, C<@_> aliasing cannot write
through it, and a subroutine that assigns to C<$_[0]> gets a read-only error.

=head2 What it does not do

C<< <: >> folds an operand that is already constant. It does not evaluate
arbitrary expressions at compile time, so it will not turn a function call into
a constant, and it does not promote anything Perl had not already folded on its
own. Its value is the marker and the immutable copy, not new folding.

=head2 Precedence

C<< <: >> binds as tightly as C<\> and unary minus, so it takes the smallest
term to its right rather than the whole expression:

    <: $a + $b        # means: (<: $a) + $b
    <: $a ** 2        # means: <: ($a ** 2)     - ** binds tighter
    <: $h->{k} * 2    # means: (<: $h->{k}) * 2

Parenthesise when a whole expression is meant:

    <: ($a + $b)

=head2 Scope

The operator is lexically scoped. It is active from C<use Confold> to the end
of the enclosing block or file, and C<no Confold> switches it off again.
Outside an active scope C<< <: >> means whatever it meant before.

=head2 Limitations

Within an active scope, C<< <: >> is claimed as the operator wherever a term is
expected. A glob whose pattern begins with a colon, C<< <:foo> >>, is therefore
a syntax error rather than a glob. Write C<glob(":foo")> instead. Everywhere an
operator is expected instead of a term, C<< < >> is untouched, so comparisons,
C<< <=> >>, left shift and readline all behave normally.

Quoted text is never affected. The operator is recognised during tokenisation
of code only, so C<< "a <: b" >>, C<< '<:encoding(UTF-8)' >>, here-documents and
regular expressions all keep their contents.

Loading Confold enables Perl's pluggable-operator path for the rest of the
process. That is a compile-time cost only, and applies to any module using that
hook; execution speed of code that does not use C<< <: >> is unaffected.

=head1 SEE ALSO

L<Infix::Custom>, for user-defined infix operators.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
