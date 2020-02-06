package AnyEvent::Finger::Transaction;

use strict;
use warnings;
use overload '""' => sub { shift->as_string };

# ABSTRACT: Simple asynchronous finger transaction
our $VERSION = '0.11'; # VERSION


sub res { shift->{res} }
sub req { shift->{req} }


sub remote_port { shift->{remote_port} }
sub local_port { shift->{local_port} }


sub remote_address { shift->{remote_address} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Finger::Transaction - Simple asynchronous finger transaction

=head1 VERSION

version 0.11

=head1 DESCRIPTION

This class is a container for response and request objects
which is used when a finger request comes into 
L<AnyEvent::Finger::Server> server instance.  It also provides
information about the connection (the remote, local ports and
the remote client's address).

=head1 ATTRIBUTES

All attributes for this class are read-only.

=head2 req

 my $request = $tx->req;

Returns the request object associated with the transaction
(an instance of L<AnyEvent::Finger::Request>).

=head2 res

 my $response = $tx->res;

Returns the response object associated with the transaction
(an instance of L<AnyEvent::Finger::Response>).

=head2 remote_port

 my $port = $tx->remote_port;

Returns the remote TCP port being used to make the request.

=head2 local_port

 my $port = $tx->local_port;

Returns the local TCP port being used to make the request.

=head2 remote_address

 my $address = $tx->remote_address;

Returns the IP address from whence the finger request is coming from.

=head1 SEE ALSO

=over 4

=item

L<AnyEvent::Finger>

=item

L<AnyEvent::Finger::Client>

=item

L<AnyEvent::Finger::Server>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
