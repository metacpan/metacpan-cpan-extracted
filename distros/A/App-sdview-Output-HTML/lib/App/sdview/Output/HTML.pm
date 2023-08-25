#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.800;

package App::sdview::Output::HTML 0.01;
class App::sdview::Output::HTML
   :does(App::sdview::Output)
   :strict(params);

use constant format => "HTML";

use String::Tagged::HTML;

=head1 NAME

C<App::sdview::Output::HTML> - generate HTML output from L<App::sdview>

=head1 SYNOPSIS

   $ sdview Some/File.pod -o HTML > index.html

=head1 DESCRIPTION

This output module adds to L<App::sdview> the ability to output HTML; or at
least, a page fragment that might be used to construct a full HTML page.

Currently, no header or CSS is generated, only the main body content by
relatively simple conversion - headers to C<< <h1> >>, C<< <h2> >>, etc.. and
inline formatting within paragraphs.

=cut

method output_head1 ( $para ) { $self->_output_para( "h1", $para ); }
method output_head2 ( $para ) { $self->_output_para( "h2", $para ); }
method output_head3 ( $para ) { $self->_output_para( "h3", $para ); }
method output_head4 ( $para ) { $self->_output_para( "h4", $para ); }

method output_plain ( $para, $prefix = "" ) { $self->_output_para( "p", $para, $prefix ); }

method _output_para ( $tag, $para, $prefix = "" )
{
   $self->say( $prefix, $self->_convert_str( $para->text, $tag ) );
}

method output_verbatim ( $para, $prefix = "" )
{
   $self->say( "$prefix<pre>\n" . $self->_convert_str( $para->text ), "</pre>" );
}

method output_item ( $para, $prefix = "", $tag = "li" )
{
   $self->_output_para( $tag, $para, $prefix );
}

method output_list_bullet ( $para, $prefix = "" ) { $self->_output_list( "ul", $para, $prefix ); }
method output_list_number ( $para, $prefix = "" ) { $self->_output_list( "ol", $para, $prefix ); }
method output_list_text   ( $para, $prefix = "" ) { $self->_output_list( "dl", $para, $prefix ); }

method _output_list ( $tag, $para, $prefix )
{
   $self->say( "$prefix<$tag>" );

   foreach my $item ( $para->items ) {
      if( $item->type eq "item" and $para->listtype eq "text" ) {
         $self->say( "$prefix  ", $self->_convert_str( $item->term, "dt" ) );
         $self->output_item( $item, "$prefix  ", "dd" );
      }
      else {
         my $code = $self->can( "output_" . ( $item->type =~ s/-/_/gr ) ) or
            die "TODO: Unhandled item type " . $item->type;
         $self->$code( $item, "$prefix  " );
      }
   }

   $self->say( "$prefix</$tag>" );
}

method output_table ( $para, $prefix = "" )
{
   my @rows = $para->rows;

   $self->say( "$prefix<table>" );

   my $first = 1;
   foreach my $row ( @rows ) {
      my $celltag = $first ? "th" : "td";
      undef $first;

      $self->say( "$prefix  <tr>" );

      foreach my $cell ( @$row ) {
         my $align =
            $cell->align eq "centre" ? "center" :
            $cell->align eq "right"  ? "right"  :
                                       undef;

         my $openelem = defined $align ? "<$celltag style=\"text-align: $align;\">" :
                                         "<$celltag>";
         $self->say( "$prefix    $openelem", $self->_convert_str( $cell->text ), "</$celltag>" );
      }
      $self->say( "$prefix  </tr>" );
   }

   $self->say( "$prefix</table>" );
}

method _convert_str ( $s, $tag = undef )
{
   return String::Tagged::HTML->clone(
      $s,
      only_tags => [qw( B I C L )],
      convert_tags => {
         B => "strong",
         I => "em",
         C => "tt",
         # TODO: F
         L => sub ($t, $v) { a => { href => $v->{target} };
         },
      },
   )->as_html( $tag );
}

=head1 TODO

=over 4

=item *

Customisable page header, CSS, general page template?

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
