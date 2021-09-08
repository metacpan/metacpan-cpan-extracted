#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;

use Object::Pad;

package App::sdview::Output::Markdown 0.04;
class App::sdview::Output::Markdown
   does App::sdview::Output
   :strict(params);

use constant format => "Markdown";

method output_head1 ( $para ) { $self->_output_head( "#",   $para ); }
method output_head2 ( $para ) { $self->_output_head( "##",  $para ); }
method output_head3 ( $para ) { $self->_output_head( "###", $para ); }

method _output_head ( $leader, $para )
{
   $self->maybe_blank;

   $self->say( $leader, " ", $self->_convert_str( $para->text ) );
}

method output_plain ( $para )
{
   $self->maybe_blank;

   $self->say( $self->_convert_str( $para->text ) );
}

method output_verbatim ( $para )
{
   $self->maybe_blank;

   # TODO: Offer a choice of ``` vs indented

   $self->say( "```" );
   $self->say( $para->text );
   $self->say( "```" );
}

method output_list_bullet ( $para ) { $self->_output_list( $para ); }
method output_list_number ( $para ) { $self->_output_list( $para ); }

method _output_list ( $para )
{
   $self->maybe_blank;

   my $n = 1;
   foreach my $item ( $para->items ) {
      my $leader;

      if( $para->listtype eq "bullet" ) {
         $leader = "*";
      }
      elsif( $para->listtype eq "number" ) {
         $leader = sprintf "%d.", $n++;
      }

      $self->say( $leader, " ", $self->_convert_str( $item->text ) );
   }
}

method _convert_str ( $s )
{
   my $ret = "";

   my %active;

   $s->iter_substr_nooverlap(
      sub ( $substr, %tags ) {
         my $md = $substr =~ s/([*`\\])/\\$1/gr;

         # No need to escape _ if it's ``-wrapped
         if( $tags{C} ) {
            $md = "`$md`";
         }
         else {
            $md =~ s/_/\\_/g;
         }

         $md = "**$md**" if $tags{B};
         $md = "*$md*"   if $tags{I};

         # There isn't a "filename" format in Markdown, we'll just use italics
         $md = "_${md}_" if $tags{F};

         $md = "[$md]($tags{L}{target})" if $tags{L};

         $ret .= $md;
      }
   );

   return $ret;
}

0x55AA;
