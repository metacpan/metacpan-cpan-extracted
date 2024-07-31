#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.800;

package App::sdview::Output 0.18;
role App::sdview::Output;

field $_content;

method say ( @s ) { $_content .= join "", @s, "\n"; }

method maybe_blank { $_content .= "\n" if length $_content; }

method generate ( @paragraphs )
{
   $_content = "";

   while ( @paragraphs ) {
      my $para = shift @paragraphs;

      if( my $code = $self->can( "output_" . ( $para->type =~ s/-/_/gr ) ) ) {
         $self->$code( $para );
      }
      else {
         die "Unhandled paragraph type " . $para->type;
      }
   }

   return $_content;
}

method output ( @paragraphs )
{
   say $self->generate( @paragraphs );
}

0x55AA;
