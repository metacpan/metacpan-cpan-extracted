#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package Data::Checks 0.04;

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

   use v5.26;
   use Sublike::Extended;
   use Signature::Attribute::Checked;

   use Data::Checks qw( Str );

   extended sub greet ( $message :Checked(Str) ) {
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

=head1 DESCRIPTION

This module provides functions that implement various value constraint
checking behaviours. These are the parts made visible by the
C<use Data::Checks ...> import line, in Perl code.

It also provides the underlying common framework XS functions to assist in
writing modules that actually implement such constraint checking. These parts
are not visible in Perl code, but instead made visible at the XS level by the
C<#include "DataChecks.h"> directive.

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
class that overloads stringification. rejects undefined, unblessed references,
or references to objects in classes that do not overload stringification.

=head2 Num

   Num()

Accepts any defined non-reference value that is either a plain number, or a
string that could be used as one without warning, or a reference to an object
in a class that overloads numification. rejects undefined, strings that would
raise a warning if converted to a number, unblessed references, or references
to objects in classes that do not overload numification.

=head2 Isa

   Isa($classname)

I<Since version 0.04.>

Accepts any blessed object reference to an instance of the given class name,
or a subclass derived from it (i.e. anything accepted by the C<isa> operator).

=head2 Maybe

   Maybe($C)

I<Since version 0.04.>

Accepts C<undef> in addition to anything else accepted by the given
constraint.

=cut

=head1 XS FUNCTIONS

The following functions are provided by the F<DataChecks.h> header file for
use in XS modules that implement value constraint checking.

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

=item *

Additionally, the constraint check functions provided by this module may be
implemented using any of the above mechanisms, or may use an unspecified
fourth different mechanism. Outside code should not rely on what that
mechanism may be.

=back

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

   NAME requires a value satisfying CONSTRAINT

Both I<name> and I<constraint> SVs used as temporary strings to generate the
stored message string. Neither SV is retained by the checker directly.

=head2 make_assertop

   OP *make_assertop(struct DataChecks_Checker *checker, OP *argop);

Creates an optree fragment for a value check assertion operation.

Given an optree fragment in scalar context that generates an argument value
(I<argop>), constructs a larger optree fragment that consumes it and checks
that the value is accepted by the constraint check given by I<checker>. The
returned optree fragment will operate in void context (i.e. it does I<not>
yield the argument value itself).

=head2 check_value

   bool check_value(struct DataChecks_Checker *checker, SV *value);

Checks whether a given SV is accepted by the given constraint check, returning
true if so, or false if not.

=head2 assert_value

   void assert_value(struct DataChecks_Checker *checker, SV *value);

Checks whether a given SV is accepted by the given constraint check, throwing
its assertion message if it does not.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
