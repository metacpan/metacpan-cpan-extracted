package CORBA::MICO::Misc;
require Exporter;

require Gtk2;

use strict;

@CORBA::MICO::Misc::ISA = qw(Exporter);
@CORBA::MICO::Misc::EXPORT = qw();
@CORBA::MICO::Misc::EXPORT_OK = qw(
        process_pending 
        cursor_clock
        cursor_hand2
        cursor_restore_to_default
        warning
        select_file
        status_line_create
        status_line_write
        ctree_pixmaps
);

use vars qw($ctree_pixmaps);

#--------------------------------------------------------------------
# Force updating of screen (process pending events)
# Return value: TRUE if main_quit has been called, FALSE else
sub process_pending {
  my $ret = Gtk2->main_iteration() while Gtk2->events_pending();
  return $ret;
}

#--------------------------------------------------------------------
# Set cursor: watch
# In: widget     - widget-owner of window cursor will be set to
#     do_repaint - repaint immediately if TRUE 
# Return value: TRUE if main_quit has been called, FALSE else
#--------------------------------------------------------------------
sub cursor_watch {
  # return cursor_set(Gtk2::Gdk::GDK_WATCH, @_);
  return cursor_set(Gtk2::Gdk::Cursor->new('watch'), @_);
}

#--------------------------------------------------------------------
# Set cursor: hand2
# In: widget     - widget-owner of window cursor will be set to
#     do_repaint - repaint immediately if TRUE 
# Return value: TRUE if main_quit has been called, FALSE else
#--------------------------------------------------------------------
sub cursor_hand2 {
  # return cursor_set(Gtk2::Gdk::GDK_HAND2, @_);
  return cursor_set(Gtk2::Gdk::Cursor->new('hand2'), @_);
}

#--------------------------------------------------------------------
# Restore cursor to its default value
# In: widget     - widget-owner of window cursor will be set to
#     do_repaint - repaint immediately if TRUE 
# Return value: TRUE if main_quit has been called, FALSE else
#--------------------------------------------------------------------
sub cursor_restore_to_default {
  return cursor_set(undef, @_);
}

#--------------------------------------------------------------------
# Set cursor
# In: cursor, widget, do_repaint
# Return value: TRUE if main_quit has been called, FALSE else
#--------------------------------------------------------------------
sub cursor_set {
  my ($cursor, $widget, $do_repaint) = @_;
  my $ret = 0;
  my $window = $widget->window();
  if( defined($window) ) {
    $window->set_cursor($cursor);
    if( $do_repaint ) {
      $ret = process_pending();
    }
  }
  return $ret;
}
        
#--------------------------------------------------------------------
# Ask file name via file selection dialog
# In: $title        - title
#     $default_name - default file name
#     $show_fileop  - show file operation buttons if TRUE
#     $callback     - 'file selected' callback
#                      with arguments: ($file_name, @udata) 
#                      Return value: 1 - close file dialog
#                                    0 - continue
#     @udata        - callback data
#--------------------------------------------------------------------
sub select_file {
  my ($title, $def_name, $show_fileop, $callback, @udata) = @_;
  my $dialog = new Gtk2::FileSelection($title);
  $dialog->ok_button->signal_connect(
                          'clicked', 
                          sub { 
                            if( &$callback($dialog->get_filename(), @udata) ) {
                              $dialog->destroy();
                            }
                          });
  $dialog->cancel_button->signal_connect('clicked', sub { $dialog->destroy() });
  $dialog->set_position('mouse');
  $dialog->set_filename($def_name) if $def_name;
  $dialog->hide_fileop_buttons()   unless $show_fileop;
  $dialog->show_all();
  Gtk2->grab_remove($dialog);
}

#--------------------------------------------------------------------
# Show warning message
#--------------------------------------------------------------------
sub warning {
  my ($text) = @_;
  my $dialog = new Gtk2::Dialog;
  $dialog->set_position('mouse');
  my $label = new Gtk2::Label($text);
  $label->set_padding(10, 10);
  $dialog->vbox()->pack_start($label, 1, 1, 0);

  my $bbox = new Gtk2::HButtonBox;
  $bbox->set_spacing(5);
  $bbox->set_layout('end');
  $dialog->action_area()->pack_start($bbox, 1, 1, 0);

  my $ok_button = new_with_label Gtk2::Button("OK");
  $ok_button->signal_connect('clicked', sub { $dialog->destroy() });
  $ok_button->can_default(1);
  $bbox->pack_end($ok_button, 0, 0, 0);
  $ok_button->grab_default();
     
  $dialog->grab_add();
  $dialog->signal_connect('destroy', sub { Gtk2->grab_remove($dialog) });
  $dialog->show_all();
}

#--------------------------------------------------------------------
# Create status line, return corresponding Gtk2::Label widget
#--------------------------------------------------------------------
sub status_line_create {
  my $widget;
  if(0) {
    $widget = new Gtk2::Label('');
    $widget->set_justify('left');
  }
  else {
    $widget = new Gtk2::Entry();
    $widget->set_editable(0);
  }
  return $widget;
}

#--------------------------------------------------------------------
# Write a message to status line
# In: $widget  - status line widget
#     $text    - message to be shown
#--------------------------------------------------------------------
sub status_line_write {
  my ($widget, $text) = @_;
#  print $text, "\n";
  $widget->set_text($text);
  process_pending();
}

#--------------------------------------------------------------------
# search handler for TreeView
# (look for substring at any positioin within the column)
#--------------------------------------------------------------------
sub ctree_std_search {
  my ($model, $column, $key, $iter, $ud) = @_;
  my ($text) = $model->get($iter, $column);
  my $rv = 1;
  # use eval so as illegal regexp may an cause exception
  if( $ud->{REGEXP} ) {
    eval { $rv = $text !~ /$key/i };
  }
  else {
    eval { $rv = $text !~ /\Q$key\E/i };
  }
  return $rv;
}

#--------------------------------------------------------------------
# Emit signal start_interactive_search when CTRL_F is pressed
#--------------------------------------------------------------------
sub ctree_kpress {
  my ($w, $event, $ud) = @_;
  my $key = Gtk2::Gdk->keyval_name($event->keyval());
  if( $key eq 'f' ) {
    $ud->{REGEXP} = 0;
  }
  elsif( $key eq 'r' ) {
    $ud->{REGEXP} = 1;
  }
  else {
    return 0;
  }
  my $st = $event->state();
  if( $#$st == 0 && $st->[0] eq 'control-mask' ) {
    $w->signal_emit('start_interactive_search');
    return 1;
  }
  return 0;
}

