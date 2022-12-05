#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

use v5.26;

use Object::Pad;

package App::sdview::Output::Markdown 0.09;
class App::sdview::Output::Markdown
   :does(App::sdview::Output)
   :strict(params);

use String::Tagged::Markdown 0.02;

use constant format => "Markdown";

method output_head1 ( $para ) { $self->_output_head( "#",    $para ); }
method output_head2 ( $para ) { $self->_output_head( "##",   $para ); }
method output_head3 ( $para ) { $self->_output_head( "###",  $para ); }
method output_head4 ( $para ) { $self->_output_head( "####", $para ); }

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

   my $n = $para->initial;
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

method output_table ( $para )
{
   $self->maybe_blank;

   my @rows = $para->rows;

   my $first = 1;
   foreach my $row ( @rows ) {
      my @cells = @$row;
      $self->say( join "|", "", ( map { " " . $self->_convert_str( $_->text ) . " " } @cells ), "" );

      next unless $first;

      my @aligns = map {
         my $n = length $_->text;
         $_->align eq "centre" ? ":".("-"x($n-2)).":" :
         $_->align eq "right"  ?     ("-"x($n-1)).":" :
                                     ("-"x $n   );
      } @cells;
      $self->say( join "|", "", ( map { " $_ " } @aligns ), "" );
      undef $first;
   }
}

method _convert_str ( $s )
{
   return String::Tagged::Markdown->clone( $s,
      only_tags => [qw( C B I F L )],
      convert_tags => {
         C => "fixed",
         B => "bold",
         I => "italic",
         F => "italic", # There isn't a "filename" format in Markdown
         L => sub ($t, $v) { return link => $v->{target} },
      }
   )->build_markdown;
}

0x55AA;
