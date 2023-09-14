#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.800;
use Object::Pad ':experimental(adjust_params)';

package App::sdview::Output::Tickit 0.03;
class App::sdview::Output::Tickit
   :strict(params);

use constant format => "tickit";

use App::sdview::Style 0.12;
use String::Tagged 0.17; # ->join method

=head1 NAME

C<App::sdview::Output::Tickit> - interactive terminal-based viewer for L<App::sdview>

=head1 SYNOPSIS

   $ sdview README.pod -o tickit

(though this is likely the default output mode if this module is installed)

=head1 DESCRIPTION

This output module provides an interactive terminal-viewer for rendering
documents in L<App::sdview>, showing formatted information on the terminal.
It uses L<Tickit> to provide the terminal interactions.

=head2 Keybindings

=over 4

=item *

C<Home> - scroll to top

=item *

C<Backspace> - scroll up a page

=item *

C<PageUp> - scroll up half a page

=item *

C<Up> - scroll up a line

=item *

C<Down> - scroll down a line

=item *

C<PageDown> - scroll down half a page

=item *

C<Space> - scroll down a page

=item *

C<End> - scroll to bottom

=item *

C<F9> - open the outline view popup. See Below.

=item

C<q> - exit

=back

=head2 Outline View

The outline view displays an overview of all the section headings in the
document.

Within the outline view, the mouse wheel will scroll the list, and clicking an
entry will jump directly to it, dismissing the view.

Typing text with the outline view open will filter it to just those headings
matching the typed text. Pressing the C<< <Enter> >> key will jump directly to
the first highlighted heading, again dismissing the view.

=cut

# Override default output format
require App::sdview;
$App::sdview::DEFAULT_OUTPUT = "tickit"
   if $App::sdview::DEFAULT_OUTPUT eq "terminal" and -t STDOUT;

field $t;
field $scroller;
field $outlinetree;
ADJUST
{
   # Lazy load all the Tickit modules in here

   require Tickit;
   require Tickit::Utils;

   $t = Tickit->new;
   $t->term->await_started( 0.050 );

   $t->bind_key( q => sub { $t->stop; } );

   require Tickit::Widget::Scroller;
   Tickit::Widget::Scroller->VERSION( '0.31' );
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

   $outlinetree = App::sdview::Output::Tickit::_OutlineTree->new;
}

method output ( @paragraphs )
{
   require Tickit::Widget::Scroller::Item::RichText;

   foreach my $para ( @paragraphs ) {
      my $code = $self->can( "output_" . ( $para->type =~ s/-/_/gr ) )
         or die "TODO: Unhandled paragraph type " . $para->type;

      $self->$code( $para );
   }

   require Tickit::Widget::FloatBox;

   $t->set_root_widget( my $fb = Tickit::Widget::FloatBox->new
      ->set_base_child( $scroller )
   );

   my $outlinefloat = $fb->add_float(
      child => $outlinetree,
      hidden => 1, # initially hidden
      top => 0, bottom => -1,
      left => 0, right => 25, # ideally we want to set "30%" or somesuch here
   );

   $t->bind_key(
      'F9' => sub { $outlinefloat->is_visible ? $outlinefloat->hide : $outlinefloat->show },
   );

   $scroller->set_on_scrolled( sub ( $scroller, $ ) {
      my $itemidx = $scroller->line2item( 0 );
      $outlinetree->set_current_itemidx( $itemidx );
   } );
   $outlinetree->set_current_itemidx( 0 ); # initial

   $outlinetree->set_on_select_item( sub ( %params ) {
      $scroller->scroll_to( 0, $params{itemidx}, 0 );
      $outlinefloat->hide;
   } );


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

   $margin += ( $parastyle{margin} // 0 );
   $indent //= 0;

   my @lines = $text->split( qr/\n/ );

   if( defined $leader ) {
      my $leaderlen = Tickit::Utils::textwidth( $leader );

      my %leaderstyle = App::sdview::Style->para_style( "leader" )->%*;
      $leaderstyle{$_} and $leader->apply_tag( 0, $leaderlen, $_ => $leaderstyle{$_} )
         for qw( fg bg bold under italic monospace );

      if( $leaderlen + 1 <= $indent ) {
         # Leader will fit on the same line
         $lines[0] = $leader . " "x($indent - $leaderlen) . $lines[0];
      }
      else {
         # spill the leader onto its own line
         unshift @lines, $leader;
      }

   }
   elsif( $para->type ne "verbatim" ) {
      $lines[0] = " "x$indent . $lines[0] if @lines;
   }

   @lines or @lines = ( String::Tagged->new( "" ) ); # placate String::Tagged->join bug

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

   if( $para->type =~ m/^head(\d+)/ ) {
      my $level = $1;
      my $itemidx = $scroller->items;
      $outlinetree->add_item( "$lines[0]", $level, $itemidx );
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

class App::sdview::Output::Tickit::_OutlineTree
   :isa(Tickit::Widget)
{
   use constant WIDGET_PEN_FROM_STYLE => 1;
   use constant CAN_FOCUS => 1;

   use Tickit::Style;
   style_definition base =>
      bg => "blue",

      selected_b => 1,

      highlighted_fg => "black",
      highlighted_bg => "yellow";

   class App::sdview::Output::Tickit::_OutlineTree::Item {
      field $label   :reader :param;
      field $indent  :reader :param;
      field $itemidx :reader :param;
   }

   field @all_items;

   field $filter = "";

   field @displayed_items;
   field $scrolloff = 0;

   method _normalize_scrolloff
   {
      $scrolloff = 0 if $scrolloff < 0;

      my $lines = $self->window->lines;
      my $maxoff = scalar @displayed_items - $lines;
      $maxoff = 0 if $maxoff < 0;

      $scrolloff = $maxoff if $scrolloff > $maxoff;
   }

   method resized { $self->_normalize_scrolloff }

   field $on_select_item :param :writer = undef;

   field $current;

   method lines { return scalar @displayed_items }
   method cols  { 1 }

   method add_item ( $label, $level, $itemidx )
   {
      push @all_items, App::sdview::Output::Tickit::_OutlineTree::Item->new(
         label   => $label,
         indent  => ($level-1) * 2 + 1,
         itemidx => $itemidx,
      );
      push @displayed_items, $all_items[-1];
   }

   method _update_filter
   {
      if( length $filter ) {
         my $re = qr/\Q$filter/i;
         @displayed_items = grep { $_->label =~ $re } @all_items;
      }
      else {
         @displayed_items = @all_items;
      }
      $self->redraw;
   }

   method set_current_itemidx ( $itemidx )
   {
      # TODO: binary search would be faster
      foreach my $i ( reverse 0 .. $#all_items ) {
         my $item = $all_items[$i];
         next if $item->itemidx > $itemidx;

         $current = $i;
         last;
      }

      return unless my $win = $self->window;
      my $bottom = $win->lines - 1;
      if( $current < $scrolloff ) {
         $scrolloff = $current;
      }
      elsif( $current > $scrolloff + $bottom ) {
         $scrolloff = $current - $bottom;
      }

      $self->redraw if $self->window && $self->window->is_visible;
   }

   method render_to_rb ( $rb, $rect )
   {
      $rb->eraserect( $rect );

      my $re = length $filter ? qr/\Q$filter/i : undef;

      foreach my $line ( $rect->top .. $rect->bottom - 2 ) {
         ($line + $scrolloff) < @displayed_items or last;
         my $item = $displayed_items[$line + $scrolloff];

         $rb->goto( $line, 0 );
         $rb->savepen;

         if( ( $line + $scrolloff ) == $current ) {
            $rb->setpen( $self->get_style_pen( 'selected' ) );
            $rb->text( ">" );
         }
         $rb->erase_to( $item->indent );

         my $label = $item->label;
         if( defined $re ) {
            my $oldpos = 0;
            while( $label =~ m/$re/gc ) {
               $rb->text( substr $label, $oldpos, $-[0]-$oldpos ) if $-[0] > $oldpos;

               $rb->savepen;
               $rb->setpen( $self->get_style_pen( 'highlighted' ) );
               $rb->text( substr $label, $-[0], $+[0]-$-[0] ); # TODO: highlight pen
               $rb->restore;

               $oldpos = $+[0];
            }
            $rb->text( substr $label, $oldpos ) if $oldpos < length $label;
         }
         else {
            $rb->text( $label );
         }

         $rb->restore;
      }

      $rb->goto( $rect->bottom - 1, 0 );
      if( length $filter ) {
         $rb->text( "Search: " . $filter );
      }
      else {
         $rb->savepen;
         $rb->setpen( Tickit::Pen::Immutable->new( i => 1 ) );
         $rb->text( "Type to search" );
         $rb->restore;
      }

      $rb->vline_at( $rect->top, $rect->bottom, $rect->right-1,
         Tickit::RenderBuffer::LINE_SINGLE, undef, Tickit::RenderBuffer::CAP_BOTH );
   }

   method on_key ( $ev )
   {
      if( $ev->type eq "text" ) {
         $filter .= $ev->str;
         $self->_update_filter;
         return 1;
      }

      my $key = $ev->str;
      if( $key eq "Backspace" ) {
         substr( $filter, -1, 1 ) = "" if length $filter;
         $self->_update_filter;
      }
      elsif( $key eq "Enter" ) {
         my $item = $displayed_items[0];
         $filter = "";
         $self->_update_filter;
         $on_select_item->( itemidx => $item->itemidx );
      }
      else {
         return 0;
      }

      return 1;
   }

   method on_mouse ( $ev )
   {
      if( $ev->type eq "wheel" ) {
         $scrolloff += 5 if $ev->button eq "down";
         $scrolloff -= 5 if $ev->button eq "up";
         $self->_normalize_scrolloff;
         $self->redraw;
      }
      elsif( $ev->type eq "press" && $ev->button == 1 ) {
         if( my $item = $displayed_items[$ev->line + $scrolloff] ) {
            $on_select_item->( itemidx => $item->itemidx );
         }
      }

      return 1;
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
