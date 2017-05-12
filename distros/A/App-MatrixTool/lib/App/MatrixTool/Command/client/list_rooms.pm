#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::client::list_rooms;

use strict;
use warnings;
use base qw( App::MatrixTool::Command::client );

our $VERSION = '0.08';

use constant DESCRIPTION => "List the rooms the user is in";
use constant ARGUMENTS => ();
use constant OPTIONS => ();

=head1 NAME

matrixtool client list-rooms - List the room IDs I am a member of

=head1 SYNOPSIS

This command prints a list of room IDs that the calling user has C<join>
membership of.

=cut

sub run
{
   my $self = shift;

   # the Matrix spec doesn't have a nice way to ask what rooms I'm a member
   # of. About the best we can do is a /sync request with a filter that asks
   # for just the m.room.create event in each room while throwing away all the
   # timeline, account_data and presence.
   # See also
   #   https://github.com/matrix-org/matrix-doc/issues/734

   $self->do_json( GET => "/_matrix/client/r0/sync",
      params => {
         filter =>
            '{"room":{' .
               '"timeline":{"limit":0},' .
               '"state":{"types":["m.room.create"]},' .
               '"ephemeral":{"types":[]}' .
            '},' .
            '"presence":{"types":[]},' .
            '"account_data":{"types":[]}}',
      }
   )->then( sub {
      my ( $body ) = @_;

      my $rooms = $body->{rooms};

      print "$_\n" for keys %{ $rooms->{join} };
      # TODO: think about invite and leave

      Future->done;
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
