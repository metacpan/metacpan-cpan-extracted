#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.800;

package App::sdview::Output::Formatted 0.15;
class App::sdview::Output::Formatted :strict(params);

# This isn't itself an output module; but a base class to build them on
# So no `format` constant.

use App::sdview::Style;

use List::Util qw( max );
use String::Tagged 0.15;  # ->from_sprintf

=head1 NAME

C<App::sdview::Output::Formatted> - base class for generating formatted output from L<App::sdview>

=head1 DESCRIPTION

This module is the base class used by  both L<App::sdview::Output::Plain> and
L<App::sdview::Output::Terminal>. It shouldn't be used directly.

=cut

field $_TERMWIDTH;
field $_nextblank;

method output ( @paragraphs )
{
   $self->setup_output();

   $_TERMWIDTH = $self->width;

   foreach my $para ( @paragraphs ) {
      my $code = $self->can( "output_" . ( $para->type =~ s/-/_/gr ) )
         or die "TODO: Unhandled paragraph type " . $para->type;

      $self->$code( $para );
   }
}

# Most paragraphs are handled in a uniform way
*output_head1 = \&_output_para;
*output_head2 = \&_output_para;
*output_head3 = \&_output_para;
*output_head4 = \&_output_para;

*output_plain = \&_output_para;

*output_verbatim = \&_output_para;

*output_item = \&_output_para;

method _output_para ( $para, %opts )
{
   my $margin = $opts{margin} // 0;
   my $leader = $opts{leader};
   my $indent = $opts{indent};

   my %typestyle = App::sdview::Style->para_style( $para->type )->%*;

   $self->say() if $_nextblank;

   my $text = App::sdview::Style->convert_str( $para->text );

   $typestyle{$_} and $text->apply_tag( 0, -1, $_ => $typestyle{$_} )
      for qw( fg bg bold under italic monospace );

   $_nextblank = !!$typestyle{blank_after};

   my @lines = $text->split( qr/\n/ );
   @lines or @lines = ( String::Tagged->new ) if defined $leader;

   # If there's a background set, then space-pad every line to the same width
   # so it looks neater on the terminal
   #   https://rt.cpan.org/Ticket/Display.html?id=140536
   if( defined $typestyle{bg} ) {
      my $width = max map { length $_ } @lines;
      $_ .= " " x ( $width - length $_ ) for @lines;
   }

   $margin += ( $typestyle{margin} // 0 );
   $indent //= 0;

   foreach my $line ( @lines ) {
      length $line or defined $leader or
         ( $self->say() ), next;

      my $width = $_TERMWIDTH - $margin - $indent;

      while( length $line or defined $leader ) {
         my $part;
         if( length($line) > $width ) {
            if( substr($line, 0, $width) =~ m/(\s+)\S*$/ ) {
               my $partlen = $-[1];
               my $chopat = $+[1];

               $part = $line->substr( 0, $partlen );
               $line->set_substr( 0, $chopat, "" );
            }
            else {
               die "ARGH: notsure how to trim this one\n";
            }
         }
         else {
            $part = $line;
            $line = "";
         }

         my $prefix = " "x$margin;;

         if( defined $leader ) {
            my %leaderstyle = App::sdview::Style->para_style( "leader" )->%*;
            $leaderstyle{$_} and $leader->apply_tag( 0, -1, $_ => $leaderstyle{$_} )
               for qw( fg bg bold under italic monospace );

            if( length $leader <= $indent ) {
               # If the leader will fit on the same line
               $prefix .= $leader . " "x($indent - length $leader);
            }
            else {
               # Spill the leader onto its own line
               $self->say( $prefix, $leader );

               $prefix .= " "x$indent if length $part;
            }

            undef $leader;
         }
         else {
            $prefix .= " "x$indent;
         }

         $self->say( $prefix, $part );
      }
   }
}

method output_list_bullet ( $para, %opts ) { $self->_output_list( bullet => $para, %opts ); }
method output_list_number ( $para, %opts ) { $self->_output_list( number => $para, %opts ); }
method output_list_text   ( $para, %opts ) { $self->_output_list( text   => $para, %opts ); }

method _output_list( $listtype, $para, %opts )
{
   my $n = $para->initial;

   my $margin = $opts{margin} // 0;
   $margin += App::sdview::Style->para_style( "list" )->{margin} // 0;

   foreach my $item ( $para->items ) {
      my $leader;
      if( $item->type eq "plain" ) {
         # plain paragraphs in list are treated like items with no leader
         $self->output_item( $item,
            # make sure not to double-count the margin
            margin => $margin - App::sdview::Style->para_style( "plain" )->{margin},
            indent => $para->indent,
         );
         next;
      }
      elsif( $item->type ne "item" ) {
         # non-items just stand as they are + indent
      }
      elsif( $listtype eq "bullet" ) {
         $leader = String::Tagged->new( "•" );
      }
      elsif( $listtype eq "number" ) {
         $leader = String::Tagged->from_sprintf( "%d.", $n++ );
      }
      elsif( $listtype eq "text" ) {
         $leader = App::sdview::Style->convert_str( $item->term );
      }

      my $code = $self->can( "output_" . ( $item->type =~ s/-/_/gr ) ) or
         die "TODO: Unhandled item type " . $item->type;

      $self->$code( $item,
         margin => $margin,
         indent => $para->indent,
         leader => $leader,
      );
   }
}

method output_table ( $para, %opts )
{
   my $margin = $opts{margin} // 0;

   my %typestyle = App::sdview::Style->para_style( "table" )->%*;
   $margin += $typestyle{margin} // 0;

   my $marginspace = " "x$margin;

   my @rows = $para->rows;
   my $ncols = scalar $rows[0]->@*;
   my $maxcol = $ncols - 1;

   my @colwidths = map {
      my $colidx = $_;
      max map { length $rows[$_][$colidx]->text } 0 .. $#rows;
   } 0 .. $maxcol;

   my @hrules = map { "─" x ($colwidths[$_] + 2) } 0 .. $maxcol;

   $self->say( $marginspace, "┌", join( "┬", @hrules ), "┐" );

   # TODO: Much splitting / reflowing of content
   my $firstrow = 1;
   foreach my $row ( @rows ) {
      if( !$firstrow ) {
         $self->say( $marginspace, "├", join( "┼", @hrules ), "┤" );
      }

      my %rowstyle = %typestyle;
      %rowstyle = ( App::sdview::Style->para_style( "table-heading" )->%*, %rowstyle ) if $firstrow;

      my $out = "│";

      foreach my $colidx ( 0 .. $maxcol ) {
         my $cell = $row->[$colidx];

         my $text = App::sdview::Style->convert_str( $cell->text );

         $rowstyle{$_} and $text->apply_tag( 0, -1, $_ => $rowstyle{$_} )
            for qw( fg bg bold under italic monospace );

         my $spare = $colwidths[$colidx] - length $text;
         my $leftpad = ( $cell->align eq "right"  ) ? " "x$spare :
                       ( $cell->align eq "centre" ) ? " "x($spare/2) :
                                                      "";
         my $rightpad = " "x($spare - length $leftpad);

         $out .= " " . $leftpad . $text . $rightpad . " ";
         $out .= "│";
      }
      $self->say( $marginspace, $out );

      undef $firstrow;
   }

   $self->say( $marginspace, "└", join( "┴", @hrules ), "┘" );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
