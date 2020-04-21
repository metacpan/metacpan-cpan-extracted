package AnyEvent::Ident;

use strict;
use warnings;
use Exporter ();

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( ident_server ident_client );

# ABSTRACT: Simple asynchronous ident client and server
our $VERSION = '0.08'; # VERSION


# keep the server object in scope so that
# we don't unbind from the port.  If you 
# don't want this, then use the OO interface
# for ::Server instead.
my $keep = [];

sub ident_server ($$$;$)
{
  my $hostname = shift;
  my $port     = shift;
  my $cb       = shift;
  require AnyEvent::Ident::Server;
  my $server = AnyEvent::Ident::Server
    ->new( hostname => $hostname, port => $port, %{ $_[0] || {} } )
    ->start($cb);
  push @$keep, $server;
  return $server;
}


sub ident_client ($$$$$)
{
  my $hostname = shift;
  my $port     = shift;
  require AnyEvent::Ident::Client;
  AnyEvent::Ident::Client
    ->new( hostname => $hostname, port => $port )
    ->ident(@_);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Ident - Simple asynchronous ident client and server

=head1 VERSION

version 0.08

=head1 SYNOPSIS

client:

 use AnyEvent::Ident qw( ident_client );
 
 ident_client '127.0.0.1', 113, $server_port, $client_port, sub {
   my($res) = @_; # isa AnyEvent::Client::Response 
   if($res->is_success)
   {
     print "user: ", $res->username, "\n"
     print "os:   ", $res->os, "\n"
   }
   else
   {
     warn "Ident error: " $res->error_type;
   }
 };

server:

 use AnyEvent::Ident qw( ident_server );
 
 ident_server '127.0.0.1', 113, sub {
   my $tx = shift;
   if($tx->req->server_port == 400
   && $tx->req->client_port == 500)
   {
     $tx->reply_with_user('UNIX', 'grimlock');
   }
   else
   {
     $tx->reply_with_error('NO-USER');
   }
 };

=head1 DESCRIPTION

This module provides a simple procedural interface to L<AnyEvent::Ident::Client> and
L<AnyEvent::Ident::Server>.

=head1 FUNCTIONS

=head2 ident_server

 my $server = ident_server $hostname, $port, $callback;
 my $server = ident_server $hostname, $port, $callback, \%opt;

Start an ident server listening to the address given by C<$hostname>
on port C<$port>.  For each request C<$callback> will be called and
passed in an instance of L<AnyEvent::Ident::Transaction>.

C<%opt> is optional hash of arguments.  See L<AnyEvent::Ident::Server#CONSTRUCTOR>
for legal key/value pairs and defaults.

=head2 ident_client

 my $client = ident_client $hostname, $port, $server_port, $client_port, $callback;

Make an ident request with the ident server at C<$hostname> on port C<$port>
with the given port pair C<$server_port,$client_port>.  When the response
comes back call C<$callback>, with an instance of L<AnyEvent::Ident::Response>.

=head1 CAVEATS

ident is an oldish protocol and almost nobody uses it anymore.  The RFC for the
protocol clearly states that ident should not be used for authentication, at most
it should be used only for audit (for example annotation of log files).  In Windows 
and possibly other operating systems, an unprivileged user can listen to port 113
and on any untrusted network, a remote ident server is not a secure authentication 
mechanism.

No modern operating systems enable the ident service by default, so you can't expect
it to be there unless you have control of the server and have specifically enabled
it.

Most of the time a client wanting to use the ident protocol expects to find 
ident listening to port 113, which on many platforms (such as UNIX) requires
special privileges (such as root).

Under Linux you can use C<iptables> to forward requests from port 113 to
an unprivileged port.  I was able to use this incantation to forward port 113
to port 8113:

 # iptables -t nat -A PREROUTING -p tcp --dport 113 -j REDIRECT --to-port 8113
 # iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 113 -j REDIRECT --to-port 8113

The first rule is sufficient for external clients, the second rule was required
for clients connecting via the loopback interface (localhost).

=head1 SEE ALSO

=over 4

=item L<AnyEvent::Ident::Client>

Client OO Interface

=item L<AnyEvent::Ident::Server>

Server OO Interface

=item L<Net::Ident>

Blocking implementation of client only.

=item L<RFC1413|http://tools.ietf.org/html/rfc1413>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
