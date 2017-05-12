#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::Devel::MAT::Explorer::GTK::Utils;

use strict;
use warnings;

use Exporter 'import';

our @EXPORT = qw(
   bytes2size
);

sub bytes2size
{
   my ( $bytes ) = @_;

   if( $bytes < 1024 ) {
      return $bytes
   }
   if( $bytes < 1024**2 ) {
      return sprintf "%.1f Ki", $bytes / 1024;
   }
   if( $bytes < 1024**3 ) {
      return sprintf "%.1f Mi", $bytes / 1024**2;
   }
   if( $bytes < 1024**4 ) {
      return sprintf "%.1f Gi", $bytes / 1024**3;
   }
   return sprintf "%.1f Ti", $bytes / 1024**4;
}

