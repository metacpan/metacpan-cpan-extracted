#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad;

package App::sdview::Output::Terminal 0.05;
class App::sdview::Output::Terminal isa App::sdview::Output::Formatted :strict(params);

use constant format => "terminal";

use Scalar::Util qw( blessed );
use String::Tagged::Terminal;
use Term::Size;

method setup_output ()
{
   if( -T STDOUT ) {
      open my $outh, "|-", "less", "-R";
      $outh->binmode( ":encoding(UTF-8)" );
      select $outh;
   }
}

method width ()
{
   return scalar Term::Size::chars;
}

method say ( @s )
{
   say map {
      blessed $_ ? String::Tagged::Terminal->new_from_formatting($_)->build_terminal : "$_"
   } @s;
}

0x55AA;
