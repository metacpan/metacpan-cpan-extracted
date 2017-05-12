# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::OpenDialog;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use Gtk2::Ex::EntryBits;
use Gtk2::Ex::TreeViewBits;
use Gtk2::Ex::Units;
use App::Chart;
use App::Chart::Database;
use App::Chart::Gtk2::GUI;

Gtk2->CHECK_VERSION(2,12,0)
  or die "Need Gtk 2.12 or higher";  # for ->error_bell

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Dialog',
  signals => { map => \&_do_map };

# use App::Chart::Gtk2::Ex::ToplevelSingleton hide_on_delete => 1;
# use base 'App::Chart::Gtk2::Ex::ToplevelSingleton';
# sub popup {
#   my ($class) = @_;
#   my $self = $class->instance;
#   $self->present;
#   return $self;
# }

use constant { RESPONSE_OPEN  => 0,
               RESPONSE_NEW   => 1 };

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_title (__('Chart: Open'));
  $self->add_buttons ('gtk-open'   => RESPONSE_OPEN,
                      'gtk-new'    => RESPONSE_NEW,
                      'gtk-cancel' => 'cancel',
                      'gtk-help'   => 'help');
  $self->signal_connect (response => \&_do_response);

  my $vbox = $self->vbox;

  my $scrolled = Gtk2::ScrolledWindow->new;
  $scrolled->set(hscrollbar_policy => 'automatic');
  $vbox->pack_start ($scrolled, 1,1,0);

  require App::Chart::Gtk2::OpenModel;
  my $model = $self->{'model'} = App::Chart::Gtk2::OpenModel->instance;
  #   require App::Chart::Gtk2::SymlistTreeModel;
  #   my $model = $self->{'model'} = App::Chart::Gtk2::SymlistTreeModel->instance;

  my $treeview = $self->{'treeview'} = Gtk2::TreeView->new_with_model ($model);
  $treeview->set (reorderable       => 1,
                  headers_visible   => 0,
                  fixed_height_mode => 1,
                  search_column     => $model->COL_ITEM_SYMBOL);
  $treeview->signal_connect (row_activated => \&_do_row_activated);
  $scrolled->add ($treeview);

  foreach my $key ('all', 'favourites') {
    if (my $path = $model->path_for_key ($key)) {
      $treeview->expand_row($path, 0);
    }
  }

  my $selection = $treeview->get_selection();
  $selection->set_mode ('single');

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 0, # left justify
                  ypad => 0);
  $renderer->set_fixed_height_from_font (1);

  my $column = Gtk2::TreeViewColumn->new;
  $column->pack_start ($renderer, 1);
  $column->set_cell_data_func ($renderer, \&_cell_data_func);
  $column->set (sizing => 'fixed');
  $treeview->append_column ($column);

  my $notfound = $self->{'notfound'}
    = Gtk2::Label->new (__('Not in database, click "New" to download.
Be sure capitalization is right for download.
(Or click/return again to really open.)'));
  $notfound->set_justify ('center');
  $vbox->pack_start ($notfound, 0,0,0);

  my $hbox = Gtk2::HBox->new;
  $vbox->pack_start ($hbox, 0,0,0);

  $hbox->pack_start (Gtk2::Label->new (__('Symbol')), 0,0,0);

  my $entry = $self->{'entry'} = Gtk2::Entry->new;
  $hbox->pack_start ($entry, 1, 1, 0.5 * Gtk2::Ex::Units::em($entry));
  $entry->signal_connect (activate => \&_do_entry_open);
  $entry->signal_connect (changed  => \&_do_entry_changed);

  my $button = Gtk2::Button->new_with_label (__('Enter'));
  $hbox->pack_start ($button, 0,0,0);
  $button->signal_connect (clicked => \&_do_entry_open);

  $vbox->show_all;
  $notfound->hide;
  $entry->grab_focus;

  # with a sensible size for the TreeView
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self, [$scrolled, '40 ems', '20 lines']);
}

# select etc when newly mapped
sub _do_map {
  my ($self) = @_;

  $self->{'notfound'}->hide;
  my $entry = $self->{'entry'};
  $entry->grab_focus;
  Gtk2::Ex::EntryBits::select_region_noclip ($entry, 0, -1);

  return shift->signal_chain_from_overridden(@_);
}

sub _do_response {
  my ($self, $response) = @_;

  if ($response eq RESPONSE_OPEN) {
    _do_entry_open ($self);

  } elsif ($response eq RESPONSE_NEW) {
    my $symbol = $self->entry_str;
    if ($symbol) { # should be insensitive when empty anyway
      App::Chart::Database->add_symbol ($symbol);
      $self->_do_open ($symbol);
      require App::Chart::Gtk2::DownloadDialog;
      App::Chart::Gtk2::DownloadDialog->popup_update ($symbol, $self);
    }

  } elsif ($response eq 'cancel' || $response eq 'delete-event') {
    $self->hide;

  } elsif ($response eq 'help') {
    require App::Chart::Manual;
    App::Chart::Manual->open(__p('manual-node','Open'), $self);
  }
}

# called:
#     entry widget 'activate'
#     enter button 'clicked'
#     dialog RESPONSE_OPEN
#
sub _do_entry_open {
  my ($widget) = @_;
  my $self = $widget->get_toplevel;
  my $str = $self->entry_str;
  if ($str eq '') {
    $widget->error_bell;
    return;
  }
  my $preferred_symlist = $self->tree_current_symlist;
  my ($symbol, $symlist)
    = App::Chart::SymbolMatch::find ($str, $preferred_symlist);
  if (! $symbol) { $symbol = $str; }
  $self->_do_open ($symbol, $symlist);
}

sub _do_open {
  my ($self, $symbol, $symlist) = @_;
  ### _do_open: $symbol
  ###  symlist: $symlist && $symlist->key
  my $notfound = $self->{'notfound'};
  if (! $notfound->visible

      && ! App::Chart::Database->symbol_exists($symbol)) {
    $self->{'entry'}->set_text ($symbol);
    $notfound->show;
    return;
  }
  $notfound->hide;
  require App::Chart::Gtk2::Main;
  my $main = App::Chart::Gtk2::Main->find_for_dialog ($self);
  $main->show;
  $self->hide;
  $main->goto_symbol ($symbol, $symlist);
}

#------------------------------------------------------------------------------

sub tree_current_symlist {
  my ($self) = @_;
  my $treeview = $self->{'treeview'};
  my ($path, $focus_column) = $treeview->get_cursor;
  if (! $path) { return undef; }

  my $model = $self->{'model'};
  my $iter = $model->get_iter ($path) || return undef;

  # OpenModel
  return $model->get_value ($iter, $model->COL_SYMLIST_OBJECT);

#   if (! $model->iter_has_child ($iter)) {
#     $iter = $model->iter_parent ($iter);
#   }
#   my $key = $model->get_value ($iter, $model->COL_SYMLIST_KEY);
#   return App::Chart::Gtk2::Symlist->new_from_key ($key);
}

sub entry_str {
  my ($self) = @_;
  my $entry = $self->{'entry'};
  return App::Chart::collapse_whitespace ($entry->get_text());
}

sub _do_entry_changed {
  my ($entry) = @_;
  my $self = $entry->get_toplevel;
  $self->{'notfound'}->hide;

  my $str = $self->entry_str;
  # "New" button active when symbol entered
  $self->set_response_sensitive (RESPONSE_NEW, $str ne '');

  require App::Chart::SymbolMatch;
  my $preferred_symlist = $self->tree_current_symlist;
  my ($symbol, $symlist)
    = App::Chart::SymbolMatch::find ($str, $preferred_symlist);
  ### OpenDialog: $str
  ### $symbol
  ### symlist: $symlist && $symlist->name
  if ($symbol && $symlist) {
    $self->scroll_to_symbol_and_symlist ($symbol, $symlist);
  }
}

sub scroll_to_symbol_and_symlist {
  my ($self, $symbol, $symlist) = @_;
  my $treeview = $self->{'treeview'};
  my $model = $self->{'model'};
  my $path = $model->path_for_symbol_and_symlist ($symbol, $symlist);
  if (! $path) {
    die "OpenDialog: oops, no path for $symbol, $symlist";
  }
  ### OpenDialog scroll to: $path->to_string
  Gtk2::Ex::TreeViewBits::scroll_cursor_to_path ($treeview, $path);
}

# 'row-activated' signal on the TreeView
sub _do_row_activated {
  my ($treeview, $path, $treeviewcolumn) = @_;
  ### OpenDialog row_activated: $path->to_string
  my $self = $treeview->get_toplevel;
  my $model = $self->{'model'};
  my $iter = $model->get_iter ($path) || do {
    $self->error_bell;
    return;
  };
  $self->_do_open ($model->get ($iter, $model->COL_ITEM_SYMBOL),
                   $model->get ($iter, $model->COL_SYMLIST_OBJECT));
}

# data setup for the renderer
sub _cell_data_func {
  my ($self, $renderer, $model, $iter) = @_;
  my $path = $model->get_path ($iter);
  my $str;
  if ($path->get_depth == 1) {
    $str = $model->get_value ($iter, $model->COL_SYMLIST_NAME);
  } else {
    if (defined ($str = $model->get_value ($iter, $model->COL_ITEM_SYMBOL))) {
      if (my $name = App::Chart::Database->symbol_name ($str)) {
        $str .= " - $name";
      }
    } else {
      $str = 'oops, no symbol at path=' . $path->to_string;
    }
  }
  $renderer->set (text => $str);
}

1;
__END__


=head1 NAME

App::Chart::Gtk2::OpenDialog -- open dialog widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::OpenDialog;
 my $dialog = App::Chart::Gtk2::OpenDialog->new;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::OpenDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::OpenDialog

=head1 DESCRIPTION

...

=head1 SIGNALS

=over 4

=item C<open> (parameters: C<$dialog>, C<$symbol>)

Emitted when the user asks to open a symbol, either by clicking from the
list or typing in a symbol.

=item C<new> (parameters: C<$dialog>, C<$symbol>)

Emitted when the user asks to create a new symbol.

=back

=cut
