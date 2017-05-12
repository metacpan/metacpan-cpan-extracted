package AnyMQ::RawSocket;

use 5.006;

use Any::Moose;

=head1 NAME

AnyMQ::ZeroMQ - AnyMQ using just a socket and JSON.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  my $bus = AnyMQ->new_with_traits(
      traits  => ['RawSocket'],

      # listener socket
      address => '0.0.0.0:4000',
  );

  # see AnyMQ docs for usage

=head1 SEE ALSO

L<AnyMQ>, L<Web::Hippie>, L<Web::Hippie::PubSub>

=head1 AUTHOR

Mischa Spiegelmock, C<< <revmischa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mischa Spiegelmock.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of AnyMQ::ZeroMQ
