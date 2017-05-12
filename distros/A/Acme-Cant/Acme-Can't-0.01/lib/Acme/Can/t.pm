package Acme::Can't;

use 5.00307;
use strict;
use warnings;

use UNIVERSAL qw/can/;

our $VERSION = '0.01';

sub can't ($$;$) {
  my( $self, $method ) = @_; 
  $self->can( $method ) ? 0 : 1;
}

1;
__END__

=head1 NAME

Acme::Can't - Determine whether your object can B<NOT> call a given method.

=head1 SYNOPSIS

  use Acme::Can't;
  use Some::Module;
  my $obj = Some::Module->new();
  die "Can't do that!" if $obj->can't( 'live' );

=head1 DESCRIPTION

This module allows a programer to determine whether on not their
objects have the ability to call a given method.  This sort of test
can be useful to programatically enforce interface implementation.
This allows for much cleaner code than using unless and can.

=head2 USAGE

You can use the C<can't> method on any object you create, and just
pass it a method name that you want to ensure that your object can
not call.  C<can't> returns 1 if true, 0 if false.

=head1 ACKNOWLEDGEMENTS

This module was almost wholly inspired by Christopher Nehren's
L<Acme::Isn't>, which was in turn inspired by Damian Conway's
L<Acme::Don't>.

=head1 AUTHOR

Kent Cowgill, E<lt>kent@c2group.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kent Cowgill

The author hereby releases this library into the public domain.

The author hereby disclaims all responsibility for any usage of this
library in any code whatsoever. If you're silly enough to use this code,
you deserve whatever you get. :-)

=cut
