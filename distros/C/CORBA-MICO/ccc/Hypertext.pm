package CORBA::MICO::Hypertext;
require Exporter;

use Gtk2 '1.140';
require CORBA::MICO::Misc;

use strict;

@CORBA::MICO::Hypertext::ISA = qw(Exporter);
@CORBA::MICO::Hypertext::EXPORT = qw();
@CORBA::MICO::Hypertext::EXPORT_OK = qw(
     hypertext_create
     hypertext_show
     item_prefix
     item_suffix
);

#--------------------------------------------------------------------
sub item_prefix {
  return "\0x1";
}

#--------------------------------------------------------------------
sub item_suffix {
  return "\0x2";
}

#--------------------------------------------------------------------
# Create a 'hypertext' object
#--------------------------------------------------------------------
sub hypertext_create {
  my $scrolled = new Gtk2::ScrolledWindow(undef,undef); # scrolled for main text
  $scrolled->set_policy( 'automatic', 'automatic' );
  my $text = Gtk2::TextView->new;
  $text->set_wrap_mode ('none');
  $text->set_editable(0);
  $text->set_cursor_visible(0);
  $scrolled->add($text);
  my $retval = new Gtk2::VPaned;
  $retval->pack1($scrolled, 1, 0);
  $retval->set_size_request(600, 400);
  $retval->show_all();
  return $retval;
}

#--------------------------------------------------------------------
# Show IDL-representation of given IR object via hypertext widget
#  $widget - hypertext widget
#  $name - name of item to be shown
#  $udata - user data to be passed each time callback is called
#  $prepare_cb - callback subroutine to be called to prepare text
#         has arguments:
#               $name - item name
#               $udata - user data (== corresponding argument passed to 'show')
#         return value: a reference to list of lines must be shown
#--------------------------------------------------------------------
sub hypertext_show {
  my ($htext, $name, $prepare_cb, $udata, $prepost_cb, $parents) = @_;
  my $scrolled = $htext->get_child1();
  return unless $scrolled;
  my $text = $scrolled->get_child();
  return unless $text;
  my $buffer = $text->get_buffer();
  $buffer->set_text("");
  return unless defined($name);                 # just clear if no name given
  $parents = [] unless defined $parents;
  my $cbdata = { NAME        => $name,
                 CALLBACK    => $prepare_cb, 
                 UDATA       => $udata,
                 PARENTS     => $parents,
                 WPARENT     => $htext,
                 PREPOST     => $prepost_cb,
                 SRCHDATA    => {},
                 CURSOR_HAND => undef };
  #$htext->show_all();
  $prepost_cb->($udata, 1);
  CORBA::MICO::Misc::cursor_watch($htext, 0);
  $text->get_window('text')->set_cursor(Gtk2::Gdk::Cursor->new('watch'));
  $htext->queue_draw();
  return if CORBA::MICO::Misc::process_pending();
  my $desc = $prepare_cb->($name, $udata);
  my $iter = $buffer->get_iter_at_offset(0);
  if( defined($desc) ) {
    my $cnt = 0;
    foreach my $line (@$desc) {
      my @parts = split(item_suffix, $line);
      foreach my $portion (@parts) {
        my @regions = split(item_prefix, $portion);
        if( @regions != 2 ) {
          $buffer->insert($iter, join("", @regions));
        }
        else {
          $buffer->insert($iter, $regions[0]);
          my $tag = $buffer->create_tag(undef, foreground => 'blue');
          $tag->{_NODE_} = $regions[1];
          $buffer->insert_with_tags($iter, $regions[1], $tag);
        }
      }
      $buffer->insert($iter, "\n");
      CORBA::MICO::Misc::process_pending()  unless ++$cnt % 10;
    }
  }
  $text->{CBDATA} = $cbdata;
  $text->signal_connect(event_after     => \&event_after);
  $text->signal_connect(backspace       => \&event_backspace);
  CORBA::MICO::Misc::cursor_restore_to_default($htext, 0);
  set_curs($text, $cbdata);
  $prepost_cb->($udata, 0);

  $htext->queue_draw();
}

#--------------------------------------------------------------------
# Search
sub do_search {
  my ($htext, $is_regexp) = @_;
  my $scrolled = $htext->get_child1();
  return unless $scrolled;
  my $text = $scrolled->get_child();
  return unless $text;
  my $se = $htext->get_child2();
  unless( $se ) {
    $se = new Gtk2::Entry;
    $htext->pack2($se, 0, 0);
    my $completion = Gtk2::EntryCompletion->new;
    my $model = Gtk2::ListStore->new("Glib::String");
    $completion->set_model($model);
    $completion->set_text_column(0);
    $se->set_completion($completion);
    $se->signal_connect(focus_out_event => \&entry_abort);
    $se->signal_connect(activate        => \&entry_search, [$htext, $is_regexp]);
  }
  @$se{qw(HTEXT IS_REG)} = ($htext, $is_regexp); 
  $se->grab_focus();
  $se->show();
}

#--------------------------------------------------------------------
sub entry_abort {
  my ($se, $ev_data, $ud) = @_;
  entry_process($se, 0);
  return 0;
}

#--------------------------------------------------------------------
sub entry_search {
  my ($se, $ud) = @_;
  entry_process($se, 1);
}

#--------------------------------------------------------------------
sub model_contains
{
  my ($model, $pat) = @_;
  my ($cnt, $i, $last);
  for( $cnt=0, $i = $model->get_iter_first(); $i; $i = $model->iter_next($i)) {
    my ($text) = $model->get($i, 0);
    return 1 if uc($pat) eq uc($text);
    ++$cnt;
    $last = $i;
  }
  $model->remove($last) if $cnt >= 100;
  return 0;
}

#--------------------------------------------------------------------
sub entry_process {
  my ($se, $do_search) = @_;
  my ($htext, $is_regexp) = @$se{qw(HTEXT IS_REG)};
  my $scrolled = $htext->get_child1();
  return unless $scrolled;
  my $text = $scrolled->get_child();
  return unless $text;
  if( $do_search ) {
    my $buffer = $text->get_buffer();
    my $htdata = $text->{CBDATA};
    return unless $htdata;
    my $sdata = $htdata->{SRCHDATA};
    my $stags = $sdata->{TAGS};
    if( $stags ) {
      # remove prev search tags
      for my $e (@$stags) {
        $buffer->remove_tag(@$e);
      }
    }
    $stags = [];
    my $pat = $se->get_text();
    if( $pat ) {
      $text->get_window('text')->set_cursor(Gtk2::Gdk::Cursor->new('watch'));
      return if CORBA::MICO::Misc::process_pending();
      my $itext = $buffer->get_text($buffer->get_bounds(), 1);
      my @sres;
      if( $is_regexp ) {
        eval { @sres = split(/((?mi)$pat)/, $itext) };
      }
      else {
        eval { @sres = split(/((?i)\Q$pat\E)/, $itext) };
      }
      $text->get_window('text')->set_cursor(Gtk2::Gdk::Cursor->new('xterm'));
      return if CORBA::MICO::Misc::process_pending();
      if( @sres ) {
        # found
        my $eiter;
        my $rect = $text->get_visible_rect();
        if( defined($sdata->{PREV}) && $sdata->{PREV} eq $pat ) {
          $eiter = $text->get_iter_at_location($rect->x+$rect->width,
                                               $rect->y+$rect->height);
        }
        else {
          $eiter = $text->get_iter_at_location($rect->x, $rect->y);
        }
        my $ppos = $eiter->get_offset();
        my $goto_pos;
        for( my ($i, $off) = (0, 0); $i < $#sres; ++$i ) {
          my $sz = length($sres[$i]);
          if( $i % 2 ) {
            # highlight
            my $i1 = $buffer->get_iter_at_offset($off);
            my $i2 = $buffer->get_iter_at_offset($off + $sz);
            my $tag = $buffer->create_tag(undef, background=>'gray');
            push(@$stags, [$tag, $i1, $i2]);
            $buffer->apply_tag($tag, $i1, $i2);
            if( !defined($goto_pos) && $off >= $ppos ) {
              $goto_pos = $off;
            }
          }
          $off += $sz;
        }
        $goto_pos = length($sres[0]) if( !defined $goto_pos && $#sres > 0 );
        if( defined($goto_pos) ) {
          my $i1 = $buffer->get_iter_at_offset($goto_pos);
          $text->scroll_to_iter($i1, 0, 1, 0.5, 0);
        }
      }
    }
    $sdata->{PREV} = $pat;
    $sdata->{TAGS} = $stags;
    my $completion = $se->get_completion();
    my $model = $completion->get_model();
    $model->set($model->prepend, 0, $pat) unless model_contains($model, $pat);
  }
  $se->hide();
  $text->grab_focus();
}

#--------------------------------------------------------------------
# 'backspace' signal: go to previous page
sub event_backspace {
  my ($w) = @_;
  my $cbdata = $w->{CBDATA};
  if( $cbdata->{PARENTS} ) {
    my @parents = @{$cbdata->{PARENTS}};
    my $pname = shift @parents;
    return unless $pname;
    hypertext_show($cbdata->{WPARENT},
                   $pname, @$cbdata{qw(CALLBACK UDATA PREPOST)}, [@parents]);
  }
}

#--------------------------------------------------------------------
# Look for hyperlink via iterator
# return hyperlink name (undef - no hyperlink)
sub get_hlink {
  my $iter = shift;
  my $node;
  foreach my $tag ($iter->get_tags()) {
      $node = $tag->{_NODE_};
      return $node if $node;
  }
  return undef;
}

#--------------------------------------------------------------------
# 'event_after': follow link if mouse released over it: 
#    in 'detailed' window (if given) if button 1 has been pressed
#    in separated dialog window if button 2 has been pressed
#    $udata must contain a reference to 2 elements array:(id_node,detailed win)
sub event_after {
  my ($w, $ev_data) = @_;

  my $cbdata = $w->{CBDATA};
  return set_curs($w, $cbdata) if $ev_data->type eq 'scroll' ||
                                  $ev_data->type eq 'visibility-notify' ||
                                  $ev_data->type eq 'motion-notify'; 
  #if( $ev_data->type eq 'focus-change' ) {
  #  print "focus-change: ", $ev_data->in(), "\n";
  #}
  return 0 unless $ev_data->type eq 'button-release'; 
#  return 0 if $ev_data->button() != 1;  # (!!!)do not create separate dialog

  my $buffer = $w->get_buffer;
  my ($x, $y) = $w->window_to_buffer_coords('widget', $ev_data->x, $ev_data->y);
  my $iter = $w->get_iter_at_location ($x, $y);

  my $node = get_hlink($iter);
  return 0 unless $node;
  if( $ev_data->button() == 1 ) {
    hypertext_show($cbdata->{WPARENT}, $node,
                                @$cbdata{qw(CALLBACK UDATA PREPOST)},
                                [$cbdata->{NAME}, @{$cbdata->{PARENTS}}]);
  }
  elsif( $ev_data->button() == 2 ) {
    # create a dialog window and show item there
    my $ht = hypertext_create();
    my $dialog = new Gtk2::Window('toplevel');
    $dialog->set_title($node);
    $dialog->add($ht);
    $dialog->show_all();
    $dialog->realize();
    return 1 if CORBA::MICO::Misc::process_pending();
    hypertext_show($ht, $node,  @$cbdata{qw(CALLBACK UDATA PREPOST)}, undef);
  }
  return 0;
}

#--------------------------------------------------------------------
# Motion notify: set appropriate cursor type
sub set_curs {
  my ($w, $cbdata) = @_;

  my (undef, $x, $y, undef) = $w->window->get_pointer();
  ($x, $y) = $w->window_to_buffer_coords('widget', $x, $y);
  my $iter = $w->get_iter_at_location ($x, $y);
  return 0 unless $iter;
  my $curshand = defined(get_hlink($iter));
  if( !defined($cbdata->{CURS_HAND}) || $curshand != $cbdata->{CURS_HAND} ) {
      $w->get_window('text')->set_cursor
      		(Gtk2::Gdk::Cursor->new($curshand ? 'hand2' : 'xterm'));
    $cbdata->{CURS_HAND} =  $curshand;
  }
  return 0;
}
