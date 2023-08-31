#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.800;

package App::sdview::Output::Man 0.12;
class App::sdview::Output::Man
   :does(App::sdview::Output)
   :strict(params);

use constant format => "Man";

use List::Util qw( any );

field $_current_mode = "";

method output_head1 ( $para ) { $self->_output_head( ".SH", $para ); }
method output_head2 ( $para ) { $self->_output_head( ".SS", $para ); }

method _output_head ( $directive, $para )
{
   $self->say( $directive, " ", $self->_convert_str( $para->text ) );
   $_current_mode = "PP";
}

method output_plain ( $para )
{
   $self->say( ".PP" ) unless $_current_mode eq "PP";
   $_current_mode = "";

   $self->say( $self->_convert_str( $para->text ) );
}

method output_verbatim ( $para )
{
   $self->say( ".EX" );

   $self->say( $_ ) for split m/\n/, $para->text;

   $self->say( ".EE" );
}

method output_list_bullet ( $para ) { $self->_output_list( $para ); }
method output_list_text   ( $para ) { $self->_output_list( $para ); }

method _output_list ( $para )
{
   foreach my $item ( $para->items ) {
      if( $item->type ne "item" ) {
         $self->say( ".IP" );
      }
      elsif( $para->listtype eq "bullet" ) {
         $self->say( ".IP \\(bu" );
      }
      elsif( $para->listtype eq "text" ) {
         $self->say( ".TP" );
         $self->say( $self->_convert_str( $item->term ) );
      }

      $self->say( $self->_convert_str( $item->text ) );
   }
}

method _convert_str ( $s )
{
   my $ret = "";

   my @fontstack;

   $s->iter_substr_nooverlap(
      sub ( $substr, %tags ) {
         $ret .= "\\fP", pop @fontstack
            while @fontstack and !$tags{ $fontstack[-1] };

         $tags{C} and (
            any { $_ eq "C" } @fontstack or
               $ret .= "\\f(CW", push @fontstack, "C" );
         $tags{B} and (
            any { $_ eq "B" } @fontstack or
               $ret .= "\\fB", push @fontstack, "B" );
         $tags{I} and (
            any { $_ eq "I" } @fontstack or
               $ret .= "\\fI", push @fontstack, "I" );

         my $man = $substr =~ s/([\\-])/\\$1/gr;

         $ret .= $man;
      }
   );

   $ret .= "\\fP", pop @fontstack
      while @fontstack;

   return $ret;
}

0x55AA;
