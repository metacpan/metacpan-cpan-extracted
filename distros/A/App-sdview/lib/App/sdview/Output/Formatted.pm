#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad;

package App::sdview::Output::Formatted 0.05;
class App::sdview::Output::Formatted :strict(params);

# This isn't itself an output module; but a base class to build them on
# So no `format` constant.

use Convert::Color;
use Convert::Color::XTerm 0.06;
use List::Util qw( max );
use String::Tagged 0.15;  # ->from_sprintf

my %FORMATSTYLES = (
   B => { bold => 1 },
   I => { italic => 1 },
   F => { italic => 1, under => 1 },
   C => { monospace => 1, bg => Convert::Color->new( "xterm:235" ) },
   L => { under => 1, fg => Convert::Color->new( "xterm:rgb(3,3,5)" ) }, # light blue
);

sub _convert_str ( $s )
{
   return $s->clone(
      convert_tags => {
         ( map { $_ => do { my $k = $_; sub { $FORMATSTYLES{$k}->%* } } } keys %FORMATSTYLES ),
      },
   );
}

my %PARASTYLES = (
   head1    => { fg => Convert::Color->new( "vga:yellow" ), bold => 1 },
   head2    => { fg => Convert::Color->new( "vga:cyan" ), bold => 1, indent => 2 },
   head3    => { fg => Convert::Color->new( "vga:green" ), bold => 1, indent => 4 },
   # TODO head4
   plain    => { indent => 6, blank_after => 1 },
   verbatim => { indent => 8, blank_after => 1, $FORMATSTYLES{C}->%* },
   list     => { indent => 6 },
   leader   => { bold => 1 },
   table    => { indent => 8 },
   "table-heading" => { bold => 1 },
);
$PARASTYLES{item} = $PARASTYLES{plain};

has $_TERMWIDTH;
has $_nextblank;

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
   my %typestyle;

   $PARASTYLES{ $para->type } or
      die "Unrecognised paragraph style for " . $para->type;

   # TODO: merge typestyle argument
   $PARASTYLES{ $para->type } and
      %typestyle = ( $PARASTYLES{ $para->type }->%* );

   $self->say() if $_nextblank;

   my $text = _convert_str( $para->text );

   $typestyle{$_} and $text->apply_tag( 0, -1, $_ => $typestyle{$_} )
      for qw( fg bg bold under italic monospace );

   $_nextblank = !!$typestyle{blank_after};

   my @lines = $text->split( qr/\n/ );
   @lines or @lines = ( String::Tagged->new ) if defined $leader;

   $indent //= $typestyle{indent};
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
            my %leaderstyle = $PARASTYLES{leader}->%*;
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
   my $indent = $PARASTYLES{list}{indent} // 0;

   foreach my $item ( $para->items ) {
      my $leader;
      if( $item->type ne "item" ) {
         # non-items just stand as they are + indent
      }
      elsif( $listtype eq "bullet" ) {
         $leader = String::Tagged->new( "•" );
      }
      elsif( $listtype eq "number" ) {
         $leader = String::Tagged->from_sprintf( "%d.", $n++ );
      }
      elsif( $listtype eq "text" ) {
         $leader = _convert_str( $item->term );
      }

      my $code = $self->can( "output_" . ( $item->type =~ s/-/_/gr ) ) or
         die "TODO: Unhandled item type " . $item->type;

      $self->$code( $item,
         margin => $margin + $indent,
         indent => $para->indent,
         leader => $leader,
      );
   }
}

method output_table ( $para, %opts )
{
   my $margin = $opts{margin} // 0;
   my $indent = $opts{indent};

   my %typestyle = $PARASTYLES{table}->%*;

   $indent //= $typestyle{indent};
   $indent //= 0;

   my @rows = $para->rows;
   my $ncols = scalar $rows[0]->@*;
   my $maxcol = $ncols - 1;

   my @colwidths = map {
      my $colidx = $_;
      max map { length $rows[$_][$colidx]->text } 0 .. $#rows;
   } 0 .. $maxcol;

   my @hrules = map { "─" x ($colwidths[$_] + 2) } 0 .. $maxcol;

   $self->say( " " x $indent, "┌", join( "┬", @hrules ), "┐" );

   # TODO: Much splitting / reflowing of content
   my $firstrow = 1;
   foreach my $row ( @rows ) {
      if( !$firstrow ) {
         $self->say( " " x $indent, "├", join( "┼", @hrules ), "┤" );
      }

      my %rowstyle = %typestyle;
      %rowstyle = ( $PARASTYLES{ "table-heading" }->%*, %rowstyle ) if $firstrow;

      my $out = "│";

      foreach my $colidx ( 0 .. $maxcol ) {
         my $cell = $row->[$colidx];

         my $text = _convert_str( $cell->text );

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
      $self->say( " "x$indent, $out );

      undef $firstrow;
   }

   $self->say( " " x $indent, "└", join( "┴", @hrules ), "┘" );
}

0x55AA;
