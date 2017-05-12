# $Id: Holy.pm,v 1.5 2003/06/16 02:49:03 ian Exp $
package Acme::Holy;

use 5.000;
use strict;

require Exporter;
require DynaLoader;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );

	$VERSION	= '0.03';
	@ISA		= qw( Exporter DynaLoader );
	@EXPORT		= qw( holy                );
	@EXPORT_OK	= qw( blessed divine hallowed consecrated sacred sacrosanct );

bootstrap Acme::Holy $VERSION;

1;
__END__
=pod

=head1 NAME

Acme::Holy - Test whether references are blessed.


=head1 SYNOPSIS

  use Acme::Holy;

  my $ref = ... some reference ...
  my $obj = bless $ref , 'Some::Class';
  
  print holy( $obj );                           # prints 'Some::Class'
  print ( holy [] ? 'object' : 'not object' );  # prints 'not object'


=head1 WARNING

This module is a classic case of reinventing the wheel and not enough
RTFM. Unless you really like having terms such as C<holy> in your code, you
should use the official "holy" implementation now found in the Perl core:
L<Scalar::Util>. There you will find the C<blessed> function which behaves
identically to C<holy()>.

... Oh well, on with the show ...


=head1 DESCRIPTION

B<Acme::Holy> provides a single routine, B<holy()>, which returns the name
of the package an object has been C<bless>ed into, or C<undef>, if its first
argument is not a blessed reference.

Isn't this what C<ref()> does already? Yes, and no. If given a blessed
reference, C<ref()> will return the name of the package the reference has
been blessed into. However, if C<ref()> is passed an unblessed reference,
then it will return the type of reference (e.g. C<SCALAR>, C<HASH>, C<CODEREF>,
etc). This means that a call to C<ref()> by itself cannot determine if a
given reference is an object. B<holy()> differs from C<ref()> by returning
C<undef> if its first argument is not a blessed reference (even if it is
a reference).

Can't we use C<UNIVERSAL::isa()>? Yes, and no. If you already have an object,
then C<isa()> will let you know if it inherits from a given class. But what do
we do if we know nothing of the inheritance tree of the object's class? Also,
if we don't have an object, just a normal reference, then attempting to call
C<isa()> through it will result in a run-time error.

B<holy()> is a quick, single test to determine if a given scalar represents
an object (i.e. a blessed reference).


=head2 EXPORT

By default, B<Acme::Holy> exports the method B<holy()> into the current
namespace. Aliases for B<holy()> (see below) may be imported upon request.

=head2 Methods

=over 4

=item B<holy> I<scalar>

B<holy()> accepts a single scalar as its argument, and, if that scalar is
a blessed reference, returns the name of the package the reference has been
blessed into. Otherwise, B<holy()> returns C<undef>.

=back


=head2 Method Aliases

To reflect that there are many terms for referring to something that is
blessed, B<Acme::Holy> offers a list of aliases for B<holy()> that may be
imported upon request:

  use Acme::Holy qw( blessed );

The following aliases are supported:

=over 4

=item * B<blessed()>

=item * B<consecrated()>

=item * B<divine()>

=item * B<hallowed()>

=item * B<sacred()>

=item * B<sacrosanct()>

=back


=head1 ACKNOWLEDGEMENTS

The idea for this module came from a conversation I had with David Cantrell
<david@cantrell.org.uk>. However, the lack of RTFM is a clear failing on
my part. It was obviously a good idea, otherwise someone wouldn't have
already written it.


=head1 SEE ALSO

L<Scalar::Util> (oops!), L<bless|perlfunc/bless>, L<perlboot>, L<perltoot>,
L<perltooc>, L<perlbot>, L<perlobj>.


=head1 AUTHOR

Ian Brayshaw, E<lt>ian@onemore.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Ian Brayshaw

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
