#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

package Data::Checks 0.02;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Data::Checks> - XS functions to assist in value constraint checking

=head1 DESCRIPTION

I<Eventually> this module will provide functions that implement various value
constraint checking behaviours.

Currently it does not contain anything directly visible to end-user Perl code,
but instead only provides the underlying common framework XS functions to
assist in writing modules that actually implement such constraint checking. It
is unlikely to be useful to end-users at this time.

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
that the value passes the constraint check given by I<checker>. The returned
optree fragment will operate in void context (i.e. it does I<not> yield the
argument value itself).

=head2 check_value

   bool check_value(struct DataChecks_Checker *checker, SV *value);

Checks whether a given SV passes the given constraint check, returning true if
so, or false if not.

=head2 assert_value

   void assert_value(struct DataChecks_Checker *checker, SV *value);

Checks whether a given SV passes the given constraint check, throwing its
assertion message if it does not.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
