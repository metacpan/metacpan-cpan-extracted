package AnyEvent::eris;
# ABSTRACT: Implementation of eris pub/sub client and server

use strict;
use warnings;

1;

__END__

=pod

=head1 DESCRIPTION

L<POE::Component::Client::eris> and L<POE::Component::Server::eris>
are L<POE>-based client and server of a pub/sub protocol. This is
the L<AnyEvent> mostly-honest port of it.

You can read more (well, actually, barely anything at all) at
L<AnyEvent::eris::Client> and L<AnyEvent::eris::Server>.
