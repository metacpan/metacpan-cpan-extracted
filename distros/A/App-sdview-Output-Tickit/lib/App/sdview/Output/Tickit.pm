#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023-2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.805;

package App::sdview::Output::Tickit 0.08;
class App::sdview::Output::Tickit
   :strict(params);

use constant format => "tickit";

use App::sdview::Style 0.12;
use String::Tagged 0.21; # safe to ->delete_tag during ->iter_extents

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

=item *

C</> - start a regexp search in the document body. See Below.

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

=head2 Regexp Searching

Typing into the main search box enters text that forms a (perl) regexp pattern
to be tested against the body text of the document. Each paragraph is tested
individually and all matches are highlighted. Pressing C<< <Enter> >> will
select the first match. Use the C<< <n> >> and C<< <p> >> keys to jump between
them. Press C<< <Escape> >> to clear the highlights. Press C<< <Alt-i> >> to
toggle case-insensitivity.

=cut

# Override default output format
require App::sdview;
$App::sdview::DEFAULT_OUTPUT = "tickit"
   if $App::sdview::DEFAULT_OUTPUT eq "terminal" and -t STDOUT;

my @HIGHLIGHT_PEN = (
   fg => 16, # avoid bold-black
   bg => "magenta",
   b  => 1,
);

my @SELECT_PEN = (
   bg => "green",
);

field $t;
field $scroller;
field $outlinetree;
field @items;

# Related to searching
field $matchposstatic;
field $matchidx;
field @matches;

ADJUST
{
   # Lazy load all the Tickit modules in here

   require Tickit;
   require Tickit::Utils;

   $t = Tickit->new;
   $t->term->await_started( 0.050 );

   $t->bind_key( q => sub { $t->stop; } );

   require Tickit::Widget::Scroller;
   Tickit::Widget::Scroller->VERSION( '0.32' );
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
   require Tickit::Widget::Scroller::Item::Text;

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

   require Tickit::Widget::Static;

   $matchposstatic = Tickit::Widget::Static->new(
      text => "",
      style => {
         rv => 1,
         fg => "green",
      },
   );
   my $matchposfloat = $fb->add_float(
      child => $matchposstatic,
      hidden => 1,
      top => -2, bottom => -1,
      left => 0, right => 10,
   );

   my $searchbox = App::sdview::Output::Tickit::_SearchBox->new(
      on_incremental => sub ( $searchbox, $searchre ) {
         my @hlmatches;
         foreach my $item ( @items ) {
            push @hlmatches, $item->apply_highlight( $searchre );
         }
         foreach my $match ( @hlmatches ) {
            my ( $item, $e ) = @$match;
            my $startline = $item->line_for_char( $e->start );
            my $where = ( $scroller->item2line( $item, $startline ) )[1] // "";

            next if $where eq "above";

            $scroller->scroll_to( 2, $item, $startline ) if $where eq "below";
            last;
         }
         $scroller->redraw;
         $searchbox->set_matchcount( scalar @hlmatches );
      },
      on_enter => sub ( $searchbox, $searchre ) {
         $matchposfloat->show;

         undef @matches;
         foreach my $item ( @items ) {
            push @matches, $item->apply_highlight( $searchre );
         }
         if( @matches ) {
            $self->select_and_jump( 0 ); # TODO pick the first one visible
         }
         else {
            $matchposfloat->hide;
         }
         $scroller->redraw;
      },
   );

   my $searchfloat = $fb->add_float(
      child => $searchbox,
      hidden => 1,
      top => -2, bottom => -1,
      left => 0, right => -1,
   );

   $searchbox->set_float( $searchfloat );

   # TODO: use ->bind_keys of Tickit 0.75 once released
   $t->bind_key(
      '/' => sub { $searchbox->show },
   );
   $t->bind_key(
      'n' => sub {
         @matches or return;
         $self->select_and_jump( ( $matchidx + 1 ) % @matches );
      },
   );
   $t->bind_key(
      'p' => sub {
         @matches or return;
         $self->select_and_jump( ( $matchidx - 1 ) % @matches );
      },
   );
   $t->bind_key(
      'Escape' => sub {
         $matchposfloat->hide;
         foreach my $item ( @items ) {
            $item->apply_highlight( undef );
         }
         $self->select_and_jump( undef );
         undef @matches;
         $scroller->redraw;
      },
   );

   $t->run;
}

method select_and_jump ( $new_idx )
{
   if( defined $matchidx ) {
      $matches[$matchidx][2] = 0;
   }

   $matchidx = $new_idx;

   if( defined $matchidx ) {
      $matches[$matchidx][2] = 1;

      $matchposstatic->set_text( sprintf "%d of %d", $matchidx+1, scalar @matches );

      my ( $item, $e ) = $matches[$matchidx]->@*;
      my $startline = $item->line_for_char( $e->start );
      $scroller->scroll_to( 2, $item, $startline );

      $scroller->redraw; # to adjust highlights
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
      $item = App::sdview::Output::Tickit::_ParagraphItem->new(
         text         => $text,
         leader       => $leader,
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

   push @items, $item;
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

# Logic kindof stolen from T:W:Scroller::Item::(Rich)Text but modified

sub _convert_color_tag ($n, $v)
{
   return $n => $v->as_xterm->index;
}

my %convert_tags = (
   bold      => "b",
   under     => "u",
   italic    => "i",
   strike    => "strike",
   blink     => "blink",
   monospace => sub ($, $v) { "af" => ( $v ? 1 : 0 ) },
   reverse   => "rv",
   fg        => \&_convert_color_tag,
   bg        => \&_convert_color_tag,
);

class App::sdview::Output::Tickit::_ParagraphItem
   :strict(params)
{
   use Tickit::Utils qw( textwidth );

   field $_pen          :param = undef;
   field $_margin_left  :param = 0;
   field $_margin_right :param = 0;
   field $_indent       :param = 0;

   field $_leader;
   ADJUST :params ( :$leader = undef ) 
   {
      $_leader = $leader->clone( convert_tags => \%convert_tags ) if defined $leader;
   }

   field $_leaderlen;
   field $_has_leaderline      = 0;
   ADJUST {
      $_leaderlen = Tickit::Utils::textwidth( $_leader ) if defined $_leader;
      $_has_leaderline = 1 if $_leaderlen and $_leaderlen + 1 > $_indent;
   }

   field $_text;
   field @_chunks; # => [ $start, $end, $width, $is_softhyphen ]
   ADJUST :params ( :$text )
   {
      $_text = String::Tagged->new( "" );

      my $textplain = "$text";
      pos( $textplain ) = 0;

      while( pos( $textplain ) < length $textplain ) {
         $textplain =~ m/\G\s+/gc and next; # skip whitespace
         $textplain =~ m/\G\xAD/gc and
            $_chunks[-1][3] = 1, next;

         my $chunkstart = pos( $textplain );
         # Find the next chunk by ignoring NBSP
         $textplain =~ m/\G(?[ \S & !\xAD + \xA0 ])+/gc or last;
         my $chunklen = pos( $textplain ) - $chunkstart;

         $_text .= " " if @_chunks and !$_chunks[-1][3];

         my $chunk = $text->substr( $chunkstart, $chunklen )
            ->clone( convert_tags => \%convert_tags );
         my $chunkwidth = textwidth $chunk;

         my $pos = length $_text;

         # Convert NBSP to regular space since it's now been used
         foreach my $e ( $chunk->match_extents( qr/\xA0/ ) ) {
            $chunk->set_substr( $e->start, $e->length, " " );
         }

         $_text .= $chunk;
         push @_chunks, [ $pos, $pos + $chunklen, $chunkwidth ];
      }
   }

   field @_lineruns;
   method _pushline ( $start, $end, $is_softhyphen )
   {
      push @_lineruns, [ $start, $end, $is_softhyphen ];
   }

   method line_for_char ( $char )
   {
      my $line = 0;
      $line++ while $line < $#_lineruns and $_lineruns[$line][1] < $char;
      return $line;
   }

   field $_cached_width;
   method height_for_width ( $width )
   {
      $_cached_width = $width;

      $width -= $_margin_left + $_margin_right;

      @_lineruns = ();
      push @_lineruns, undef if $_has_leaderline;

      # Operate on pos() within textplain as a proxy for the position within
      # the String::Tagged instance
      my $textplain = "$_text";
      pos( $textplain ) = 0;

      my $linestart = 0;
      my $lineend   = 0;
      my $linewidth = 0;
      my $was_softhyphen;

      foreach my $chunk ( @_chunks ) {
         my ( $startpos, $endpos, $chunkwidth, $is_softhyphen ) = @$chunk;

         $linewidth += 1 if $linewidth;

         if( $linewidth + $chunkwidth > $width ) {
            $self->_pushline( $linestart, $lineend, $was_softhyphen // 0 );
            $linestart = $startpos;
            $linewidth = 0;
         }

         $linewidth += $_indent if !$linewidth;

         $linewidth += $chunkwidth;
         $lineend = $endpos;
         $was_softhyphen = $is_softhyphen;
      }

      $self->_pushline( $linestart, $lineend, 0 ) if $linewidth;
      return scalar @_lineruns;
   }

   method render ( $rb, %args )
   {
      my $width = $args{width};

      $self->height_for_width( $width ) if $width != $_cached_width;

      foreach my $line ( $args{firstline} .. $args{lastline} ) {
         $rb->goto( $line, 0 );
         $rb->erase( $_margin_left ) if $_margin_left;

         if( $_pen ) {
            $rb->savepen;
            $rb->setpen( $_pen );
         }

         if( $line == 0 and $_leaderlen ) {
            $_leader->iter_substr_nooverlap(
               sub ( $substr, %tags )
               {
                  my $pen = Tickit::Pen::Immutable->new_from_attrs( \%tags );
                  $rb->text( $substr, $pen );
               },
            );

            goto next_line if $_has_leaderline;
         }

         $rb->erase_to( $_margin_left + $_indent ) if $_indent;

         my ( $start, $end, $is_softhyphen ) = $_lineruns[$line]->@*;
         $_text->iter_substr_nooverlap(
            sub ( $substr, %tags )
            {
               if( exists $tags{highlight} ) {
                  %tags = ( %tags, @HIGHLIGHT_PEN );
                  %tags = ( %tags, @SELECT_PEN ) if $tags{highlight}->$*;
               }
               my $pen = Tickit::Pen::Immutable->new_from_attrs( \%tags );
               $rb->text( $substr, $pen );
            },
            start => $start,
            end   => $end,
         );
         $rb->text( "-" ) if $is_softhyphen;

      next_line:
         if( $_pen ) {
            $rb->erase_to( $width - $_margin_right );
            $rb->restore;
            $rb->erase_to( $width ) if $_margin_right;
         }
         else {
            $rb->erase_to( $width );
         }
      }
   }

   method apply_highlight ( $re )
   {
      my $redraw_needed;

      $_text->iter_extents(
         sub ( $e, $t, $v ) {
            $_text->delete_tag( $e, $t );
            $redraw_needed++;
         },
         only => [qw( highlight )],
      );

      my @ret;

      if( defined $re ) {
         foreach my $e ( $_text->match_extents( $re ) ) {
            push @ret, [ $self, $e, 0 ];
            $_text->apply_tag( $e, highlight => \$ret[-1][2] );
         }
      }

      return @ret;
   }
}

class App::sdview::Output::Tickit::_FixedWidthItem
   :strict(params)
{
   use Tickit::Utils qw( textwidth );

   field $_text;
   field @_lineruns;
   field $_maxwidth;
   ADJUST :params (
      :$text,
   ) {
      $_text = $text;

      my $start = 0;
      while( $text =~ m/\n|$/g ) {
         push @_lineruns, [ $start, $-[0] ];
         $start = $+[0];
      }
      $_maxwidth = 0;
      $_ > $_maxwidth and $_maxwidth = $_ for map { textwidth(substr($text, $_->[0], $_->[1]-$_->[0])) } @_lineruns;
   }

   field $_pen          :param = undef;
   field $_margin_left  :param = 0;
   field $_margin_right :param = 0;

   method height_for_width ( $ ) { return scalar @_lineruns; }

   method line_for_char ( $char )
   {
      my $line = 0;
      $line++ while $line < $#_lineruns and $_lineruns[$line][1] < $char;
      return $line;
   }

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

         my ( $start, $end, $is_softhyphen ) = $_lineruns[$lineidx]->@*;
         $_text->iter_substr_nooverlap(
            sub ( $substr, %tags )
            {
               if( exists $tags{highlight} ) {
                  %tags = ( %tags, @HIGHLIGHT_PEN );
                  %tags = ( %tags, @SELECT_PEN ) if $tags{highlight}->$*;
               }
               my $pen = Tickit::Pen::Immutable->new_from_attrs( \%tags );
               $rb->text( $substr, $pen );
            },
            start => $start,
            end   => $end,
            only  => [qw( highlight )],
         );
         $rb->erase_to( $_maxwidth + $_margin_left );

         if( $_pen ) {
            $rb->restore;
         }

         $rb->erase_to( $cols );
      }
   }

   method apply_highlight ( $re )
   {
      $_text->iter_extents(
         sub ( $e, $t, $v ) {
            $_text->delete_tag( $e, $t );
         },
         only => [qw( highlight )],
      );

      my @ret;

      if( defined $re ) {
         foreach my $e ( $_text->match_extents( $re ) ) {
            push @ret, [ $self, $e, 0 ];
            $_text->apply_tag( $e, highlight => \$ret[-1][2] );
         }
      }

      return @ret;
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

class App::sdview::Output::Tickit::_SearchBox
   :isa(Tickit::Widget)
{
   use constant WIDGET_PEN_FROM_STYLE => 1;

   use constant CAN_FOCUS => 1;

   use Tickit::Style;
   style_definition base =>
      bg => "grey",
      fg => 16, # colour 16 is black but doesn't become grey on bold
      b  => 1,

      bad_fg => 1;

   method lines { 1 }
   method cols  { 1 }

   field $float :writer;

   field $leader = "Search: ";
   field $text = "";

   field $is_ignorecase;

   field $ok = 1;

   field $matchcount = 0;
   method set_matchcount ( $_count ) { $matchcount = $_count; $self->redraw; }

   field $searchre;

   field $on_incremental :param;
   field $on_enter       :param;

   method show ()
   {
      $text = "";
      $float->show;
      $self->window->cursor_at( 0, length($leader) );
      $self->take_focus;
   }

   method dismiss ()
   {
      $float->hide;
   }

   method render_to_rb ( $rb, $rect )
   {
      $rb->eraserect( $rect );

      $rb->goto( 0, 0 );
      $rb->text( $leader );

      $rb->text( $text, $ok ? undef : $self->get_style_pen( "bad" ) );
      $self->window->cursor_at( 0, length($leader) + length($text) );

      my $counttext = sprintf " (%d)", $matchcount;
      if( $is_ignorecase ) {
         $rb->goto( 0, $self->window->right - 2 - length $counttext );
         $rb->text( "/i" );
      }
      $rb->goto( 0, $self->window->right - length $counttext );
      $rb->text( $counttext );
   }

   method on_key ( $ev )
   {
      if( $ev->type eq "text" ) {
         $text .= $ev->str;
         $self->_update_pattern;
         $self->redraw;
         return 1;
      }

      my $key = $ev->str;
      if( $key eq "Backspace" ) {
         substr( $text, -1, 1 ) = "";
         $self->_update_pattern;
         $self->redraw;
      }
      elsif( $key eq "Escape" ) {
         undef $text;
         $self->_update_pattern;
         $self->dismiss;
      }
      elsif( $key eq "Enter" ) {
         $on_enter->( $self, $searchre ) if $on_enter;
         $self->dismiss;
      }
      elsif( $key eq "M-i" ) {
         $is_ignorecase = !$is_ignorecase;
         $self->_update_pattern;
         $self->redraw;
      }
      else {
         return 0;
      }

      return 1;
   }

   method _update_pattern ()
   {
      my $patternok = 0;
      if( defined $text and length $text ) {
         # Compiling the pattern might not succeed; if not just keep the previous
         eval { $searchre = $is_ignorecase ? qr/$text/i : qr/$text/; $patternok = 1 };
      }

      $self->redraw if $patternok != $ok; $ok = $patternok;

      $on_incremental->( $self, $searchre ) if $on_incremental;
   }
}

=head1 TODO

=over 4

=item *

Line-editing and history in the C</> search entry box.

=item *

Follow links, possibly internally implementing a history mechanism or
multiple pages.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
