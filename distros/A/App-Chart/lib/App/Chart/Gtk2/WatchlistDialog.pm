# Copyright 2007, 2008, 2009, 2010, 2011, 2013, 2014 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::WatchlistDialog;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2 1.220;
use Locale::TextDomain 1.17; # for __p()
use Locale::TextDomain ('App-Chart');

use Glib::Ex::ConnectProperties;
use Gtk2::Ex::EntryBits;
use Gtk2::Ex::TreeViewBits;
use Gtk2::Ex::Units;
use Gtk2::Ex::WidgetCursor;

use App::Chart::Gtk2::Ex::CellRendererTextBits;
use App::Chart::Gtk2::Ex::NotebookLazyPages;
use App::Chart::Gtk2::Ex::ToplevelBits;
use App::Chart::Gtk2::Symlist;

# uncomment this to run the ### lines
#use Devel::Comments;

BEGIN {
  Gtk2->CHECK_VERSION(2,12,0)
    or die "Need Gtk 2.12 or higher";  # for ->error_bell
}

use constant DEFAULT_SYMLIST_KEY => 'favourites';

# use App::Chart::Gtk2::Ex::ToplevelSingleton hide_on_delete => 1;
# use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';
# sub popup {
#   my ($class, $parent) = @_;
#   my $self = $class->instance_for_screen ($parent);
#   $self->present;
#   return $self;
# }

use Glib::Object::Subclass
  'Gtk2::Dialog',
  properties => [ Glib::ParamSpec->object
                  ('symlist',
                   'symlist',
                   'The symlist to display.',
                   # App::Chart::Gtk2::Symlist::Join isn't a glib derivative
                   'Glib::Object', # 'App::Chart::Gtk2::Symlist',
                   Glib::G_PARAM_READWRITE),
                ];


use constant { NOTEBOOK_PAGENUM_SYMBOLS => 0,
               NOTEBOOK_PAGENUM_SYMLISTS => 1 };

use constant { RESPONSE_REFRESH   => 0,
               RESPONSE_DELETE    => 1,
               RESPONSE_INTRADAY  => 2,
               RESPONSE_EDIT_NAME => 3,
             };

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set_title (__('Chart: Watchlist'));
  $self->signal_connect (response => \&_do_response);

  my $vbox = $self->vbox;
  my $action_area = $self->action_area;
  my $em = Gtk2::Ex::Units::em($self);

  my $symlist = $self->{'symlist'}
    = App::Chart::Gtk2::Symlist->new_from_key (DEFAULT_SYMLIST_KEY);

  my $notebook = $self->{'notebook'} = Gtk2::Notebook->new;
  $notebook->set (tab_hborder => 0.5 * $em);
  $vbox->pack_start ($notebook, 1,1,0);

  #   require App::Chart::Gtk2::SymlistComboBox;
  #   my $combobox = App::Chart::Gtk2::SymlistComboBox->new;
  #   Glib::Ex::ConnectProperties->new ([$self,    'symlist'],
  #                                     [$combobox,'symlist']);
  #   $combobox->signal_connect (changed => \&_do_combobox_changed);
  #   $action_area->add ($combobox);

  $self->add_buttons ('gtk-refresh'   => RESPONSE_REFRESH,
                      'gtk-delete'    => RESPONSE_DELETE);
  {
    my $intraday_button = $self->{'intraday_button'}
      = Gtk2::Button->new_with_mnemonic (__('_Intraday'));
    $self->add_action_widget ($intraday_button, RESPONSE_INTRADAY);
  }
  {
    my $edit_button = $self->{'edit_button'}
      = Gtk2::Button->new_with_mnemonic (__('_Edit Name'));
    $self->add_action_widget ($edit_button, RESPONSE_EDIT_NAME);
  }
  $self->add_buttons ('gtk-close'     => 'close',
                      'gtk-help'      => 'help');



  require App::Chart::Gtk2::WatchlistModel;
  my $model = App::Chart::Gtk2::WatchlistModel->new ($symlist);

  my $symbols_vbox = Gtk2::VBox->new;
  my $symbols_tab_eventbox = $self->{'symbols_tab_eventbox'}
    = Gtk2::EventBox->new;
  $symbols_tab_eventbox->signal_connect
    (button_press_event => \&_do_symbols_tab_button_press);
  my $symbols_tab_label = $self->{'symbols_tab_label'} = Gtk2::Label->new;
  $symbols_tab_label->show;
  $symbols_tab_eventbox->add ($symbols_tab_label);
  $notebook->append_page ($symbols_vbox, $symbols_tab_eventbox);

  my $symlists_vbox = $self->{'symlists_vbox'} = Gtk2::VBox->new;
  $notebook->append_page ($symlists_vbox, __('Symlists'));
  App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
      ($notebook, $symlists_vbox, \&_init_symlists_page);

  $notebook->signal_connect ('notify::page' => \&_do_notebook_notify_page);

  my $scrolled = $self->{'symbols_scrolled'} = Gtk2::ScrolledWindow->new;
  $scrolled->set(hscrollbar_policy => 'never');
  $symbols_vbox->pack_start ($scrolled, 1,1,0);

  my $treeview = $self->{'symbols_treeview'}
    = Gtk2::TreeView->new_with_model ($model);
  $treeview->set (fixed_height_mode => 1,
                  reorderable => $symlist && $symlist->can_edit);

  $scrolled->add ($treeview);
  $treeview->signal_connect (query_tooltip => \&_do_query_tooltip);
  $treeview->set (has_tooltip => 1);

  my $selection = $treeview->get_selection;
  $selection->signal_connect (changed => \&_do_symbol_selection_changed);
  $selection->set_mode ('single');

  my $renderer_left = Gtk2::CellRendererText->new;
  $renderer_left->set (xalign => 0,
                       ypad => 0);
  $renderer_left->set_fixed_height_from_font (1);
  my $renderer_right = Gtk2::CellRendererText->new;
  $renderer_right->set (xalign => 1,
                        ypad => 0);
  $renderer_right->set_fixed_height_from_font (1);

  {
    my $renderer = $self->{'symbol_renderer'} = Gtk2::CellRendererText->new;
    $renderer->set (xalign => 0, ypad => 0);
    $renderer->set_fixed_height_from_font (1);

    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Symbol'), $renderer,
       text => $model->COL_SYMBOL,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 8*$em,
                  resizable => 1);
    App::Chart::Gtk2::Ex::CellRendererTextBits::renderer_edited_set_value
        ($renderer, $column, 0);
    $renderer->signal_connect (edited => \&_do_symbol_renderer_edited);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Bid/Offer'), $renderer_right,
       text => $model->COL_BIDOFFER,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 12*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Last'), $renderer_right,
       text => $model->COL_LAST,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 7*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Change'), $renderer_right,
       text => $model->COL_CHANGE,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 7*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('High'), $renderer_right,
       text => $model->COL_HIGH,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 7*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Low'), $renderer_right,
       text => $model->COL_LOW,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 7*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Volume'), $renderer_right,
       text => $model->COL_VOLUME,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 6*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('When'), $renderer_right,
       text => $model->COL_WHEN,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 6*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Notes'), $renderer_left,
       text => $model->COL_NOTE,
       foreground => $model->COL_COLOUR);
    $column->set (sizing => 'fixed',
                  fixed_width => 8*$em,
                  resizable => 1);
    $treeview->append_column ($column);
  }
  $treeview->add_events ('button-press-mask');
  $treeview->signal_connect (button_press_event => \&_do_symbol_menu_popup);
  $treeview->signal_connect (row_activated => \&_do_symbol_treeview_activate);

  my $hbox = Gtk2::HBox->new;
  $symbols_vbox->pack_start ($hbox, 0,0,0);

  my $entry_label = Gtk2::Label->new (__('New Symbol'));
  $hbox->pack_start ($entry_label, 0,0,0);

  my $entry = $self->{'symbol_entry'} = Gtk2::Entry->new;
  $hbox->pack_start ($entry, 1,1,0);
  $entry->signal_connect (activate => \&_do_symbol_entry_activate);

  { my $button = Gtk2::Button->new_with_label (__('Insert'));
    $hbox->pack_start ($button, 0,0,0);
    $button->signal_connect (clicked => \&_do_symbol_entry_activate);
  }

  _update_delete_sensitive ($self);
  _update_intraday_sensitive ($self);
  _update_edit_sensitive ($self);

  $vbox->show_all;
  _do_notebook_notify_page ($notebook); # initial hides

  # with a sensible rows size for the TreeView
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self, [$scrolled, -1, '20 lines']);

  $self->{'symlist'} = undef; # fake to force update
  $self->set_symlist ($symlist);
}

# # 'notify:symlist' on the App::Chart::Gtk2::SymlistComboBox
# # switch page to the symbol list display when a symlist is selected
# sub _do_combobox_changed {
#   my ($combobox) = @_;
#   if (DEBUG) {
#     say "Watchlist symlist combobox changed, switch notebook to symbols";
#   }
#   my $self = $combobox->get_toplevel;
#   my $notebook = $self->{'notebook'};
#   $notebook->set_current_page(NOTEBOOK_PAGENUM_SYMBOLS);
# }

# 'edited' signal on the Gtk2::CellRendererText in the symbol column,
# initiate a download of the new symbol
sub _do_symbol_renderer_edited {
  my ($renderer, $pathstr, $newstr) = @_;
  require App::Chart::Gtk2::Job::Latest;
  App::Chart::Gtk2::Job::Latest->start ([$newstr]);
}

sub _do_notebook_notify_page {
  my ($notebook) = @_;
  my $self = $notebook->get_toplevel;
  ### Watchlist notebook switch to: $notebook->get_current_page

  my $pagenum = $notebook->get_current_page;
  $self->{'intraday_button'}->set
    (visible => ($pagenum == NOTEBOOK_PAGENUM_SYMBOLS));
  $self->{'edit_button'}->set
    (visible => ($pagenum == NOTEBOOK_PAGENUM_SYMLISTS));
  _update_delete_sensitive ($self);
}

sub _init_symlists_page {
  my ($notebook, $vbox, $pagenum) = @_;
  my $self = $notebook->get_toplevel;
  ### Watchlist _init_symlists_page()

  my $scrolled = $self->{'symlists_scrolled'} = Gtk2::ScrolledWindow->new;
  $scrolled->set (hscrollbar_policy => 'automatic');
  $vbox->pack_start ($scrolled, 1,1,0);

  require App::Chart::Gtk2::SymlistListModel;
  my $model = App::Chart::Gtk2::SymlistListModel->instance;

  my $treeview = $self->{'symlists_treeview'}
    = Gtk2::TreeView->new_with_model ($model);
  $treeview->set (fixed_height_mode => 0,
                  reorderable => 1);
  $scrolled->add ($treeview);
  $treeview->signal_connect (row_activated =>\&_do_symlists_treeview_activate);
  $treeview->add_events ('button-press-mask');
  $treeview->signal_connect (button_press_event => \&_do_symlist_menu_popup);
  # $treeview->signal_connect (query_tooltip => \&_do_query_tooltip);
  # $treeview->set (has_tooltip => 1);

  my $selection = $treeview->get_selection;
  $selection->signal_connect (changed => \&_do_symlist_selection_changed);
  $selection->set_mode ('single');

  {
    my $renderer = $self->{'symlists_name_renderer'}
      = Gtk2::CellRendererText->new;
    $renderer->set (xalign => 0,
                    ypad => 0);
    my $column = $self->{'symlists_name_treecolumn'}
      = Gtk2::TreeViewColumn->new_with_attributes
        (__('Name'), $renderer, text => $model->COL_NAME);
    App::Chart::Gtk2::Ex::CellRendererTextBits::renderer_edited_set_value
        ($renderer, $column, $model->COL_NAME);
    $treeview->append_column ($column);
  }
  {
    my $renderer = Gtk2::CellRendererText->new;
    $renderer->set (xalign => 0,
                    ypad => 0);
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Key'), $renderer, text => $model->COL_KEY);
    $treeview->append_column ($column);
  }
  #   {
  #     my $renderer = Gtk2::CellRendererText->new;
  #     $renderer->set (xalign => 0,
  #                     ypad => 0,
  #                     text => __('Edit Name'));
  #     my $column = Gtk2::TreeViewColumn->new_with_attributes
  #       ('', $renderer);
  #     $treeview->append_column ($column);
  #   }

  my $hbox = Gtk2::HBox->new;
  $vbox->pack_start ($hbox, 0,0,0);

  my $entry_label = Gtk2::Label->new (__('New List'));
  $hbox->pack_start ($entry_label, 0,0,0);

  my $entry = $self->{'symlist_entry'} = Gtk2::Entry->new;
  $hbox->pack_start ($entry, 1,1,0);
  $entry->signal_connect (activate => \&_do_symlist_entry_activate);

  { my $button = Gtk2::Button->new_with_label (__('Insert'));
    $hbox->pack_start ($button, 0,0,0);
    $button->signal_connect (clicked => \&_do_symlist_entry_activate);
  }

  $self->{'symlists_setup'} = 1;
  $vbox->show_all;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if ($pspec->get_name eq 'symlist') {
    $self->set_symlist ($newval);
  } else {
    $self->{$pname} = $newval;  # per default GET_PROPERTY
  }
}

sub get_selected_symbol {
  my ($self) = @_;
  my $treeview = $self->{'symbols_treeview'};
  my $selection = $treeview->get_selection;
  my ($model, $iter) = $selection->get_selected;
  if (! defined $iter) { return undef; }
  my ($symbol) = $model->get ($iter, 0);
  return $symbol;
}

sub set_symlist {
  my ($self, $symlist) = @_;
  ### Watchlist set_symlist()

  if (my $conn = delete $self->{'symlist_name_conn'}) {
    $conn->disconnect;
  }
  my $label = $self->{'symbols_tab_label'};
  if ($symlist) {
    $self->{'symlist_name_conn'}
      = Glib::Ex::ConnectProperties->new ([$symlist,'name'],
                                          [$label,  'label']);
  } else {
    $label->set_text (__('(No list)'));
  }

  if (($symlist||0) eq ($self->{'symlist'}||0)) {
    ### symlist unchanged
    return;
  }

  ### new symlist: "$symlist"
  Gtk2::Ex::WidgetCursor->busy;
  my $model = $symlist && App::Chart::Gtk2::WatchlistModel->new ($symlist);

  {
    my $reorderable = $symlist && $symlist->can_edit;
    my $symbols_treeview = $self->{'symbols_treeview'};
    ### $reorderable
    $symbols_treeview->set (model       => $model,
                            reorderable => $reorderable);

    # FIXME: what was this? dragging text to add a symbol? doing it turns
    # off reorderable circa gtk 2.24 -- another incompatible change probably ...
    #
    # if ($reorderable) {
    #   $symbols_treeview->enable_model_drag_dest
    #     (['move'], { target => 'text/plain',
    #                  flags => []});  # 'other-app'
    # }
  }

  $self->{'symlist'} = $symlist;

  if ($symlist) {
    if (my $treeview = $self->{'symlists_treeview'}) {
      my $model = $treeview->get_model;
      my $key = $symlist->key;
      $model->foreach
        (sub {
           my ($model, $path, $iter) = @_;
           my $this_key = $model->get_value ($iter, $model->COL_KEY);
           if ($this_key ne $key) { return 0; } # keep iterating
           my $selection = $treeview->get_selection;
           $selection->select_path ($path);
           return 1; # stop iterating
         });
    }
  }

  my $editable = $symlist && $symlist->can_edit;
  ### symbol column editable: $editable
  $self->{'symbol_renderer'}->set (editable => $editable);

  $self->notify ('symlist');
}

sub get_symlists_selected_key {
  my ($self) = @_;
  my $treeview = $self->{'symlists_treeview'} || return; # if created yet
  my $selection = $treeview->get_selection;
  my ($model, $iter) = $selection->get_selected;
  if (! defined $iter) { return; }
  my ($symbol) = $model->get ($iter, $model->COL_KEY);
  return $symbol;
}

sub _update_delete_sensitive {
  my ($self) = @_;
  ### Watchlist _update_delete_sensitive()
  $self->set_response_sensitive (RESPONSE_DELETE,
                                 _want_delete_sensitive($self));
}
sub _want_delete_sensitive {
  my ($self) = @_;
  my $notebook = $self->{'notebook'};
  my $pagenum = $notebook->get_current_page;
  ### $pagenum

  if ($pagenum == NOTEBOOK_PAGENUM_SYMLISTS) {
    my $key = $self->get_symlists_selected_key;
    if (! defined $key) {
      ### no selected symlist
      return 0;
    }
    my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
    if (! $symlist) {
      ### no such symlist: $key
      return 0;
    }
    ### can_delete_symlist() on: $key
    return $symlist->can_delete_symlist;

  } else {
    my $treeview = $self->{'symbols_treeview'};
    my $selection = $treeview->get_selection;
    my ($model, $iter) = $selection->get_selected;
    if (! $iter) {
      ### no selected symbol
      return 0;
    }
    my $symlist = $model->get_model;
    return $symlist->can_edit;
  }
}

sub _update_intraday_sensitive {
  my ($self) = @_;
  ### Watchlist _update_intraday_sensitive()
  my $symbol = $self->get_selected_symbol;
  ### $symbol
  $self->set_response_sensitive (RESPONSE_INTRADAY,
                                 symbol_intraday_sensitive($symbol));
}
sub symbol_intraday_sensitive {
  my ($symbol) = @_;
  if (! $symbol) { return 0; }
  require App::Chart::IntradayHandler;
  return scalar (App::Chart::IntradayHandler->handlers_for_symbol ($symbol));
}

sub _update_edit_sensitive {
  my ($self) = @_;
  $self->set_response_sensitive (RESPONSE_EDIT_NAME,
                                 defined $self->get_symlists_selected_key);
}

sub _do_symbols_tab_button_press {
  my ($symbols_tab_eventbox, $event) = @_;
  my $self = $symbols_tab_eventbox->get_toplevel;

  if ($event->button == 3) {
    require App::Chart::Gtk2::SymlistRadioMenu;
    my $symlist_menu = App::Chart::Gtk2::SymlistRadioMenu->new;
    ### menu destroy connection: $symlist_menu->signal_connect (destroy => sub { print "Watchlist symlist menu destroyed\n" })
    Glib::Ex::ConnectProperties->new ([$self, 'symlist'],
                                      [$symlist_menu, 'symlist']);
    $symlist_menu->set_screen ($self->get_screen);
    $symlist_menu->popup (undef,  # parent menushell
                          undef,  # parent menuitem
                          undef,  # position func
                          undef,  # position userdata
                          $_,     # button
                          $event->time);
    return Gtk2::EVENT_PROPAGATE;
  }

  # GtkNotebook button press handler can cope with an event from a child
  # widget
  return $self->{'notebook'}->signal_emit ('button_press_event', $event);
}

sub _do_symbol_treeview_activate {
  my ($treeview, $path, $column) = @_;
  my $self = $treeview->get_toplevel;
  my $symlist = $self->{'symlist'};
  my $iter = $symlist->get_iter ($path);
  my $symbol = $symlist->get_value ($iter, 0);

  require App::Chart::Gtk2::Main;
  my $main = App::Chart::Gtk2::Main->find_for_dialog ($self);
  $main->goto_symbol ($symbol, $symlist);
  $main->present;
}

sub _do_symlists_treeview_activate {
  my ($treeview, $path, $column) = @_;
  my $model = $treeview->get_model;
  my $iter = $model->get_iter ($path);
  my $key = $model->get_value ($iter, $model->COL_KEY);
  my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key);
  my $self = $treeview->get_toplevel;
  $self->set_symlist ($symlist);
  $self->{'notebook'}->set_current_page (0);
}

sub _do_symbol_selection_changed {
  my ($selection) = @_;
  my $self = $selection->get_tree_view->get_toplevel;
  _update_intraday_sensitive ($self);
  _update_delete_sensitive ($self);
}
sub _do_symlist_selection_changed {
  my ($selection) = @_;
  my $self = $selection->get_tree_view->get_toplevel;
  _update_delete_sensitive ($self);
  _update_edit_sensitive ($self);
}

# 'response' signal handler
sub _do_response {
  my ($self, $response) = @_;
  ### Watchlist _do_response(): $response

  if ($response eq RESPONSE_REFRESH) {
    $self->refresh;

  } elsif ($response eq RESPONSE_DELETE) {
    my $notebook = $self->{'notebook'};
    my $pagenum = $notebook->get_current_page;
    my $treeview;
    if ($pagenum == NOTEBOOK_PAGENUM_SYMLISTS) {
      $treeview = $self->{'symlists_treeview'};
      # supposed to be insensitive when no selection, but check anyway
      my $key = $self->get_symlists_selected_key || return;

      # ignore somehow unknown key
      my $symlist = App::Chart::Gtk2::Symlist->new_from_key ($key) || return;

      if (! $symlist->is_empty) {
        # dialog if symlist not empty
        require App::Chart::Gtk2::DeleteSymlistDialog;
        App::Chart::Gtk2::DeleteSymlistDialog->popup ($symlist, $self);
        return;
      }
    } else {
      $treeview = $self->{'symbols_treeview'};
    }
    require Gtk2::Ex::TreeViewBits;
    Gtk2::Ex::TreeViewBits::remove_selected_rows ($treeview);

  } elsif ($response eq RESPONSE_INTRADAY) {
    # supposed to be insensitive when no selected symbol, but check anyway
    my $symbol = $self->get_selected_symbol // return;
    App::Chart::Gtk2::Ex::ToplevelBits::popup
        ('App::Chart::Gtk2::IntradayDialog',
         properties => { symbol => $symbol },
         screen => $self);

  } elsif ($response eq RESPONSE_EDIT_NAME) {
    my $notebook = $self->{'notebook'};
    my $pagenum = $notebook->get_current_page;
    # supposed to be visible only when symlists showing, but check anyway
    ($pagenum == NOTEBOOK_PAGENUM_SYMLISTS) or return;

    my $treeview = $self->{'symlists_treeview'};
    my $selection = $treeview->get_selection;
    my ($symlists_model, $iter) = $selection->get_selected;
    # supposed to be insensitive if no selection, but check anyway
    if (! defined $iter) { return; }

    my $path = $symlists_model->get_path($iter);
    ### set_cursor to path: $path->to_string
    $treeview->grab_focus;
    my $renderer = $self->{'symlists_name_renderer'};
    $renderer->set (editable => 1);
    $treeview->set_cursor ($path, $self->{'symlists_name_treecolumn'}, 1);
    $renderer->set (editable => 0);

  } elsif ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');

  } elsif ($response eq 'help') {
    require App::Chart::Manual;
    App::Chart::Manual->open(__p('manual-node','Watchlist'), $self);
  }
}

sub refresh {
  my ($self) = @_;
  Gtk2::Ex::WidgetCursor->busy;
  if (my $symlist = $self->{'symlist'}) {
    require App::Chart::Gtk2::Job::Latest;
    App::Chart::Gtk2::Job::Latest->start_symlist ($symlist);
  }
}

sub _do_symbol_menu_popup {
  my ($treeview, $event) = @_;
  if ($event->button == 3) {
    require App::Chart::Gtk2::WatchlistSymbolMenu;
    App::Chart::Gtk2::WatchlistSymbolMenu->popup_from_treeview ($event, $treeview);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub _do_symlist_menu_popup {
  # nothing yet ...
  #   my ($treeview, $event) = @_;
  #   my $self = $treeview->get_toplevel;
  return Gtk2::EVENT_PROPAGATE;
}

# 'query-tooltip' signal on symbols_treeview
sub _do_query_tooltip {
  my ($treeview, $x, $y, $keyboard_tip, $tooltip) = @_;
  # ### Watchlist _do_query_tooltip() "$x,$y"

  my ($bin_x, $bin_y, $model, $path, $iter)
    = $treeview->get_tooltip_context ($x, $y, $keyboard_tip);
  if (! defined $path) { return 0; }

  my $symbol = $model->get_value($iter, $model->COL_SYMBOL);
  if (! defined $symbol) { return 0; }
  require App::Chart::Latest;
  my $latest = App::Chart::Latest->get ($symbol);

  require App::Chart::Database;
  my $tip = $symbol;
  if (my $name = ($latest->{'name'}
                  || App::Chart::Database->symbol_name ($symbol))) {
    $tip .= ' - ' . $name;
  }
  $tip .= "\n";

  if (my $quote_date = $latest->{'quote_date'}) {
    my $quote_time = $latest->{'quote_time'} || '';
    $tip .= __x("Quote: {quote_date} {quote_time}",
                quote_date => $quote_date,
                quote_time => $quote_time);
    $tip .= "\n";
  }

  if (my $last_date = $latest->{'last_date'}) {
    my $last_time = $latest->{'last_time'} || '';
    $tip .= __x("Last:  {last_date} {last_time}",
                last_date => $last_date,
                last_time => $last_time);
    $tip .= "\n";
  }

  $tip .= __x('{location} time; source {source}',
              location => App::Chart::TZ->for_symbol($symbol)->name,
              source => $latest->{'source'});

  ### $tip
  $tooltip->set_text ($tip);
  $treeview->set_tooltip_row ($tooltip, $path);
  return 1;
}

sub _do_symlist_entry_activate {
  my ($entry_or_button) = @_;
  my $self = $entry_or_button->get_toplevel;
  my $treeview = $self->{'symlists_treeview'};
  my $pos = treeview_pos_after_selected_or_top_of_visible ($treeview);

  my $entry = $self->{'symlist_entry'};
  my $name = $entry->get_text;
  require App::Chart::Gtk2::Symlist::User;
  App::Chart::Gtk2::Symlist::User->add_symlist ($pos, $name);

  my $path = Gtk2::TreePath->new_from_indices ($pos);
  Gtk2::Ex::TreeViewBits::scroll_cursor_to_path ($treeview, $path);
}

# 'activate' signal handler on the Gtk2::Entry for a symbol 
sub _do_symbol_entry_activate {
  my ($entry_or_button) = @_;
  my $self = $entry_or_button->get_toplevel;
  my $treeview = $self->{'symbols_treeview'};
  my $pos = treeview_pos_after_selected_or_top_of_visible ($treeview);

  my $entry = $self->{'symbol_entry'};
  my $symlist = $self->{'symlist'};
  if (! $symlist->can_edit) {  # supposed to be insensitive anyway
    $entry->error_bell;
    return;
  }

  # select text for ease of typing another
  Gtk2::Ex::EntryBits::select_region_noclip ($entry, 0, -1);

  my $symbol = $entry->get_text;
  if (my $path = $symlist->find_symbol_path ($symbol)) {
    # already exists, move to it
    Gtk2::Ex::TreeViewBits::scroll_cursor_to_path ($treeview, $path);
    return;
  }
  $symlist->insert_with_values ($pos, 0=>$symbol);

  my $path = Gtk2::TreePath->new_from_indices ($pos);
  Gtk2::Ex::TreeViewBits::scroll_cursor_to_path ($treeview, $path);

  # request this, everything else as extras
  if ($symbol ne '') {
    require App::Chart::Gtk2::Job::Latest;
    App::Chart::Gtk2::Job::Latest->start ([$symbol]);
  }
}

#------------------------------------------------------------------------------
# generic helpers

sub treeview_pos_after_selected_or_top_of_visible {
  my ($treeview) = @_;

  my ($lo_path, $hi_path) = $treeview->get_visible_range;
  my ($lo) = $lo_path ? $lo_path->get_indices : (-1);
  my ($hi) = $hi_path ? $hi_path->get_indices : (-1);
  my $pos = $lo + 1;

  my $selection = $treeview->get_selection;
  my ($sel_path) = $selection->get_selected_rows;
  if ($sel_path) {
    my ($sel) = $sel_path->get_indices;
    if ($sel >= $lo && $sel <= $hi) {
      $pos = $sel + 1;
    }
  }
  return $pos;
}

#------------------------------------------------------------------------------

sub main {
  my ($class, $args) = @_;

  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  Gtk2->init;

  require Gtk2::Ex::ErrorTextDialog::Handler;
  Glib->install_exception_handler
    (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);
  ## no critic (RequireLocalizedPunctuationVars)
  $SIG{'__WARN__'} = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;
  ## use critic

  require App::Chart::Gtk2::TickerMain;
  my $symlist = App::Chart::Gtk2::TickerMain::args_to_symlist ($args);

  my $self = $class->new;
  $self->set (symlist => $symlist);
  $self->signal_connect (destroy =>
                         \&App::Chart::Gtk2::TickerMain::_do_destroy_main_quit);
  $self->show_all;
  Gtk2->main;
}

1;
__END__

=for stopwords watchlist Watchlist Popup

=head1 NAME

App::Chart::Gtk2::WatchlistDialog -- watchlist dialog module

=head1 SYNOPSIS

 use App::Chart::Gtk2::WatchlistDialog;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::WatchlistDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::WatchlistDialog

=head1 DESCRIPTION

A C<App::Chart::Gtk2::WatchlistDialog> widget is a watchlist display and dialog.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::WatchlistDialog->new (key=>value,...) >>

Create and return a new Watchlist dialog widget.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::WatchlistSymbolMenu>

=cut

#  App::Chart::Gtk2::WatchlistDialog->popup();
# =item C<< App::Chart::Gtk2::WatchlistDialog->popup () >>
# 
# =item C<< App::Chart::Gtk2::WatchlistDialog->popup ($parent) >>
# 
# Popup a C<Watchlist> dialog.  This function creates a C<Watchlist> widget
# the first time it's called, and then on subsequent calls just presents that
# single dialog.
# 
# If C<$parent> is supplied then a Watchlist on that display is sought, and if
# one is created then it's on the same screen as C<$parent>.

