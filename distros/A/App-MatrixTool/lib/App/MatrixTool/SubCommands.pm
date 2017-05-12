#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::SubCommands;

use strict;
use warnings;
use base qw( App::MatrixTool );

use constant ARGUMENTS => ( "command", "..." );

sub run
{
   my $self = shift;
   my @args = @_;

   my $cmd = shift @args;

   my $pkg = $self->_pkg_for_command( $cmd );
   $pkg->can( "new" ) or
      return $self->error( "No such command '$cmd'" );

   # TODO: ponder global opts?
   my $runner = $pkg->new( %$self );

   $self->run_command_in_runner( $runner, @args );
}

0x55AA;
