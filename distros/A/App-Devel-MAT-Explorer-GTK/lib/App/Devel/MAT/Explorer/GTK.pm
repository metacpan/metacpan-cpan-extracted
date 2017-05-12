#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2016 -- leonerd@leonerd.org.uk

package App::Devel::MAT::Explorer::GTK;

use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

C<App::Devel::MAT::Explorer::GTK> - L<GTK>-based interactive explorer for L<Devel::MAT>

=cut

=head1 INSTALLATION

=head2 SVG Loading

If running this program produces errors similar to

   Couldn't recognize the image file format for file '.../Devel-MAT-UI/icons/refs-All.svg'
   at .../App/Devel/MAT/Explorer/GTK/Resources.pm line 61.

this is likely because F<gdk-pixbuf> does not have an image loader for the SVG
format. This is probably fixed by installing F<librsvg2>, for example

   $ apt-get install librsvg2-2
   $ pkg install librsvg2
   etc...

=cut

0x55AA;
