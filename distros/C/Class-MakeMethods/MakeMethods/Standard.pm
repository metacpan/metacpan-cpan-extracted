=head1 NAME

Class::MakeMethods::Standard - Make common object accessors


=head1 SYNOPSIS

  package MyObject;
  use Class::MakeMethods::Standard::Hash (
    new => 'new',
    scalar => [ 'foo', 'bar' ],
    array => 'my_list',
    hash => 'my_index',
  );


=head1 DESCRIPTION

This document describes the various subclasses of Class::MakeMethods
included under the Standard::* namespace, and the method types each
one provides.

The Standard subclasses provide a parameterized set of method-generation
implementations.

Subroutines are generated as closures bound to a hash containing
the method name and (optionally) additional parameters.


=head1 USAGE AND SYNTAX

When you C<use> a subclass of this package, the method declarations
you provide as arguments cause subroutines to be generated and
installed in your module. You can also omit the arguments to C<use>
and instead make methods at runtime by passing the declarations to
a subsequent call to C<make()>.

You may include any number of declarations in each call to C<use>
or C<make()>. If methods with the same name already exist, earlier
calls to C<use> or C<make()> win over later ones, but within each
call, later declarations superceed earlier ones.

You can install methods in a different package by passing
C<-target_class =E<gt> I<package>> as your first arguments to C<use>
or C<make>.

See L<Class::MakeMethods/"USAGE"> for more details.

=cut

package Class::MakeMethods::Standard;

$VERSION = 1.000;
use strict;
use Class::MakeMethods '-isasubclass';

########################################################################

=head1 SEE ALSO

See L<Class::MakeMethods> for general information about this distribution. 

For distribution, installation, support, copyright and license 
information, see L<Class::MakeMethods::Docs::ReadMe>.

=cut

1;
