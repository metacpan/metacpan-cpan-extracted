package AnyEvent::WebSocket::Message;

use strict;
use warnings;
use Moo;
use Encode ();

# ABSTRACT: WebSocket message for AnyEvent
our $VERSION = '0.38'; # VERSION


has body => ( is => 'ro', required => 1 );
has opcode => ( is => 'ro', default => 1 );


sub decoded_body
{
  Encode::decode("UTF-8", shift->body)
}


sub is_text   { $_[0]->opcode == 1 }
sub is_binary { $_[0]->opcode == 2 }
sub is_close  { $_[0]->opcode == 8 }
sub is_ping   { $_[0]->opcode == 9 }
sub is_pong   { $_[0]->opcode == 10 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::WebSocket::Message - WebSocket message for AnyEvent

=head1 VERSION

version 0.38

=head1 SYNOPSIS

 $connection->send(
   AnyEvent::WebSocket::Message->new(body => "some message"),
 );

 $connection->on(each_message => sub {
   my($connection, $message) = @_;
   if($message->is_text || $message->is_binary)
   {
     my $body = $message->body;
   }
 });

=head1 DESCRIPTION

Instances of this class represent a single WebSocket message.  They are
the objects that come through from the other end of your
L<AnyEvent::WebSocket::Connection> instance.  They can also be sent through
that class using its C<send> method.

=head1 ATTRIBUTES

=head2 body

The body or payload of the message.

=head2 opcode

The integer code for the type of message.

=head1 METHODS

=head2 decoded_body

 my $body = $message->decoded_body;

Returns the body decoded from UTF-8.

=head2 is_text

 my $bool = $message->is_text;

True if the message is text.

=head2 is_binary

 my $bool = $message->is_binary;

True if the message is binary.

=head2 is_close

 my $bool = $message->is_close;

True if the message is a close message.

=head2 is_ping

 my $bool = $message->is_ping

True if the message is a ping.

=head2 is_pong

 my $bool = $message->is_pong;

True if the message is a pong.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::WebSocket::Client>

=item *

L<AnyEvent::WebSocket::Connection>

=item *

L<AnyEvent::WebSocket::Server>

=item *

L<AnyEvent>

=item *

L<RFC 6455 The WebSocket Protocol|http://tools.ietf.org/html/rfc6455>

=back

=for stopwords Joaquín José

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Toshio Ito

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
