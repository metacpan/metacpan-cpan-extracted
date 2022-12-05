#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad;

package App::sdview::Output::Plain 0.09;
class App::sdview::Output::Plain
   :isa(App::sdview::Output::Formatted)
   :strict(params);

use constant format => "plain";

method setup_output ()
{
   STDOUT->binmode( ":encoding(UTF-8)" );
}

method width ()
{
   return 80;
}

method say ( @s )
{
   say map { "$_" } @s;  # stringify to remove the String::Tagged formatting
}

# Ugh this is all backwards; the ::Terminal plugin really wants to be written
# to use this instead
method generate ( @p )
{
   open my $outh, ">:encoding(UTF-8)", \( my $outbuf = "" );
   {
      my $oldh = select;
      select $outh;

      $self->output( @p );

      select $oldh;
   }
   close $outh;

   return Encode::decode( "UTF-8", $outbuf );
}

0x55AA;
