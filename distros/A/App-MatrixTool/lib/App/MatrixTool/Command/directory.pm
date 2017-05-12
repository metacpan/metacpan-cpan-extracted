#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::directory;

use strict;
use warnings;
use base qw( App::MatrixTool );

use URI::Escape qw( uri_escape );

our $VERSION = '0.08';

use constant DESCRIPTION => "Look up room alias to room ID entries";
use constant ARGUMENTS => ( "alias" );
use constant OPTIONS => (
   's|servers' => 'Include list of candidate servers',
);

=head1 NAME

matrixtool directory - Look up room alias to room ID entries

=head1 SYNOPSIS

   $ matrixtool directory '#matrix:matrix.org'

=head1 DESCRIPTION

This command queries the room directory service on a homeserver to map a room
alias name into a room ID. As this is a fully public API that does not need an
access token, this command is separate from C<matrixtool client>.

=head1 OPTIONS

The following additional options are recognised

=over 4

=item C<--servers>, C<-s>

Include a list of candidate servers in the output.

=back

=cut

sub run
{
   my $self = shift;
   my ( $opts, $alias ) = @_;

   my ( $server ) = $alias =~ m/^\#[^:]*:(.*)$/ or
      return Future->fail( "Cannot parse room alias" );

   $self->http_client->request_json(
      method => "GET",
      server => $server,
      path   => "/_matrix/client/r0/directory/room/" . uri_escape( $alias ),
   )->then( sub {
      my ( $body ) = @_;

      my $room_id = $body->{room_id};

      $self->output( "room_id: " . $room_id );

      if( $opts->{servers} ) {
         my $servers = $body->{servers};

         $self->output( "candidate servers:" );
         $self->output( "  $_" ) for @$servers;
      }

      Future->done;
   });
}

=head1 EXAMPLES

For example, resolving a room alias into a room ID:

   $ matrixtool directory '#matrix:matrix.org'
   room_id: !cURbafjkfsMDVwdRDQ:matrix.org

Additionally a list of join candidate servers can also be printed:

   room_id: !cURbafjkfsMDVwdRDQ:matrix.org
   candidate servers:
     matrix.org
     ...

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
