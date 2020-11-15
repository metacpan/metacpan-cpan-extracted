#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.32;

role App::Device::Chip::UI::WithWrite;

method write
{
   my ( $text ) = @_;

   my $bytes = "";

   local $_ = $text;
   while( length ) {
      s/^\s+// and next;

      s/^"// and do {
         s/^((?:[^"]*|\\.)*)//;
         my $str = $1;
         $bytes .= $str =~ s/\\(.)/$1/gr;
         s/^"// or die "Unterminated \" string\n";
      }, next;

      s/^0x// and do {
         s/^([[:xdigit:]]+)// or die "Unrecognised hex number\n";
         $bytes .= chr hex $1;
      }, next;

      s/^([[:digit:]]+)// and do {
         $bytes .= chr $1;
      }, next;

      die "Unrecognised input '" . substr( $_, 0, 5 ) . "'...\n";
   }

   $self->_do_write( $bytes );
}

0x55AA;
