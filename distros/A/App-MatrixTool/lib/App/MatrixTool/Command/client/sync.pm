#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::client::sync;

use strict;
use warnings;
use base qw( App::MatrixTool::Command::client );

our $VERSION = '0.08';

use Future::Utils qw( repeat );

use constant DESCRIPTION => "Follow the /sync event stream";
use constant ARGUMENTS => ();
use constant OPTIONS => (
   'i|initial' => "Print the initial sync result too",
);

=head1 NAME

matrixtool client sync - Follow the C</sync> event stream

=head1 SYNOPSIS

   $ matrixtool client -u @me:example.com sync

=head1 DESCRIPTION

This command follows the event stream from the homeserver by making repeated
calls to the C</sync> API, printing the returned values.

=head1 OPTIONS

=over 4

=item C<--initial>, C<-i>

Include the initial C</sync> result in the output, as well as ongoing updates.

=back

=cut

sub run
{
   my $self = shift;
   my ( $opts ) = @_;

   my $token;

   repeat {
      $self->do_json( GET => "/_matrix/client/r0/sync",
         params => {
            timeout => 30*1000,
            ( defined $token ) ? ( since => $token ) : (),
         }
      )->then( sub {
         my ( $body ) = @_;

         if( defined $token or $opts->{initial} ) {
            print "---\n";
            print $self->JSON_pretty->encode( $body );
         }

         $token = $body->{next_batch};
         Future->done;
      });
   } while => sub { !$_[0]->failure };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
