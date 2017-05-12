#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::client;

use strict;
use warnings;
use base qw( App::MatrixTool::SubCommands );

our $VERSION = '0.08';

use constant DESCRIPTION => "Commandline client utilities";
use constant OPTIONS => (
   's|server=s' => "Server",
   'u|user-id=s' => "User ID",
   'U|user-id-parameter=s' => "'user_id' query parameter override",
);

=head1 NAME

matrixtool client - Commandline client utilities for a Matrix homeserver

=head1 SYNOPSIS

   $ matrixtool client login @username:example.com

=head1 DESCRIPTION

This command provides a commandline interface to various client APIs on a
Matrix homeserver. It has various sub-commands that provide particular
functionality, along with some common options between them.

These sub-commands offers a convenience over using simpler tools like F<curl>
directly because they will automatically fill in details like access tokens
and server hostnames, when given a C<user-id> argument. This works by storing
a cache of access tokens in the user's home directory, under
F<.matrix/client-tokens>.

By using the C<matrixtool client login> command you can add an access token
for your user account into this cache:

   $ matrixtool client login @me:example.com
   Password:
   [OK] Obtained access token

Having logged in, you can now use the C<-u> option to other
C<matrixtool client> subcommands, causing it to automatically supply this
access token on every request:

   $ matrixtool client -u @me:example.com json /_matrix/client/r0/publicRooms
   ...

=head1 OPTIONS

The following additional options are recognised

=over 4

=item C<--user-id>, C<-u>

User ID to supply the C<access_token> of.

=item C<--user-id-parameter>, C<-U>

User ID to set as the value of the C<user_id> HTTP query parameter. This is
usually only useful for controlling application service ghosted users.

=item C<--server>, C<-s>

Server to connect to. Usually optional, as it is implied by the C<user-id> if
provided.

=back

=head1 COMMANDS

The following sub-commands are recognised

=head2 json

Perform a direct JSON request

   $ matrixtool client json PATH [DATA]

See also L<App::MatrixTool::Command::client::json>.

=head2 login

Obtain a client authentication token

   $ matrixtool client login USER-ID

See also L<App::MatrixTool::Command::client::login>.

=head2 upload

Upload a file to the media repository

   $ matrixtool client upload FILE [TYPE]

See also L<App::MatrixTool::Command::client::upload>.

=cut

sub run
{
   my $self = shift;
   my ( $opts, @args ) = @_;

   $self->{$_} //= $opts->{$_} for qw( server user_id user_id_parameter );

   return $self->SUPER::run( @args );
}

sub do_json
{
   my $self = shift;
   my ( $method, $path, %opts ) = @_;

   my $client = $self->http_client;

   if( my $user_id = $self->{user_id} ) {
      my ( $server ) = $user_id =~ m/^@.*?:(.*)$/;
      $self->{server} //= $server;
   }

   defined $self->{server} or
      die "Not sure what --server to use\n";

   if( $self->{server} && $self->{user_id} ) {
      my $token = $self->client_token_store->get(
         server => $self->{server},
         id     => $self->{user_id},
      );

      $opts{params}{access_token} = $token if defined $token;
   }

   if( $self->{user_id_parameter} ) {
      $opts{params}{user_id} //= $self->{user_id_parameter};
   }

   $client->request_json(
      server => $self->{server},
      method => $method,
      path   => $path,
      %opts,
   );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
