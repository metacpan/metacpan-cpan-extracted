#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.800;
use Object::Pad ':experimental(adjust_params)';

package App::sdview::Output::Tickit 0.01;
class App::sdview::Output::Tickit
   :strict(params);

use constant format => "tickit";

use App::sdview::Style;

=head1 NAME

C<App::sdview::Output::Tickit> - interactive terminal-based viewer for L<App::sdview>

=head1 SYNOPSIS

   $ sdview README.pod -o tickit

(though this is likely the default output mode if this module is installed)

=head1 DESCRIPTION

This output module provides an interactive terminal-viewer for rendering
documents in L<App::sdview>, showing formatted information on the terminal.
It uses L<Tickit> to provide the terminal interactions.

=cut

# Override default output format
require App::sdview;
$App::sdview::DEFAULT_OUTPUT = "tickit"
   if $App::sdview::DEFAULT_OUTPUT eq "terminal" and -t STDOUT;

field $t;
field $scroller;
ADJUST
{
   # Lazy load all the Tickit modules in here

   require Tickit;
   $t = Tickit->new;

   $t->bind_key( q => sub { $t->stop; } );

   require Tickit::Widget::Scroller;
   Tickit::Widget::Scroller->VERSION( '0.30' );
   $scroller = Tickit::Widget::Scroller->new;

   $scroller->set_gen_bottom_indicator(
      sub ( $scroller ) {
         my $lines_above = $scroller->lines_above;
         my $lines_total = $lines_above + $scroller->window->lines + $scroller->lines_below;
         return sprintf( "%d of %d (%d%%)",
            $lines_above, $lines_total, 100 * $lines_above / $lines_total );
      }
   );

   # Ugh
   $scroller->set_style(
      '<Home>'      => "scroll_to_top",
      '<Space>'     => "scroll_down_page",
      '<Backspace>' => "scroll_up_page",
      '<End>'       => "scroll_to_bottom",
   );
}

method output ( @paragraphs )
{
   require Tickit::Widget::Scroller::Item::RichText;

   foreach my $para ( @paragraphs ) {
      my $code = $self->can( "output_" . ( $para->type =~ s/-/_/gr ) )
         or die "TODO: Unhandled paragraph type " . $para->type;

      $self->$code( $para );
   }

   $t->set_root_widget( $scroller );

   $t->run;
}

# Most paragraphs are handled in a uniform way
*output_head1 = \&_output_para;
*output_head2 = \&_output_para;
*output_head3 = \&_output_para;
*output_head4 = \&_output_para;

*output_plain = \&_output_para;

*output_verbatim = \&_output_para;

*output_item = \&_output_para;

field $_nextblank;

method _output_para ( $para, %opts )
{
   my $margin = $opts{margin} // 0;
   my $leader = $opts{leader};
   my $indent = $opts{indent};

   $scroller->push( Tickit::Widget::Scroller::Item::Text->new( "" ) ) if $_nextblank;

   my %parastyle = App::sdview::Style->para_style( $para->type )->%*;

   $indent //= $parastyle{indent};
   $indent //= 0;

   my $text = App::sdview::Style->convert_str( $para->text );

   my $itempen = Tickit::Pen->new;
   $itempen->chattr( b  => 1 ) if defined $parastyle{bold};
   $itempen->chattr( u  => 1 ) if defined $parastyle{under};
   $itempen->chattr( i  => 1 ) if defined $parastyle{italic};
   $itempen->chattr( af => 1 ) if defined $parastyle{monospace};

   $itempen->chattr( fg => $parastyle{fg}->as_xterm->index )
      if defined $parastyle{fg};
   $itempen->chattr( bg => $parastyle{bg}->as_xterm->index )
      if defined $parastyle{bg};

   my @lines = $text->split( qr/\n/ );

   if( defined $leader ) {
      # TODO: use textwidth
      my $leaderlen = length $leader;

      my %leaderstyle = App::sdview::Style->para_style( "leader" )->%*;
      $leaderstyle{$_} and $leader->apply_tag( 0, $leaderlen, $_ => $leaderstyle{$_} )
         for qw( fg bg bold under italic monospace );

      if( $leaderlen <= $indent ) {
         # Leader will fit on the same line
         $lines[0] = $leader . " "x($indent - $leaderlen) . $lines[0];
      }
      else {
         # spill the leader onto its own line
         unshift @lines, $leader;
      }

   }
   elsif( $para->type ne "verbatim" ) {
      $lines[0] = " "x$indent . $lines[0];
   }

   $text = String::Tagged->join( "\n", @lines );

   my $item;
   if( $para->type eq "verbatim" ) {
      # This handily deals with the paragraph bg too
      $item = App::sdview::Output::Tickit::_FixedWidthItem->new(
         text         => $text,
         margin_left  => $margin + $indent,
         margin_right => 1,
         pen          => $itempen,
      );
   }
   else {
      $item = Tickit::Widget::Scroller::Item::RichText->new_from_formatting( $text,
         indent       => $indent,
         margin_left  => $margin,
         margin_right => 1,
         pen          => $itempen,
      )
   }

   $scroller->push( $item );

   $_nextblank = !!$parastyle{blank_after};
}

method output_list_bullet ( $para, %opts ) { $self->_output_list( bullet => $para, %opts ); }
method output_list_number ( $para, %opts ) { $self->_output_list( number => $para, %opts ); }
method output_list_text   ( $para, %opts ) { $self->_output_list( text   => $para, %opts ); }

method _output_list ( $listtype, $para, %opts )
{
   my $n = $para->initial;

   my $margin = $opts{margin} // 0;
   my $indent = App::sdview::Style->para_style( "list" )->{indent} // 0;

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
         $leader = App::sdview::Style->convert_str( $item->term );
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

class App::sdview::Output::Tickit::_FixedWidthItem
   :strict(params)
{
   use Tickit::Utils qw( textwidth );

   field @_lines;
   field $_maxwidth;
   ADJUST :params (
      :$text,
   ) {
      @_lines = split m/\n/, $text;
      $_maxwidth = 0;
      $_ > $_maxwidth and $_maxwidth = $_ for map { textwidth($_) } @_lines;
   }

   field $_pen          :param = undef;
   field $_margin_left  :param = 0;
   field $_margin_right :param = 0;

   method height_for_width ( $ ) { return scalar @_lines; }

   method render ( $rb, %args )
   {
      my $cols = $args{width};

      foreach my $lineidx ( $args{firstline} .. $args{lastline} ) {
         $rb->goto( $lineidx, 0 );
         $rb->erase( $_margin_left ) if $_margin_left;

         if( $_pen ) {
            $rb->savepen;
            $rb->setpen( $_pen );
         }

         # TODO: truncation if text wider than margin

         $rb->text( $_lines[$lineidx] );
         $rb->erase_to( $_maxwidth + $_margin_left );

         if( $_pen ) {
            $rb->restore;
         }

         $rb->erase_to( $cols );
      }
   }
}

=head1 TODO

=over 4

=item *

Search behaviours

=item *

Follow links, possibly internally implementing a history mechanism or
multiple pages.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
