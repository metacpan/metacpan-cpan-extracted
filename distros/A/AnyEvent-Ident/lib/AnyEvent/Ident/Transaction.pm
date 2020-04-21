package AnyEvent::Ident::Transaction;

use strict;
use warnings;
use AnyEvent::Ident::Response;

# ABSTRACT: Simple asynchronous ident transaction
our $VERSION = '0.08'; # VERSION


sub req { shift->{req} }


sub reply_with_user
{
  my $self = shift;
  my $username = pop;
  my $os = shift;
  $os = 'OTHER' unless defined $os;
  $self->{cb}->(
    AnyEvent::Ident::Response->new(
      req      => $self->{req},
      username => $username,
      os       => $os,
    )
  );
}


sub reply_with_error
{
  my($self, $error_type) = @_;
  $self->{cb}->(
    AnyEvent::Ident::Response->new(
      req        => $self->{req},
      error_type => $error_type,
    )
  );
}


sub remote_port { shift->{remote_port} }
sub local_port { shift->{local_port} }


sub remote_address { shift->{remote_address} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Ident::Transaction - Simple asynchronous ident transaction

=head1 VERSION

version 0.08

=head1 METHODS

=head2 req

 my $req = $tx->req;

Returns the request object for the transaction
(an instance of L<AnyEvent::Ident::Request>).

=head2 reply_with_user

 $tx->reply_with_user($os, $username);
 $tx->reply_with_user($os);

Reply to the client with the given username and operating system.  If
C<$os> is not specified then "OTHER" is used for the operating system.
The operating system should be one specified in 
L<RFC-952|http://tools.ietf.org/html/rfc1340> under SYSTEM NAMES, or
C<OTHER>.  Common system names include C<UNIX>, C<WIN32> and C<VMS>.
C<OTHER> should be used when the identification ($username) does not map
directly to a user or email address on the server system.  Here are a couple
of examples where C<OTHER> should be used:

=over 4

=item *

The username is actually an encrypted audit token

=item *

The username is actually a real name and phone number.

=back

=head2 reply_with_error

 $tx->reply_with_error( $error_type );

Reply to the client with the given error.  Should be one of

=over 4

=item *

INVALID-PORT

Usually detected and handled by L<AnyEvent::Ident::Server> itself.

=item *

NO-USER

No user for the port pair, or the port pair does not
refer to a currently open TCP connection.

=item *

HIDDEN-USER

The port pair was valid and the ident server was able to determine
the user, but the user declined to provide this information (typically
via user configuration).

=item *

UNKNOWN-ERROR

Used for all other errors.

=back

=head2 remote_port

 my $port = $tx->remote_port;

Returns the remote TCP port being used to make the request.

=head2 local_port

 my $port = $tx->local_port;

Returns the local TCP port being used to make the request.

=head2 remote_address

 my $address = $tx->remote_address;

Returns the IP address from whence the ident request is coming from.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
