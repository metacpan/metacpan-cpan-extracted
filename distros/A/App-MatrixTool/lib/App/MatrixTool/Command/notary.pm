#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::notary;

use strict;
use warnings;
use base qw( App::MatrixTool );

our $VERSION = '0.08';

use MIME::Base64 qw( decode_base64 );
use Protocol::Matrix qw( verify_json_signature );

use constant DESCRIPTION => "Fetch a server's signing key via another server";
use constant ARGUMENTS => ( "server_name", "via" );

=head1 NAME

matrixtool notary - Fetch a server's signing key via another server

=head1 SYNOPSIS

   $ matrixtool notary my-server.org matrix.org

=head1 DESCRIPTION

This command uses the notary federation API to fetch the keys from a Matrix
homeserver (the "target") by querying via another server (the "notary"). This
helps you test whether a given server can see the one you are testing.

=head1 OPTIONS

There are no additional options for this command.

=cut

sub get_key_notary_v2
{
   my $self = shift;
   my ( $server_name, $via ) = @_;

   $self->http_client->request_json(
      method => "GET",
      server => $via,
      path   => "/_matrix/key/v2/query/$server_name/*",

      on_ready => sub {
         my ( $conn ) = @_;
         my $socket = $conn->read_handle;

         $self->output_info( "Connected to " . $self->format_addr( $socket->peername ) );
         Future->done;
      },
   )->then( sub {
      my ( $body ) = @_;

      # Find our result.
      foreach ( @{ $body->{server_keys} } ) {
         return Future->done( $_ ) if $_->{server_name} eq $server_name;
      }

      $self->output_fail( "Could not find a key result for '$server_name'");
      Future->fail( "Failed" );
   });
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
   my ( $server_name, $via ) = @_;

   $self->get_key_notary_v2( $server_name, $via )->then( sub {
      my ( $result ) = @_;

      $self->output( "Keys from $result->{server_name} via notary $via" );
      $self->output();

      my $store = $self->server_key_store;

      foreach my $key_id ( keys %{ $result->{verify_keys} } ) {
         my $key = decode_base64 $result->{verify_keys}{$key_id}{key};

         $self->output( "Key id $key_id" );
         $self->output( "  " . $self->format_binary( $key ) );

         my $ok;
         foreach my $signing_server ( keys %{ $result->{signatures} } ) {
            foreach my $signing_key_id ( keys %{ $result->{signatures}{$signing_server} } ) {
               my $signing_key = $store->get( server => $signing_server, id => $key_id );
               next unless defined $signing_key;

               my $verified = eval { verify_json_signature( $result,
                  public_key => $signing_key,
                  origin     => $signing_server,
                  key_id     => $signing_key_id,
               ); 1 };

               $verified or
                  $self->output_check_failure( "Signature verification failed for server_name=$signing_server key_id=$signing_key_id" );

               $verified and $ok++,
                  $self->output_ok( "Verified using server_name=$signing_server key_id=$signing_key_id" );
            }
         }

         my $cached = $store->get( server => $server_name, id => $key_id );
         if( !defined $cached ) {
            # ignore but don't store
         }
         elsif( $cached eq $key ) {
            $self->output_info( "Matches cached key" );
         }
         else {
            $self->output_warn( "Does not match cached key " . $self->format_binary( $cached ) );
         }
      }

      Future->done;
   });
}

=head1 EXAMPLES

For example, once you believe your server is working correctly according to
C<matrixtool server-key> you can query the F<matrix.org> server to see if that
can fetch the same keys:

   $ matrixtool notary example.com matrix.org
   [INFO] Connected to 83.166.64.33:8448
   Keys from example.com via notary matrix.org

   Key id ed25519:auto
     base64::aBcDeFgHiJ...
   [OK] Verified using server_name=matrix.org key_id=ed25519:auto
   [OK] Verified using server_name=example.com key_id=ed25519:auto
   [INFO] Matches cached key

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
