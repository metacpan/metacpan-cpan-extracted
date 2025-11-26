#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024-2025 -- leonerd@leonerd.org.uk

package Data::Checks 0.11;

use v5.22;
use warnings;

use Carp;

use builtin qw( export_lexically );
no warnings "experimental::builtin";

sub import
{
   shift;
   my @syms = @_;

   # @EXPORT_OK is provided by XS code
   foreach my $sym ( @syms ) {
      grep { $sym eq $_ } our @EXPORT_OK or
         croak "$sym is not exported by ".__PACKAGE__;

      export_lexically( $sym => \&$sym );
   }
}

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Data::Checks> - Value constraint checking

=head1 SYNOPSIS

With L<Signature::Attribute::Checked>:

=for highlighter perl

   use v5.26;
   use Sublike::Extended 0.29 'sub';
   use Signature::Attribute::Checked;

   use Data::Checks qw( Str );

   sub greet ( $message :Checked(Str) ) {
      say "Hello, $message";
   }

   greet( "world" );  # is fine
   greet( undef );    # throws an exception

With L<Object::Pad::FieldAttr::Checked>:

   use v5.22;
   use Object::Pad;
   use Object::Pad::FieldAttr::Checked;

   use Data::Checks qw( Str );

   class Datum {
      field $name :param :reader :Checked(Str);
   }

   my $x = Datum->new( name => "something" );  # is fine
   my $y = Datum->new( name => undef );        # throws an exception

With L<Syntax::Operator::Is> on Perl v5.38 or later:

   use v5.38;
   use Syntax::Operator::Is;

   use Data::Checks qw( Num Object );

   my $x = ...;

   if($x is Num) {
      say "x can be used as a number";
   }
   elsif($x is Object) {
      say "x can be used as an object";
   }

=head1 DESCRIPTION

This module provides functions that implement various value constraint
checking behaviours. These are the parts made visible by the
C<use Data::Checks ...> import line, in Perl code.

It also provides the underlying common framework XS functions to assist in
writing modules that actually implement such constraint checking. These parts
are not visible in Perl code, but instead made visible at the XS level by the
C<#include "DataChecks.h"> directive.

See the L</SYNOPSIS> section above for several examples of other CPAN modules
that make direct use of these constraint checks.

=cut

=head1 CONSTRAINTS

The following constraint checks are inspired by the same-named ones in
L<Types::Standard>. They may be called fully-qualified, or imported
I<lexically> into the calling scope.

B<Note> to users familiar with C<Types::Standard>: some of these functions
behave slightly differently. In particular, these constraints are generally
happy to accept an object reference to a class that provides a conversion
overload, whereas the ones in C<Types::Standard> often are not. Additionally
functions that are parametric take their parameters in normal Perl function
argument lists, not wrapped in additional array references.

=head2 Defined

   Defined()

Accepts any defined value, rejects only C<undef>.

=head2 Object

   Object()

Accepts any blessed object reference, rejects non-references or references to
unblessed data.

=head2 Str

   Str()

Accepts any defined non-reference value, or a reference to an object in a
class that overloads stringification. Rejects undefined, unblessed references,
or references to objects in classes that do not overload stringification.

=head2 StrEq

   StrEq($s)
   StrEq($s1, $s2, ...)

I<Since version 0.05.>

Accepts any value that passes the L</Str> check, and additionally is exactly
equal to I<any of> the given strings.

=head2 StrMatch

   StrMatch(qr/pattern/)

I<Since version 0.08.>

Accepts any value that passes the L</Str> check, and additionally matches the
given regexp pattern.

Remember that the pattern must be supplied as a C<qr/.../> expression, not
simply C<m/.../> or C</.../>.

=head2 Num

   Num()

Accepts any defined non-reference value that is either a plain number, or a
string that could be used as one without warning, or a reference to an object
in a class that overloads numification. 

Rejects undefined, not-a-number, strings that would raise a warning if
converted to a number, unblessed references, or references to objects in
classes that do not overload numification.

=head2 NumGT

=head2 NumGE

=head2 NumLE

=head2 NumLT 

   NumGT($bound)
   NumGE($bound)
   NumLE($bound)
   NumLT($bound)

I<Since version 0.05.>

Accepts any value that passes the L</Num> check, and additionally is within
the bound given. C<NumGT> and C<NumLT> exclude the bound value itself,
C<NumGE> and C<NumLE> include it.

=head2 NumRange

   NumRange($boundge, $boundlt)

I<Since version 0.05.>

Accepts any value that passes the L</Num> check, and additionally is between
the two bounds given. The lower bound is inclusive, and the upper bound is
exclusive.

This choice is made so that a set of C<NumRange> constraints can easily be
created that cover distinct sets of numbers:

   NumRange(0, 10), NumRange(10, 20), NumRange(20, 30), ...

To implement checks with both lower and upper bounds but other kinds of
inclusivity, use two C<Num...> checks combined with an C<All()>. For example,
to test between 0 and 100 inclusive at both ends:

   All(NumGE(0), NumLE(100))

Combinations like this are internally implemented as efficiently as a single
C<NumRange()> constraint.

=head2 NumEq

   NumEq($n)
   NumEq($n1, $n2, ...)

I<Since version 0.05.>

Accepts any value that passes the L</Num> check, and additionally is exactly
equal to I<any of> the given numbers.

=head2 Isa

   Isa($classname)

I<Since version 0.04.>

Accepts any blessed object reference to an instance of the given class name,
or a subclass derived from it (i.e. anything accepted by the C<isa> operator).

=head2 Can

   Can($methodname)
   Can($methodname1, $methodname2, ...)

I<Since version 0.11.>

Accepts any blessed object reference to an instance in a class, or a class
name directly, that has the all of the given method names (i.e. anything that
passes a C<< ->can >> test on every name).

To accept only object references and not package names, combine this check
with C<Object> by using the C<All> combination:

   All(Object, Can($methodname, ...))

=head2 ArrayRef

   ArrayRef()

I<Since version 0.07.>

Accepts any plain reference to an array, or any object reference to an
instance of a class that provides an array dereference overload.

=head2 HashRef

   HashRef()

I<Since version 0.07.>

Accepts any plain reference to a hash, or any object reference to an instance
of a class that provides a hash dereference overload.

=head2 Callable

   Callable()

I<Since version 0.06.>

Accepts any plain reference to a subroutine, or any object reference to an
instance of a class that provides a subroutine dereference overload.

=head2 Maybe

   Maybe($C)

I<Since version 0.04.>

Accepts C<undef> in addition to anything else accepted by the given
constraint.

=head2 Any

   Any($C1, $C2, ...)

I<Since version 0.07.>

Accepts a value that is accepted by at least one of the given constraints.
Rejects if none of them accept it.

At least one constraint is required; it is an error to try to call C<Any()>
with no arguments. If you need a constraint that accepts any value at all, see
L</All>.

   $C1 | $C2 | ...

I<Since version 0.08.>

This function is used to implement C<|> operator overloading, so constraint
checks can be written using this more convenient syntax.

=head2 All

   All($C1, $C2, ...)
   All()

I<Since version 0.07.>

Accepts a value that is accepted by every one of the given constraints.
Rejects if at least one of them rejects it.

Note that if no constraints are given, this accepts all possible values. This
may be useful as an "accept-all" fallback case for generated code, or other
situations where it is required to provide a constraint check but you do not
wish to constraint allowed values.

=head1 CONSTRAINT METHODS

While not intended to be called from regular Perl code, these constraints
still act like objects with the following methods.

=head2 check

   $ok = $constraint->check( $value );

I<Since version 0.09.>

Returns a boolean value indicating whether the constraint accepts the given
value.

=cut

{
   package # hide from indexer
      Data::Checks::Constraint;

   use overload
      '|' => sub { my ( $lhs, $rhs ) = @_; return Data::Checks::Any( $lhs, $rhs ) };
      # For now we won't support or encourage & to mean All() because parsing
      # of expressions like `Str & Object` doesn't actually work properly.
}

=head1 XS FUNCTIONS

The following functions are provided by the F<DataChecks.h> header file for
use in XS modules that implement value constraint checking.

=for highlighter c

=head2 boot_data_checks

   void boot_data_checks(double ver);

Call this function from your C<BOOT> section in order to initialise the module
and load the rest of the support functions.

I<ver> should either be 0 or a decimal number for the module version
requirement; e.g.

   boot_data_checks(0.01);

=head2 make_checkdata

   struct DataChecks_Checker *make_checkdata(SV *checkspec);

Creates a C<struct DataChecks_Checker> structure, which wraps the intent of
the value constraint check. The returned value is used as the I<checker>
argument for the remaining functions.

The constraint check itself is specified by the C<SV> given by I<checkspec>,
which should come directly from the user code. The constraint check may be
specified in any of three ways:

=for highlighter perl

=over 4

=item *

An B<object> reference in a class which has a C<check> method. Value checks
will be invoked as

   $ok = $checkerobj->check( $value );

=item *

A B<package> name as a plain string of a package which has a C<check> method.
Value checks will be invoked as

   $ok = $checkerpkg->check( $value );

=item *

A B<code reference>. Value checks will be invoked with a single argument, as

   $ok = $checkersub->( $value );

I<Since version 0.09> this form is now deprecated, because it does not easily
support a way to query the constraint for its name or stringified form, which
is useful when generating error messages.

=item *

Additionally, the constraint check functions provided by this module may be
implemented using any of the above mechanisms, or may use an unspecified
fourth different mechanism. Outside code should not rely on what that
mechanism may be.

=back

=for highlighter c

Once constructed into a checker structure, the choice of which implementation
is used is fixed, and if a method lookup is involved its result is stored
directly as a CV pointer for efficiency of later invocations. In either of the
first two cases, the reference count on the I<checkspec> SV is increased to
account for the argument value used on each invocation. In the third case, the
reference SV is not retained, but the underlying CV it refers to has its
reference count increased.

=head2 free_checkdata

   void free_checkdata(struct DataChecks_Checker *checker);

Releases any stored SVs in the checker structure, and the structure itself.

=head2 gen_assertmess

   void gen_assertmess(struct DataChecks_Checker *checker, SV *name, SV *constraint);

Generates and stores a message string for the assert message to be used by
L</make_assertop> and L</assert_value>. The message will take the form

=for highlighter

   NAME requires a value satisfying CONSTRAINT

=for highlighter c

Both I<name> and I<constraint> SVs used as temporary strings to generate the
stored message string. Neither SV is retained by the checker directly.

=head2 make_assertop

   OP *make_assertop(struct DataChecks_Checker *checker, OP *argop);

Shortcut to calling L</make_assertop_flags> with I<flags> set to zero.

=head2 make_assertop_flags

   OP *make_assertop_flags(struct DataChecks_Checker *checker, U32 flags, OP *argop);

Creates an optree fragment for a value check assertion operation.

Given an optree fragment in scalar context that generates an argument value
(I<argop>), constructs a larger optree fragment that consumes it and checks
that the value is accepted by the constraint check given by I<checker>. The
behaviours of the returned optree fragment will depend on the I<flags>.

If I<flags> is C<OPf_WANT_VOID> the returned optree will yield nothing.

If I<flags> is zero, the return behaviour is not otherwise specified.

=head2 check_value

   bool check_value(struct DataChecks_Checker *checker, SV *value);

Checks whether a given SV is accepted by the given constraint check, returning
true if so, or false if not.

=head2 assert_value

   void assert_value(struct DataChecks_Checker *checker, SV *value);

Checks whether a given SV is accepted by the given constraint check, throwing
its assertion message if it does not.

=cut

=head1 TODO

=over 4

=item *

Unit constraints - maybe C<Int>, some plain-only variants of C<Str> and
C<Num>, some reference types, etc...

=item *

Structural constraints - C<HashOf>, C<ArrayOf>, etc...

=item *

Think about a convenient name for inclusive-bounded numerical constraints.

=item *

Look into making const-folding work with the C<MIN .. MAX> flip-flop operator

=item *

Performance enhancements for lists of many values in C<StrEq>, C<NumEq>, etc

=item *

Performance enhancement of C<Can> by caching per package name

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
