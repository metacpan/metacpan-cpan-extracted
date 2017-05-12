#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::resolve;

use strict;
use warnings;
use base qw( App::MatrixTool );

our $VERSION = '0.08';

use Future::Utils qw( try_repeat );

use constant DESCRIPTION => "Look up hostnames or IP addresses of a server";
use constant ARGUMENTS => ( "server_name" );
use constant OPTIONS => (
   'a|address' => 'Resolve hostnames into IP addressese',
);

=head1 NAME

matrixtool resolve - Look up hostnames or IP addresses of a server

=head1 SYNOPSIS

   $ matrixtool resolve my-server.org

=head1 DESCRIPTION

This command attempts to find the hostnames or IP addresses to use to
communicate with a given Matrix homeserver. It does not attempt to actually
talk to the server, it merely queries in DNS for information on how to find
the server. It is typically the first diagnostic command to use to determine
whether Matrix server federation is working, and if not where it is failing.

=head1 OPTIONS

The following additional options are recognised:

=over 4

=item C<--address>, C<-a>

Also resolve hostnames into IP addresses in printed output.

=back

=cut

sub run
{
   my $self = shift;
   my ( $opts, $server_name ) = @_;

   $self->http_client->resolve_matrix( $server_name )->then( sub {
      my @res = @_;
      # SRV records yield a 'weight' field, A/AAAA-based backup does not
      defined $res[0]->{weight}
         ? $self->output_info( "Resolved $server_name by SRV" )
         : $self->output_info( "Using legacy IP address fallback" );

      try_repeat {
         my $res = shift;

         $self->output( "target=$res->{target} port=$res->{port}" );

         $opts->{address} or
            return Future->done;

         $self->http_client->resolve_addr( $res->{target} )
            ->then( sub {
               my @addrs = @_;
               foreach my $addr ( @addrs ) {
                  $self->output( "  " . $self->format_hostport( $addr, $res->{port} ) );
               }
               Future->done;
            })
            ->else( sub {
               $self->output( "  address unknown [$_[0]]" );
               Future->done;
            });
      } foreach => \@res;
   });
}

=head1 EXAMPLES

For example, retrieving the F<matrix.org> server's information:

   $ matrixtool resolve matrix.org
   [INFO] Resolved matrix.org by SRV
   target=matrix.org port=8448

We can also see the IP addresses associated with these hostnames:

   $ matrixtool resolve -a matrix.org
   [INFO] Resolved matrix.org by SRV
   target=matrix.org port=8448
     83.166.64.33:8448

Some networks don't publish a C<SRV> record in DNS, so for those the hostname
is implied directly from the server name. For example:

   $ matrixtool resolve example.org
   [INFO] Using legacy IP address fallback
   target=example.org port=8448

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
