=head1 NAME

Array::Base - array index offseting

=head1 SYNOPSIS

	use Array::Base +1;

	no Array::Base;

=head1 DESCRIPTION

This module implements automatic offsetting of array indices.  In normal
Perl, the first element of an array has index 0, the second element has
index 1, and so on.  This module allows array indexes to start at some
other value.  Most commonly it is used to give the first element of an
array the index 1 (and the second 2, and so on), to imitate the indexing
behaviour of FORTRAN and many other languages.  It is usually considered
poor style to do this.

The array index offset is controlled at compile time, in a
lexically-scoped manner.  Each block of code, therefore, is subject to
a fixed offset.  It is expected that the affected code is written with
knowledge of what that offset is.

=head2 Using an array index offset

An array index offset is set up by a C<use Array::Base> directive, with
the desired offset specified as an argument.  Beware that a bare, unsigned
number in that argument position, such as "C<use Array::Base 1>", will
be interpreted as a version number to require of C<Array::Base>.  It is
therefore necessary to give the offset a leading sign, or parenthesise
it, or otherwise decorate it.  The offset may be any integer (positive,
zero, or negative) within the range of Perl's integer arithmetic.

An array index offset declaration is in effect from immediately after the
C<use> line, until the end of the enclosing block or until overridden
by another array index offset declaration.  A declared offset always
replaces the previous offset: they do not add.  "C<no Array::Base>" is
equivalent to "C<use Array::Base +0>": it returns to the Perlish state
with zero offset.

A declared array index offset influences these types of operation:

=over

=item *

array indexing (C<$a[3]>)

=item *

array slicing (C<@a[3..5]>)

=item *

list indexing/slicing (C<qw(a b c)[2]>)

=item *

array splicing (C<splice(@a, 3, 2)>)

=item *

array last index (C<$#a>)

=item *

array keys (C<keys(@a)>) (Perl 5.11 and later)

=item *

array each (C<each(@a)>) (Perl 5.11 and later)

=back

Only forwards indexing, relative to the start of the array, is supported.
End-relative indexing, normally done using negative index values, is
not supported when an index offset is in effect.  Use of an index that
is numerically less than the index offset will have unpredictable results.

=head2 Differences from C<$[>

This module is a replacement for the historical L<C<$[>|perlvar/$[>
variable.  In early Perl that variable was a runtime global, affecting all
array and string indexing in the program.  In Perl 5, assignment to C<$[>
acts as a lexically-scoped pragma.  C<$[> is deprecated.  The original
C<$[> was removed in Perl 5.15.3, and later replaced in Perl 5.15.5 by
an automatically-loaded L<arybase> module.  This module reimplements
the index offset feature without any specific support from the core.

Unlike C<$[>, this module does not affect indexing into strings.
This module is concerned only with arrays.  To influence string indexing,
see L<String::Base>.

This module does not show the offset value in C<$[> or any other
accessible variable.  With the array offset being lexically scoped,
there should be no need to write code to handle a variable offset.

C<$[> has some predictable, but somewhat strange, behaviour for indexes
less than the offset.  The behaviour differs slightly between slicing
and scalar indexing.  This module does not attempt to replicate it,
and does not support end-relative indexing at all.

The last-index operator (C<$#a>), as implemented by the Perl core,
generates a magical scalar which is linked to the underlying array.
The numerical value of the scalar varies if the length of the array
is changed, and code with different C<$[> settings will see accordingly
different values.  The scalar can also be written to, to change the length
of the array, and again the interpretation of the value written varies
according to the C<$[> setting of the code that is doing the writing.
This module does not replicate any of that behaviour.  With an array
index offset from this module in effect, C<$#a> evaluates to an ordinary
rvalue scalar, giving the last index of the array as it was at the time
the operator was evaluated, according to the array index offset in effect
where the operator appears.

=cut

package Array::Base;

{ use 5.008001; }
use Lexical::SealRequireHints 0.006;
use warnings;
use strict;

our $VERSION = "0.005";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 PACKAGE METHODS

These methods are meant to be invoked on the C<Array::Base> package.

=over

=item Array::Base->import(BASE)

Sets up an array index offset of I<BASE>, in the lexical environment
that is currently compiling.

=item Array::Base->unimport

Clears the array index offset, in the lexical environment that is
currently compiling.

=back

=head1 BUGS

L<B::Deparse> will generate incorrect source when deparsing code that
uses an array index offset.  It will include both the pragma to set up
the offset and the munged form of the affected operators.  Either the
pragma or the munging is required to get the index offset effect; using
both will double the offset.  Also, the code generated for an array each
(C<each(@a)>) operation involves a custom operator, which L<B::Deparse>
can't understand, so the source it emits in that case is completely wrong.

The additional operators generated by this module cause spurious warnings
if some of the affected array operations are used in void context.

Prior to Perl 5.9.3, the lexical state of array index offset does not
propagate into string eval.

=head1 SEE ALSO

L<String::Base>,
L<arybase>,
L<perlvar/$[>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2012
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
