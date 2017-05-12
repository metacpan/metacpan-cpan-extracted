#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package App::MatrixTool::HTTPClient;

use strict;
use warnings;

our $VERSION = '0.08';

use Carp;
use Future 0.33; # ->catch
use Future::Utils qw( repeat_until_success );
use IO::Async::Loop;
use IO::Async::Resolver 0.68; # failure details
use IO::Async::Resolver::DNS 0.06 qw( ERR_NO_HOST ERR_NO_ADDRESS ); # Future return with failure details
use JSON qw( encode_json decode_json );
use URI;

use Socket qw( getnameinfo NI_NUMERICHOST SOCK_RAW );

use constant DEFAULT_MATRIX_PORT => 8448;

=head1 NAME

C<App::MatrixTool::HTTPClient> - HTTP client helper for L<App::MatrixTool>

=head1 DESCRIPTION

Provides helper methods to perform HTTP client operations that may be required
by commands of L<App::MatrixTool>.

=cut

sub new
{
   my $class = shift;

   my $loop = IO::Async::Loop->new; # magic constructor

   return bless {
      @_,
      resolver => $loop->resolver,
      loop     => $loop,
   }, $class;
}

=head1 METHODS

=cut

sub ua
{
   my $self = shift;
   return $self->{ua} ||= do {
      require IO::Async::SSL;
      require Net::Async::HTTP;
      require HTTP::Request;

      my $ua = Net::Async::HTTP->new(
         SSL_verify_mode => 0,
         fail_on_error => 1,  # turn 4xx/5xx errors into Future failures
      );

      $self->{loop}->add( $ua );
      $ua;
   };
}

=head2 resolve_matrix

   @res = $client->resolve_matrix( $server_name )->get

Returns a list of C<HASH> references. Each has at least the keys C<target>
and C<port>. These should be tried in order until one succeeds.

=cut

sub resolve_matrix
{
   my $self = shift;
   my ( $server_name ) = @_;

   if( my ( $host, $port ) = $server_name =~ m/^(\S+):(\d+)$/ ) {
      return Future->done( { target => $host, port => $port } );
   }

   $self->{resolver}->res_query(
      dname => "_matrix._tcp.$server_name",
      type  => "SRV",
   )->then( sub {
      my ( undef, @srvs ) = @_;
      Future->done( @srvs );
   })->catch_with_f(
      resolve => sub {
         my ( $f, $message, undef, undef, $errnum ) = @_;
         return $f unless $errnum == ERR_NO_HOST or $errnum == ERR_NO_ADDRESS;

         Future->done( { target => $server_name, port => DEFAULT_MATRIX_PORT } );
      }
   );
}

=head2 resolve_addr

   @addrs = $client->resolve_addr( $hostname )->get

Returns a list of human-readable string representations of the IP addresses
resolved by the given hostname.

=cut

sub resolve_addr
{
   my $self = shift;
   my ( $host ) = @_;

   $self->{resolver}->getaddrinfo(
      host     => $host,
      service  => "",
      family   => $self->{family},
      socktype => SOCK_RAW,
   )->then( sub {
      my @res = @_;
      return Future->done(
         map { ( getnameinfo( $_->{addr}, NI_NUMERICHOST ) )[1] } @res
      );
   });
}

=head2 request

   $response = $client->request( server => $name, method => $method, path => $path, ... )->get

Performs an HTTPS request to the given server, by resolving the server name
using the C<resolve_matrix> method first, thus obeying its published C<SRV>
records.

=cut

sub request
{
   my $self = shift;
   my %params = @_;

   my $uri = URI->new;
   $uri->path( $params{path} );
   $uri->query_form( %{ $params{params} } ) if $params{params};

   my $ua  = $self->ua;
   my $req = $params{request} // HTTP::Request->new( $params{method} => $uri,
      [ Host => $params{server} ],
   );
   $req->protocol( "HTTP/1.1" );

   if( defined $params{content} ) {
      if( ref $params{content} ) {
         $req->content( encode_json( delete $params{content} ) );
         $req->header( Content_type => "application/json" );
      }
      else {
         $req->content( delete $params{content} );
         $req->header( Content_type => delete $params{content_type} //
            croak "Non-reference content needs 'content_type'" );
      }
      $req->header( Content_length => length $req->content );
   }

   if( $self->{print_request} ) {
      print STDERR "Sending HTTP request to $params{server}\n";
      print STDERR "  $_\n" for split m/\n/, $req->as_string( "\n" );
   }

   my $path = $req->uri->path;

   # Different kinds of request need resolving either as a client or as a
   # federated server
   my $resolve_f;
   if( $path =~ m{^/_matrix/key/} ) {
      $resolve_f = $self->resolve_matrix( $params{server} )->then( sub {
         my @res = @_;
         Future->done( map {
            { SSL => 1, host => $_->{target}, port => $_->{port}, family => $self->{family} }
         } @res );
      });
   }
   elsif( $path =~ m{^/_matrix/(?:client|media)/} ) {
      my ( $server, $port ) = $params{server} =~ m/^([^:]+)(?::(\d+))?$/ or
         die "Unable to parse server '$params{server}'\n";
      $resolve_f = Future->done(
         { SSL => 1, port => $port // 443, host => $server, family => $self->{family} }
      );
   }
   else {
      die "Unsure how to resolve server for path $path\n";
   }

   $resolve_f->then( sub {
      my @res = @_;

      repeat_until_success {
         my $res = shift;
         print STDERR "Using target $res->{host} port $res->{port}\n" if $self->{print_request};

         $ua->do_request(
            %params,
            %$res,
            request => $req,
         )->on_done( sub {
            my ( $response ) = @_;
            if( $self->{print_response} ) {
               print STDERR "Received HTTP response:\n";
               print STDERR "  $_\n" for split m/\n/, $response->as_string( "\n" );
            }
         })->on_fail( sub {
            my ( undef, $name, $response ) = @_;
            if( $name eq "http" and $self->{print_response} ) {
               print STDERR "Received HTTP response:\n";
               print STDERR "  $_\n" for split m/\n/, $response->as_string( "\n" );
            }
         });
      } foreach => \@res;
   });
}

=head2 request_json

   ( $body, $response ) = $client->request_json( ... )

A small wrapper around C<request> that decodes the returned body as JSON.

=cut

sub request_json
{
   my $self = shift;
   $self->request( @_ )->then( sub {
      my ( $response ) = @_;

      $response->content_type eq "application/json" or
         return Future->fail( "Expected an application/json response body", matrix => );

      Future->done( decode_json( $response->decoded_content ), $response );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
