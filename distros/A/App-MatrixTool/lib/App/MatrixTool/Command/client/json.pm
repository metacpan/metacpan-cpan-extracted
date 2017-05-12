#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::client::json;

use strict;
use warnings;
use base qw( App::MatrixTool::Command::client );

our $VERSION = '0.08';

use constant DESCRIPTION => "Perform a direct JSON request";
use constant ARGUMENTS => ( "path", "data?" );
use constant OPTIONS => (
   'm|method=s' => "HTTP method",
);

=head1 NAME

matrixtool client json - Perform a direct JSON request

=head1 SYNOPSIS

   $ matrixtool client -u @me:example.com json /_matrix/client/r0/publicRooms

=head1 DESCRIPTION

This command performs a direct low-level HTTP request to a Matrix homeserver.
The server name part of the URL is automatically inferred from the given user
ID; the I<PATH> commandline argument only requires the path and optional query
parameters. If an access token is known for the user (see
C<matrixtool client login>) then it is automatically added to the query
parameters as well.

An optional second argument, I<DATA>, may be provided. If so, this should
contain a JSON encoding of data to supply with the request, turning it into a
C<PUT> request. If no data is supplied, then a C<GET> request is performed
instead.

The resulting JSON data from the homeserver is parsed and re-printed in a more
human-readable form to standard output. Linefeeds and indentation whitespace
are used to increase readability.

=head1 OPTIONS

=over 4

=item C<--method>, C<-m>

Use a different HTTP method. If not specified, C<GET> or C<PUT> will be
performed, depending on whether the I<DATA> argument was supplied.

=back

=cut

sub run
{
   my $self = shift;
   my ( $opts, $pathquery, $data ) = @_;

   my $method = "GET";
   $method = "PUT" if defined $data;

   $method = $opts->{method} if defined $opts->{method};

   my %opts;

   $opts{content} = $self->JSON_pretty->decode( $data ) if defined $data;

   my $uri = URI->new( $pathquery );
   if( $uri->query_form ) {
      $opts{params} = { $uri->query_form };
   }

   $self->do_json( $method, $uri->path, %opts )->then( sub {
      my ( $body, $response ) = @_;

      print $self->JSON_pretty->encode( $body ) . "\n";
      Future->done();
   });
}

=head1 EXAMPLES

For example, directly querying your user profile data:

   $ matrixtool client -u @me:example.com json \
       /_matrix/client/r0/profile/@me:example.com
   {
       "avatar_url": "mxc://example.com/aBcDeFgHiJ...",
       "displayname": "Mr Example",
   }

By supplying a second parameter containing JSON-encoded data, we can perform
a C<PUT> request to update the displayname:

   $ matrixtool client -u @me:example.com json \
       /_matrix/client/r0/profile/@me:example.com/displayname \
       '{"displayname":"Mr. Example"}'
   {}

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
