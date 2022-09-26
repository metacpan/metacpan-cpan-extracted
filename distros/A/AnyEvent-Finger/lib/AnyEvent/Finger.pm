package AnyEvent::Finger;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( finger_client finger_server );

# ABSTRACT: Simple asynchronous finger client and server
our $VERSION = '0.14'; # VERSION


sub finger_client ($$$;$)
{
  my($hostname) = shift;
  require AnyEvent::Finger::Client;
  AnyEvent::Finger::Client
    ->new( hostname => $hostname )
    ->finger(@_);
  ();
}


# keep the server object in scope so that
# we don't unbind from the port.  If you
# don't want this, then use the OO interface
# for ::Server instead.
my $keep = [];

sub finger_server ($;$)
{
  require AnyEvent::Finger::Server;
  my $server = AnyEvent::Finger::Server
    ->new
    ->start(@_);
  push @$keep, $server;
  $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Finger - Simple asynchronous finger client and server

=head1 VERSION

version 0.14

=head1 SYNOPSIS

client:

 use AnyEvent::Finger qw( finger_client );
 
 finger_client 'localhost', 'username', sub {
   my($lines) = @_;
   print "[response]\n";
   print join "\n", @$lines;
 };

server:

 use AnyEvent::Finger qw( finger_server );
 
 my %users = (
   grimlock => 'ME GRIMLOCK HAVE ACCOUNT ON THIS MACHINE',
   optimus  => 'Freedom is the right of all sentient beings.',
 );
 
 finger_server sub {
   my $tx = shift; # isa AnyEvent::Finger::Transaction
   if($tx->req->listing_request)
   {
     # respond if remote requests list of users
     $tx->res->say('users: ', keys %users);
   }
   else
   {
     # respond if user exists
     if(defined $users{$tx->req->username})
     {
       $tx->res->say($users{$request});
     }
     # respond if user does not exist
     else
     {
       $tx->res->say('no such user');
     }
   }
   # required! done generating the reply,
   # close the connection with the client.
   $tx->res->done;
 };

=head1 DESCRIPTION

This distribution provides an asynchronous finger server and
client which can be used by any event loop supported by
L<AnyEvent>.  This specific module provides a simple procedural
interface to client and server classes also in this distribution.

=head1 FUNCTIONS

=head2 finger_client

 finger_client( $server, $request, $callback, [ \%options ] )

Send a finger request to the given server.  The callback will
be called when the response is complete.  The options hash may
be passed in as the optional forth argument to override any
default options (See L<AnyEvent::Finger::Client> for details).

=head2 finger_server

 my $server = finger_server $callback, \%options;

Start listening to finger callbacks and call the given callback
for each request.  See L<AnyEvent::Finger::Server> for details
on the options and the callback.

=head1 CAVEATS

Finger is an oldish protocol and almost nobody uses it anymore.

Most finger clients do not have a way to configure an alternate port.
Binding to the default port 79 on Unix usually requires root.  Running
L<AnyEvent::Finger::Server> as root is not recommended.

Under Linux you can use C<iptables> to forward requests to port 79 to
an unprivileged port.  I was able to use this incantation to forward port 79
to port 8079:

 # iptables -t nat -A PREROUTING -p tcp --dport 79 -j REDIRECT --to-port 8079
 # iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 79 -j REDIRECT --to-port 8079

The first rule is sufficient for external clients, the second rule was required
for clients connecting via the loopback interface (localhost).

=head1 SEE ALSO

=over 4

=item

L<RFC1288|http://tools.ietf.org/html/rfc1288>,

=item

L<AnyEvent::Finger::Client>,

=item

L<AnyEvent::Finger::Server>

=item

L<AnyEvent>

Generic non-blocking event loop used by L<AnyEvent::Finger>

=item

L<Net::Finger>

Blocking implementation of a finger client

=item

L<Net::Finger::Server>

Blocking implementation of a finger server

=item

L<PlugAuth::Plugin::Finger>

PlugAuth plugin that allows querying a PlugAuth server
via the finger protocol.  Uses this module for its
implementation.

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
