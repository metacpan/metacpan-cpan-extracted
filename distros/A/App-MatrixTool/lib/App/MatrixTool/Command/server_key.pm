#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::server_key;

use strict;
use warnings;
use base qw( App::MatrixTool );

our $VERSION = '0.08';

use MIME::Base64 qw( decode_base64 );
use Protocol::Matrix qw( verify_json_signature );

use Net::Async::HTTP;
Net::Async::HTTP->VERSION( '0.40' ); # ->request on_ready

use constant SHA256_ALGO => do {
   require Net::SSLeay;
   Net::SSLeay::SSLeay_add_ssl_algorithms();
   Net::SSLeay::EVP_get_digestbyname( "sha256" );
};

use constant DESCRIPTION => "Fetch a server's signing key";
use constant ARGUMENTS => ( "server_name" );
use constant OPTIONS => (
   '1|v1'       => "Restrict to the v1 key API",
   '2|v2'       => "Restrict to the v2 key API",
   'n|no-store' => "Don't cache the received key in the key store",
);

=head1 NAME

matrixtool server-key - Fetch a server's signing key

=head1 SYNOPSIS

   $ matrixtool server-key my-server.org

=head1 DESCRIPTION

This command fetches the keys from a Matrix homeserver. This helps you test
whether the server is basically configured correctly, responding to basic
federation key requests.

=head1 OPTIONS

The following additional options are recognised

=over 4

=item C<--v1>, C<-1>

Restrict to the v1 key API

=item C<--v2>, C<-2>

Restrict to the v2 key API

=item C<--no-store>, C<-n>

Don't cache the received key in the key store

=back

=cut

sub get_key_v1
{
   my $self = shift;
   my ( $server_name ) = @_;

   my $server_cert;

   $self->http_client->request_json(
      server  => $server_name,
      request => $self->federation->make_key_v1_request(
         server_name => $server_name,
      ),

      on_ready => sub {
         my ( $conn ) = @_;
         my $socket = $conn->read_handle;

         $server_cert = $socket->peer_certificate;

         $self->output_info( "Connected to " . $self->format_addr( $socket->peername ) );
         Future->done;
      },
   )->then( sub {
      my ( $body ) = @_;

      $body->{server_name} eq $server_name or
         $self->output_check_failure( "Returned server_name does not match" );

      # Ugh SSLeay is a pain
      my $bio = Net::SSLeay::BIO_new( Net::SSLeay::BIO_s_mem() );
      Net::SSLeay::BIO_write( $bio, decode_base64 $body->{tls_certificate} );

      my $got_cert = Net::SSLeay::d2i_X509_bio( $bio ) or
         die Net::SSLeay::print_errs("d2i_X509_bio");

      Net::SSLeay::X509_digest( $server_cert, SHA256_ALGO ) eq Net::SSLeay::X509_digest( $got_cert, SHA256_ALGO )
         ? $self->output_ok( "TLS certificate fingerprint matches (SHA-256)" )
         : $self->output_check_failure( "TLS certificate fingerprint does not match" );

      my $keys = $body->{verify_keys};
      my @keys = map { { id => $_, key => decode_base64 $keys->{$_} } } sort keys %$keys;

      $self->verify( $body, @keys );

      Future->done(
         version     => "v1",
         server_name => $body->{server_name},
         keys        => \@keys,
      );
   });
}

sub get_key_v2
{
   my $self = shift;
   my ( $server_name ) = @_;

   my $server_cert;

   $self->http_client->request_json(
      server  => $server_name,
      request => $self->federation->make_key_v2_server_request(
         server_name => $server_name,
         key_id      => "*",
      ),

      on_ready => sub {
         my ( $conn ) = @_;
         my $socket = $conn->read_handle;

         $server_cert = $socket->peer_certificate;

         $self->output_info( "Connected to " . $self->format_addr( $socket->peername ) );
         Future->done;
      },
   )->then( sub {
      my ( $body ) = @_;

      my $fingerprint = Net::SSLeay::X509_digest( $server_cert, SHA256_ALGO );

      $body->{server_name} eq $server_name or
         $self->output_check_failure( "Returned server_name does not match" );

      my $fprint_ok;
      foreach ( @{ $body->{tls_fingerprints} } ) {
         $_->{sha256} or next;
         decode_base64( $_->{sha256} ) eq $fingerprint and $fprint_ok++, last;
      }
      $fprint_ok ? $self->output_ok( "TLS fingerprint matches (SHA-256)" )
         : $self->output_check_failure( "TLS fingerprint does not match any listed" );

      my $keys = $body->{verify_keys};
      my @keys = map { { id => $_, key => decode_base64 $keys->{$_}{key} } } sort keys %$keys;

      $self->verify( $body, @keys );

      Future->done(
         version     => "v2",
         server_name => $body->{server_name},
         keys        => \@keys,
      );
   });
}

sub verify
{
   my $self = shift;
   my ( $body, @keys ) = @_;

   my %keys_by_id = map { $_->{id} => $_->{key} } @keys;

   my $ok;
   foreach my $origin ( sort keys %{ $body->{signatures} } ) {
      foreach my $key_id ( sort keys %{ $body->{signatures}{$origin} } ) {
         my $key = $keys_by_id{$key_id} or do {
            $self->output_info( "Skipping origin=$origin key_id=$key_id as there is no useable public key" );
            next;
         };

         my $verified = eval { verify_json_signature( $body,
            public_key => $key,
            origin     => $origin,
            key_id     => $key_id,
         ); 1 };

         $verified or
            $self->output_check_failure( "Signature verification failed for origin=$origin key_id=$key_id" );

         $verified and $ok++,
            $self->output_ok( "Verified using origin=$origin key_id=$key_id" );
      }
   }

   $ok or
      $self->output_check_failure( "Failed to find any valid signatures" );
}

sub output_check_failure
{
   my $self = shift;
   # TODO: option to make this fatal or non-fatal
   $self->output_fail( @_ );
}

sub run
{
   my $self = shift;
   my ( $opts, $server_name ) = @_;

   $opts->{v1} and $opts->{v2} and
      return $self->error( "Cannot request 'v1' and 'v2' key API at the same time" );

   ( $opts->{v1} ? Future->fail( "No v2" ) : $self->get_key_v2( $server_name ) )
      ->else_with_f( sub { $opts->{v2} ? shift : $self->get_key_v1( $server_name ) } )
   ->then( sub {
      my %result = @_;
      $self->output( "$result{version} keys from $result{server_name}:" );
      $self->output();

      my $store = $self->server_key_store;
      my %cached_keys = $store->list( server => $result{server_name} );

      foreach ( @{ $result{keys} } ) {
         $self->output( "Key id $_->{id}" );
         $self->output( "  " . $self->format_binary( $_->{key} ) );

         if( !exists $cached_keys{ $_->{id} } ) {
            $store->put(
               server => $result{server_name},
               id     => $_->{id},
               data   => $_->{key},
            ) unless $opts->{no_store};
         }
         elsif( $cached_keys{ $_->{id} } eq $_->{key} ) {
            $self->output_info( "Matches cached key" );
         }
         else {
            $self->output_warn( "Does not match cached key " . $self->format_binary( $cached_keys{ $_->{id} } ) );
         }
      }

      Future->done;
   });
}

=head1 EXAMPLES

For example, fetching the keys from a server:

   $ matrixtool server-key matrix.org
   [INFO] Connected to 83.166.64.33:8448
   Keys from matrix.org

   Key id ed25519:auto
     base64::aBcDeFgHiJ...
   [INFO] Matches cached key

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
