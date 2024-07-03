#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.807;

package App::sdview::Output::Markdown 0.15;
class App::sdview::Output::Markdown :strict(params);

apply App::sdview::Output;

use String::Tagged::Markdown 0.05;

use constant format => "Markdown";

=head1 NAME

C<App::sdview::Output::Markdown> - generate Markdown output from L<App::sdview>

=head1 SYNOPSIS

   $ sdview README.pod -o Markdown > README.md

=head1 DESCRIPTION

This output module adds to L<App::sdview> the ability to output text in
Markdown formatting. Given a Markdown file as input, the output should be
relatively similar, up to minor details like whitespacing. Given input in some
other format, it will do a reasonable job attempting to represent most of the
structure and formatting.

=cut

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

   $self->say( "```" . ( $para->language // "" ) );
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
      only_tags => [qw( bold italic monospace strikethrough file link )],
      convert_tags => {
         # bold, italic remain as they are
         monospace => "fixed",
         strikethrough => "strike",
         file => "italic", # There isn't a "filename" format in Markdown
         link => sub ($t, $v) { return link => $v->{target} },
      }
   )->build_markdown;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
