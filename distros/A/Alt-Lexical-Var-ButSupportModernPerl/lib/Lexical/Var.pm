=head1 NAME

Lexical::Var - static variables without namespace pollution

=head1 SYNOPSIS

	use Lexical::Var '$foo' => \$Remote::foo;
	use Lexical::Var '$const' => \123;
	use Lexical::Var '@bar' => [];
	use Lexical::Var '%baz' => { a => 1, b => 2 };
	use Lexical::Var '&quux' => sub { $_[0] + 1 };
	use Lexical::Var '*wibble' => Symbol::gensym();

=head1 DESCRIPTION

This module implements lexical scoping of static variables and
subroutines.  Although it can be used directly, it is mainly intended
to be infrastructure for modules that manage namespaces.

This module influences the meaning of single-part variable names that
appear directly in code, such as "C<$foo>".  Normally, in the absence
of any particular declaration, or under the effect of an C<our>
declaration, this would refer to the scalar variable of that name
located in the current package.  A C<Lexical::Var> declaration can
change this to refer to any particular scalar, bypassing the package
system entirely.  A variable name that includes an explicit package part,
such as "C<$main::foo>", always refers to the variable in the specified
package, and is unaffected by this module.  A symbolic reference through
a string value, such as "C<${'foo'}>", also looks in the package system,
and so is unaffected by this module.

The types of name that can be influenced are scalar ("C<$foo>"),
array ("C<@foo>"), hash ("C<%foo>"), subroutine ("C<&foo>"), and glob
("C<*foo>").  A definition for any of these names also affects code
that logically refers to the same entity, even when the name is spelled
without its usual sigil.  For example, any definition of "C<@foo>" affects
element references such as "C<$foo[0]>".  Barewords in filehandle context
actually refer to the glob variable.  Bareword references to subroutines,
such as "C<foo(123)>", only work on Perl 5.11.2 and later; on earlier
Perls you must use the C<&> sigil, as in "C<&foo(123)>".

Where a scalar name is defined to refer to a constant (read-only) scalar,
references to the constant through the lexical namespace can participate
in compile-time constant folding.  This can avoid the need to check
configuration values (such as whether debugging is enabled) at runtime.

A name definition supplied by this module takes effect from the end of the
definition statement up to the end of the immediately enclosing block,
except where it is shadowed within a nested block.  This is the same
lexical scoping that the C<my>, C<our>, and C<state> keywords supply.
Definitions from L<Lexical::Var> and from C<my>/C<our>/C<state> can shadow
each other.  These lexical definitions propagate into string C<eval>s,
on Perl versions that support it (5.9.3 and later).

This module only manages variables of static duration (the kind of
duration that C<our> and C<state> variables have).  To get a fresh
variable for each invocation of a function, use C<my>.

=cut

package Lexical::Var;

{ use 5.006; }
use Lexical::SealRequireHints 0.006;
use warnings;
use strict;

our $VERSION = "0.009";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 PACKAGE METHODS

These methods are meant to be invoked on the C<Lexical::Var> package.

=over

=item Lexical::Var->import(NAME => REF, ...)

Sets up lexical variable declarations, in the lexical environment that
is currently compiling.  Each I<NAME> must be a variable name (e.g.,
"B<$foo>") including sigil, and each I<REF> must be a reference to a
variable/value of the appropriate type.  The name is lexically associated
with the referenced variable/value.

L<Scalar::Construct> can be helpful in generating appropriate I<REF>s,
especially to create constants.  There are Perl core bugs to beware of
around compile-time constants; see L</BUGS>.

=item Lexical::Var->unimport(NAME [=> REF], ...)

Sets up negative lexical variable declarations, in the lexical environment
that is currently compiling.  Each I<NAME> must be a variable name
(e.g., "B<$foo>") including sigil.  If the name is given on its own,
it is lexically dissociated from any value.  Within the resulting scope,
the variable name will not be recognised.  If a I<REF> (which must be a
reference to a value of the appropriate type) is specified with a name,
the name will be dissociated if and only if it is currently associated
with that value.

=back

=head1 BUGS

Subroutine invocations without the C<&> sigil cannot be correctly
processed on Perl versions earlier than 5.11.2.  This is because
the parser needs to look up the subroutine early, in order to let any
prototype affect parsing, and it looks up the subroutine by a different
mechanism than is used to generate the call op.  (Some forms of sigilless
call have other complications of a similar nature.)  If an attempt
is made to call a lexical subroutine via a bareword on an older Perl,
this module will probably still be able to intercept the call op, and
will throw an exception to indicate that the parsing has gone wrong.
However, in some cases compilation goes further wrong before this
module can catch it, resulting in either a confusing parse error or
(in rare situations) silent compilation to an incorrect op sequence.
On Perl 5.11.2 and later, sigilless subroutine calls work correctly,
except for an issue noted below.

Subroutine calls that have neither sigil nor parentheses (around the
argument list) are subject to an ambiguity with indirect object syntax.
If the first argument expression begins with a bareword or a scalar
variable reference then the Perl parser is liable to interpret the call as
an indirect method call.  Normally this syntax would be interpreted as a
subroutine call if the subroutine exists, but the parser doesn't look at
lexically-defined subroutines for this purpose.  The call interpretation
can be forced by prefixing the first argument expression with a C<+>,
or by wrapping the whole argument list in parentheses.

On Perls built for threading (even if threading is not actually used),
scalar constants that are defined by literals in the Perl source don't
reliably maintain their object identity.  What appear to be multiple
references to a single object can end up behaving as references
to multiple objects, in surprising ways.  The multiple objects all
initially have the correct value, but they can be writable even though the
original object is a constant.  See Perl bug reports [perl #109744] and
[perl #109746].  This can affect objects that are placed in the lexical
namespace, just as it can affect those in package namespaces or elsewhere.
C<Lexical::Var> avoids contributing to the problem itself, but certain
ways of building the parameters to C<Lexical::Var> can result in the
object in the lexical namespace not being the one that was intended,
or can damage the named object so that later referencing operations on
it misbehave.  L<Scalar::Construct> can be used to avoid this problem.

Bogus redefinition warnings occur in some cases when C<our> declarations
and C<Lexical::Var> declarations shadow each other.

Package hash entries get created for subroutine and glob names that
are used, even though the subroutines and globs are not actually being
stored or looked up in the package.  This can occasionally result in a
"used only once" warning failing to occur when it should.

On Perls prior to 5.15.5,
if this package's C<import> or C<unimport> method is called from inside
a string C<eval> inside a C<BEGIN> block, it does not have proper
access to the compiling environment, and will complain that it is being
invoked outside compilation.  Calling from the body of a C<require>d
or C<do>ed file causes the same problem
on the same Perl versions.  Other kinds of indirection
within a C<BEGIN> block, such as calling via a normal function, do not
cause this problem.

=head1 SEE ALSO

L<Attribute::Lexical>,
L<Lexical::Import>,
L<Lexical::Sub>,
L<Scalar::Construct>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2012, 2013
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
