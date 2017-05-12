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

package App::Chart::Gtk2::RawDialog;
use 5.010;
use strict;
use warnings;
use Gtk2 1.220;
use Locale::TextDomain 1.18;
use Locale::TextDomain 'App-Chart';
use List::Util qw(min max);

use Gtk2::Ex::Datasheet::DBI;
use Gtk2::Ex::WidgetCursor;

use Gtk2::Ex::Units;

# hack for Gtk2::Ex::Datasheet::DBI 2.1
{ package Gtk2::Ex::Datasheet::DBI::CellRendererText;
  sub GET_SIZE {
    my ($self, $widget, $cell_area) = @_;
    return $self->SUPER::GET_SIZE ($widget, $cell_area);
  }
}

use App::Chart::Gtk2::Ex::NotebookLazyPages;
use App::Chart::Gtk2::GUI;
use App::Chart::Intraday;
use App::Chart::Gtk2::SeriesTreeView;
use App::Chart::Gtk2::RawLatest;
use App::Chart::Gtk2::RawInfo;

# uncomment this to run the ### lines
#use Smart::Comments;


use Glib::Object::Subclass
  'Gtk2::Dialog',
  properties => [Glib::ParamSpec->string
                 ('symbol',
                   __('Symbol'),
                  'The symbol to display.',
                  '', # default
                  Glib::G_PARAM_READWRITE),];


use constant { RESPONSE_INSERT  => 0,
               RESPONSE_DELETE  => 1,
               RESPONSE_APPLY   => 2,
               RESPONSE_UNDO    => 3,
               RESPONSE_REFRESH => 4,
             };

# sub _do_edited {
#   my ($cell, $pathstr, $newstr, $self) = @_;
#   my $path = Gtk2::TreePath->new_from_string ($pathstr);
#   my $model = $self->{'model'};
#   my $treeview = $self->{'treeview'};
#   my $iter = $model->get_iter ($path);
#   my ($treepath, $treeviewcolumn) = $treeview->get_cursor;
#   my $col = $treeviewcolumn->{'model_col'};
#   $model->set_value ($iter, $col, $newstr);
# }

# sub _do_data_changed {
#   my ($self, $symbol_hash) = @_;
#   my $symbol = $self->{'symbol'};
#   if (List::Util::first {$_ eq $symbol} @symbol_list) {
#     $self->refresh;
#   }
# }

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set_title (__('Chart: RawDialog'));
  $self->{'symbol'} = ''; # default

  #   App::Chart::chart_dirbroadcast()->connect_for_object ('data-changed',
  #                                          \&_do_data_changed, $self);

  $self->add_buttons ('gtk-add'     => RESPONSE_INSERT,
                      'gtk-delete'  => RESPONSE_DELETE,
                      'gtk-apply'   => RESPONSE_APPLY,
                      'gtk-undo'    => RESPONSE_UNDO,
                      'gtk-refresh' => RESPONSE_REFRESH,
                      'gtk-close'   => 'close',
                      'gtk-help'    => 'help');
  $self->signal_connect ('response', \&_do_response);

  my $vbox = $self->vbox;

  $vbox->pack_start (Gtk2::Label->new
                     ('Warning, this dialog is not quite right.'),
                     0,0,0);

  my $notebook = $self->{'notebook'} = Gtk2::Notebook->new;
  $vbox->pack_start ($notebook, 1,1,0);

  {
    my $scrolled = Gtk2::ScrolledWindow->new;
    $notebook->append_page ($scrolled, __('Series'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $scrolled, \&_init_series);
  }
  {
    my $div_vbox = Gtk2::VBox->new;
    $notebook->append_page ($div_vbox, __('Dividends'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $div_vbox, \&_init_dividends);
  }
  {
    my $split_vbox = Gtk2::VBox->new;
    $notebook->append_page ($split_vbox, __('Splits'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $split_vbox, \&_init_splits);
  }

  {
    my $scrolled = Gtk2::ScrolledWindow->new;
    $notebook->append_page ($scrolled, __('Latest'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $scrolled, \&_init_latest);
  }

  {
    my $scrolled = Gtk2::ScrolledWindow->new;
    $notebook->append_page ($scrolled, __('Info'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $scrolled, \&_init_info);
  }

  {
    my $scrolled = Gtk2::ScrolledWindow->new;
    $notebook->append_page ($scrolled, __('Extra'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $scrolled, \&_init_extra);
  }

  {
    my $scrolled = Gtk2::ScrolledWindow->new;
    $notebook->append_page ($scrolled, __('Intraday'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $scrolled, \&_init_intraday);
  }

  {
    my $scrolled = Gtk2::ScrolledWindow->new;
    $notebook->append_page ($scrolled, __('Lines'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $scrolled, \&_init_lines);
  }

  {
    my $scrolled = Gtk2::ScrolledWindow->new;
    $notebook->append_page ($scrolled, __('Alerts'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $scrolled, \&_init_alerts);
  }

  {
    my $scrolled = Gtk2::ScrolledWindow->new;
    $notebook->append_page ($scrolled, __('Weblinks'));
    App::Chart::Gtk2::Ex::NotebookLazyPages::set_init
        ($notebook, $scrolled, \&_init_weblinks);
  }

  $notebook->signal_connect ('notify::page' => \&_do_notebook_page);
  $notebook->set_current_page (1);
  _do_notebook_page ($notebook, undef); # initial button sensitives

  my $hbox = Gtk2::HBox->new (0, 0);
  $vbox->pack_start ($hbox, 0,0,0);
  $hbox->pack_start (Gtk2::Label->new (__('Symbol')), 0,0,0);
  my $entry = $self->{'entry'} = Gtk2::Entry->new;
  $hbox->pack_start ($entry, 1, 1, 0.5 * Gtk2::Ex::Units::em($entry));
  $entry->signal_connect (activate => \&_do_entry_activate);
  $entry->grab_focus;

  $vbox->show_all;

  # Size per a sensible height for the notebook.

  # With all the scrolleds in 'never' mode they give their contained
  # treeviews as their width.
  # FIXME: ... which is not true any more ...
  Gtk2::Ex::Units::set_default_size_with_subsizes
      ($self, [$notebook, -1, '25 lines']);
}

sub _init_series {
  my ($notebook, $scrolled, $pagenum) = @_;

  $scrolled->{'dirty'} = 1;
  $scrolled->set (hscrollbar_policy => 'automatic');

  my $treeview = $scrolled->{'seriestreeview'}
    = App::Chart::Gtk2::SeriesTreeView->new;
  $scrolled->add ($treeview);

  $scrolled->show_all;
}

sub _init_dividends {
  my ($notebook, $vbox, $pagenum) = @_;

  my $self = $notebook->get_toplevel;
  my $scrolled = Gtk2::ScrolledWindow->new;
  $scrolled->set (hscrollbar_policy => 'never');
  $vbox->pack_start ($scrolled, 1,1,0);

  my $treeview = Gtk2::TreeView->new;
  $scrolled->add ($treeview);

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;

  my $em = Gtk2::Ex::Units::em($self);
  my $date_width = App::Chart::Gtk2::GUI::string_width ($treeview, '2099-99-99 ');
  my $date_width_editable = $date_width * 1.4; # diff font, and pulldown
  my $digit_width = Gtk2::Ex::Units::digit_width ($self);

  my $datasheet = Gtk2::Ex::Datasheet::DBI->new
    ({ dbh => $dbh,
       sql => { select   => 'ex_date, record_date, pay_date, amount, imputation, type, qualifier, note',
                from     => 'dividend',
                order_by => 'ex_date DESC',
                where    => 'symbol=?',
                bind_values => [ '' ],
              },
       treeview => $treeview,
       fields => [ { name          => 'ex_date',
                     header_markup => __('Ex'),
                     x_absolute    => $date_width_editable,
                     validation    => \&validate_date,
                     # renderer      => 'date',
                   },
                   { name          => 'record_date',
                     header_markup => __('Record'),
                     x_absolute    => $date_width_editable,
                     validation    => \&validate_date,
                     # renderer      => 'date',
                   },
                   { name          => 'pay_date',
                     header_markup => __('Pay'),
                     x_absolute    => $date_width_editable,
                     validation    => \&validate_date,
                     # renderer      => 'date',
                   },
                   { name          => 'amount',
                     header_markup => __('Amount'),
                     align         => 'right',
                     x_absolute    => 8 * $digit_width,
                     validation    => \&validate_number,
                   },
                   { name          => 'imputation',
                     header_markup => __('Imputation'),
                     align         => 'right',
                     x_absolute    => 8 * $digit_width,
                     validation    => \&validate_number,
                   },
                   { name          => 'type',
                     header_markup => __('Type'),
                     x_absolute    => 6 * $em,
                   },
                   { name          => 'qualifier',
                     header_markup => __('Qualifier'),
                     x_absolute    => 6 * $em,
                   },
                   { name          => 'note',
                     header_markup => __('Note'),
                     x_absolute    => 10 * $em,
                   },
                 ],
     });
  $vbox->{'insert_defaults'} = \&_dividends_insert_defaults;
  _datasheet_init ($self, $vbox, $datasheet);
}
sub _dividends_insert_defaults {
  my ($self, $pagewidget) = @_;
  my $datasheet = $pagewidget->{'datasheet'};
  my $num = $datasheet->{'column_name_to_number_mapping'};
  return ($num->{'ex_date'}, $self->default_date,
          $num->{'amount'},  0,
          $num->{'note'},    '');
}

sub default_date {
  my ($self) = @_;
  my $symbol = $self->{'symbol'} // '';
  my $timezone = App::Chart::TZ->for_symbol ($symbol);
  require App::Chart::Download;
  my $tdate = App::Chart::Download::tdate_today ($timezone);
  return App::Chart::tdate_to_iso($tdate);
}

sub _init_splits {
  my ($notebook, $vbox, $pagenum) = @_;

  my $self = $notebook->get_toplevel;
  my $scrolled = Gtk2::ScrolledWindow->new;
  $scrolled->set (hscrollbar_policy => 'never');
  $vbox->pack_start ($scrolled, 1,1,0);

  my $treeview = Gtk2::TreeView->new;
  $scrolled->add ($treeview);

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;

  my $em = Gtk2::Ex::Units::em($self);
  my $date_width = App::Chart::Gtk2::GUI::string_width ($treeview, '2099-99-99 ');
  my $date_width_editable = $date_width * 1.4; # diff font, and pulldown
  my $digit_width = Gtk2::Ex::Units::digit_width ($self);

  my $datasheet = Gtk2::Ex::Datasheet::DBI->new
    ({ dbh => $dbh,
       sql => { select   => 'date, new, old, note',
                from     => 'split',
                order_by => 'date DESC',
                where    => 'symbol=?',
                bind_values => [ '' ],
              },
       treeview => $treeview,
       fields => [ { name          => 'date',
                     header_markup => __('Date'),
                     x_absolute    => $date_width_editable,
                     validation    => \&validate_date,
                     # renderer      => 'date',
                   },
                   { name          => 'new',
                     header_markup => __('New'),
                     align         => 'right',
                     x_absolute    => 3 * $digit_width,
                     validation    => \&validate_number,
                   },
                   { name          => 'old',
                     header_markup => __('Old'),
                     align         => 'right',
                     x_absolute    => 3 * $digit_width,
                     validation    => \&validate_number,
                   },
                   { name          => 'note',
                     header_markup => __('Note'),
                     x_absolute    => 10 * $em,
                   },
                 ],
     });
  _datasheet_init ($self, $vbox, $datasheet);
  $vbox->{'insert_defaults'} = \&_splits_insert_defaults;
}
sub _splits_insert_defaults {
  my ($self, $pagewidget) = @_;
  my $datasheet = $pagewidget->{'datasheet'};
  my $num = $datasheet->{'column_name_to_number_mapping'};
  return ($num->{'date'}, $self->default_date,
          $num->{'new'},  1,
          $num->{'old'},  1,
          $num->{'note'}, '');
}

sub _init_latest {
  my ($notebook, $scrolled, $pagenum) = @_;

  $scrolled->{'dirty'} = 1;
  $scrolled->set (hscrollbar_policy => 'never'); # label wrap

  my $viewport = Gtk2::Viewport->new;
  $scrolled->add ($viewport);

  my $rawlatest = $scrolled->{'rawlatest'} = App::Chart::Gtk2::RawLatest->new;
  $viewport->add ($rawlatest);

  $scrolled->show_all;
}

sub _init_info {
  my ($notebook, $scrolled, $pagenum) = @_;

  $scrolled->{'dirty'} = 1;
  $scrolled->set (hscrollbar_policy => 'never'); # label wrap

  my $viewport = Gtk2::Viewport->new;
  $scrolled->add ($viewport);

  my $rawinfo = $scrolled->{'rawinfo'} = App::Chart::Gtk2::RawInfo->new;
  $viewport->add ($rawinfo);

  $scrolled->show_all;
}

sub _init_extra {
  my ($notebook, $scrolled, $pagenum) = @_;
  my $self = $notebook->get_toplevel;

  $scrolled->set (hscrollbar_policy => 'automatic');

  my $treeview = Gtk2::TreeView->new;
  $scrolled->add ($treeview);

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $em = Gtk2::Ex::Units::em($self);

  my $datasheet = Gtk2::Ex::Datasheet::DBI->new
    ({ dbh => $dbh,
       sql => { select   => 'key, value',
                from     => 'extra',
                order_by => 'key ASC',
                where    => 'symbol=?',
                bind_values => [ '' ],
              },
       treeview => $treeview,
       fields => [
                  { name => 'key',
                    header_markup => __('Key'),
                    x_absolute    => 15 * $em,
                  },
                  { name => 'value',
                    header_markup => __('Value'),
                    x_absolute    => 15 * $em,
                  },
                 ],
     });
  $scrolled->{'insert_defaults'} = \&_extra_insert_defaults;
  _datasheet_init ($self, $scrolled, $datasheet);
}
sub _extra_insert_defaults {
  my ($self, $pagewidget) = @_;
  return;
}

sub _init_intraday {
  my ($notebook, $scrolled, $pagenum) = @_;
  my $self = $notebook->get_toplevel;

  $scrolled->set (hscrollbar_policy => 'automatic');

  my $treeview = Gtk2::TreeView->new;
  $scrolled->add ($treeview);

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $em = Gtk2::Ex::Units::em($self);
  my $digit_width = Gtk2::Ex::Units::digit_width ($self);

  my $datasheet = Gtk2::Ex::Datasheet::DBI->new
    ({ dbh => $dbh,
       sql => { select   => 'mode, error, fetch_timestamp, url, etag, last_modified',
                from     => 'intraday_image',
                order_by => 'mode ASC',
                where    => 'symbol=?',
                bind_values => [ '' ],
              },
       treeview => $treeview,
       fields => [ { name          => 'mode',
                     header_markup => __('Mode'),
                     x_absolute    => 4 * $em,
                   },
                   { name          => 'error',
                     header_markup => __('Error'),
                     x_absolute    => 10 * $em,
                   },
                   { name          => 'fetch_timestamp',
                     header_markup => __('Fetch Timestamp'),
                     x_absolute    => (length('2009-03-09 22:01:31+00:00')
                                       * $digit_width),
                     validation    => \&validate_integer,
                   },
                   { name          => 'url',
                     header_markup => __('URL'),
                     x_absolute    => 10 * $em,
                   },
                   { name          => 'etag',
                     header_markup => __('ETag'),
                     x_absolute    => 10 * $em,
                   },
                   { name          => 'last_modified',
                     header_markup => __('Last Modified'),
                     x_absolute    => 10 * $em,
                   },
                 ],
       multi_select => 1,
     });
  _datasheet_init ($self, $scrolled, $datasheet);
}

sub _init_lines {
  my ($notebook, $scrolled, $pagenum) = @_;
  my $self = $notebook->get_toplevel;

  $scrolled->set (hscrollbar_policy => 'automatic');

  my $treeview = Gtk2::TreeView->new;
  $scrolled->add ($treeview);

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $date_width = App::Chart::Gtk2::GUI::string_width ($treeview, '2099-99-99 ');
  my $date_width_editable = $date_width * 1.4; # diff font, and pulldown
  my $em = Gtk2::Ex::Units::em($treeview);
  my $digit_width = Gtk2::Ex::Units::digit_width ($self);

  my $datasheet = Gtk2::Ex::Datasheet::DBI->new
    ({ dbh => $dbh,
       sql => { select   => 'id,date1,price1,date2,price2,horizontal',
                from     => 'line',
                order_by => 'id ASC',
                where    => 'symbol=?',
                bind_values => [ '' ],
              },
       treeview => $treeview,
       fields => [
                  { name => 'id',
                    header_markup => __('Id'),
                    x_absolute    => 3 * $em,
                  },
                  { name          => 'date1',
                    header_markup => __('Date1'),
                    x_absolute    => $date_width_editable,
                    validation    => \&validate_date,
                    # renderer      => 'date',
                  },
                  { name          => 'price1',
                    header_markup => __('Price1'),
                    x_absolute    => 15 * $digit_width,
                    validation    => \&validate_number,
                  },
                  { name          => 'date2',
                    header_markup => __('Date2'),
                    x_absolute    => $date_width_editable,
                    validation    => \&validate_date,
                    # renderer      => 'date',
                  },
                  { name          => 'price2',
                    header_markup => __('Price2'),
                    x_absolute    => 15 * $digit_width,
                    validation    => \&validate_number,
                  },
                  { name          => 'horizontal',
                    header_markup => __('Horizontal'),
                    # validation    => \&validate_boolean,
                  },
                 ],
     });
  _datasheet_init ($self, $scrolled, $datasheet);
  $scrolled->{'insert_defaults'} = \&_lines_insert_defaults;
}
sub _lines_insert_defaults {
  my ($self, $pagewidget) = @_;
  my $datasheet = $pagewidget->{'datasheet'};
  my $num = $datasheet->{'column_name_to_number_mapping'};
  #### $num
  my $date = $self->default_date;
  return ($num->{'date1'},  $date,
          $num->{'price1'}, 0,
          $num->{'date2'},  $date,
          $num->{'price2'}, 1);
}

sub _init_alerts {
  my ($notebook, $scrolled, $pagenum) = @_;
  my $self = $notebook->get_toplevel;

  $scrolled->set (hscrollbar_policy => 'automatic');

  my $treeview = Gtk2::TreeView->new;
  $scrolled->add ($treeview);

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $em = Gtk2::Ex::Units::em($treeview);
  my $digit_width = Gtk2::Ex::Units::digit_width ($self);

  my $datasheet = Gtk2::Ex::Datasheet::DBI->new
    ({ dbh => $dbh,
       sql => { select   => 'id,price,above',
                from     => 'alert',
                order_by => 'id ASC',
                where    => 'symbol=?',
                bind_values => [ '' ],
              },
       treeview => $treeview,
       fields => [
                  { name => 'id',
                    header_markup => __('Id'),
                    x_absolute    => 3 * $em,
                  },
                  { name          => 'price1',
                    header_markup => __('Price1'),
                    x_absolute    => 15 * $digit_width,
                    validation    => \&validate_number,
                  },
                  { name          => 'above',
                    header_markup => __('Above'),
                    # validation    => \&validate_boolean,
                  },
                 ],
     });

  _datasheet_init ($self, $scrolled, $datasheet);
}

sub _datasheet_init {
  my ($self, $pagewidget, $datasheet) = @_;

  my $scrolled = $pagewidget;
  if ($pagewidget->isa ('Gtk2::VBox')) {
    ($scrolled) = $pagewidget->get_children;
    if ($datasheet->{'read_only'}) {
      $pagewidget->pack_start (Gtk2::Label->new(__('*** Read only ***')),
                               0,0,0);
    }
  }

  $pagewidget->{'dirty'} = 1;
  $pagewidget->{'datasheet'} = $datasheet;
  push @{$self->{'datasheets'}}, $datasheet;

  my $treeview = $scrolled->get_child;
  foreach my $column ($treeview->get_columns) {
    $column->set (resizable => 1);
    $column->set_sizing ('fixed');
  }
  $treeview->set_fixed_height_mode (1);

  $pagewidget->show_all;
  _refresh_page ($pagewidget);
}

sub _init_weblinks {
  my ($notebook, $scrolled, $pagenum) = @_;

  $scrolled->set (hscrollbar_policy => 'automatic');

  my $treeview = Gtk2::TreeView->new;
  $treeview->set (tooltip_column => 2);
  $treeview->signal_connect (row_activated => \&_do_weblink_row_activate);
  $treeview->signal_connect (button_press_event => \&_do_weblink_button_press);
  $scrolled->add ($treeview);

  my $store = $scrolled->{'weblinks_store'}
    = Gtk2::ListStore->new ('Glib::String', 'Glib::String', 'Glib::String');
  $treeview->set_model ($store);

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xalign => 0,
                  ypad => 0);
  $renderer->set_fixed_height_from_font (1);

  my $em = Gtk2::Ex::Units::em($treeview);
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('Name'), $renderer, markup => 0);
    $column->set (sizing      => 'fixed',
                  fixed_width => 20*$em,
                  resizable   => 1);
    $treeview->append_column ($column);
  }
  {
    my $column = Gtk2::TreeViewColumn->new_with_attributes
      (__('URL'), $renderer, text => 1);
    $column->set (sizing      => 'fixed',
                  fixed_width => 60*$em,
                  resizable   => 1);
    $column->{'menu_func'} = \&_do_weblink_menu_popup;
    $treeview->append_column ($column);
  }
  $scrolled->show_all;
}
sub _do_weblink_row_activate {
  my ($treeview, $path, $column) = @_;
  my $url = _do_weblink_row_url ($treeview, $path);
  require App::Chart::Gtk2::GUI;
  App::Chart::Gtk2::GUI::browser_open ($url);
}
sub _do_weblink_row_url {
  my ($treeview, $path) = @_;
  my $store = $treeview->get_model;
  my $iter = $store->get_iter ($path);
  return $store->get_value ($iter, 1);
}
sub mnemonic_to_markup {
  my ($str) = @_;
  $str = Glib::Markup::escape_text($str);
  $str =~ s{_(.)}{$1 eq '_' ? '' : "<u>$1</u>"}eg;
  return $str;
}
# 'button-press-event' on the weblink TreeView
sub _do_weblink_button_press {
  my ($treeview, $event) = @_;
  my ($path, $column) = $treeview->get_path_at_pos ($event->x, $event->y);
  if (!$path) { return; }
  if (my $func = $column->{'menu_func'}) {
    $func->($treeview, $event, $path);
  }
  return Gtk2::EVENT_PROPAGATE;
}
sub _do_weblink_menu_popup {
  my ($treeview, $event, $path) = @_;
  my $menu = Gtk2::Menu->new;
  $menu->set_screen ($treeview->get_screen);
  my $url = _do_weblink_row_url ($treeview, $path);
  {
    my $item = Gtk2::ImageMenuItem->new_from_stock ('gtk-open');
    $item->{'url'} = $url;
    $item->signal_connect (activate => \&_do_weblink_menu_open);
    $menu->append ($item);
  }
  # LinkButton of Gtk 2.14 has a "Copy URL" message string (translated etc),
  # could show that
  {
    my $item = Gtk2::ImageMenuItem->new_from_stock ('gtk-copy');
    $item->{'url'} = $url;
    $item->signal_connect (activate => \&_do_weblink_menu_copy);
    $menu->append ($item);
  }
  $menu->show_all;
  $menu->popup (undef, undef, undef, undef,
                $event->button, $event->time);
}
sub _do_weblink_menu_open {
  my ($item) = @_;
  require App::Chart::Gtk2::GUI;
  App::Chart::Gtk2::GUI::browser_open ($item->{'url'});
}
sub _do_weblink_menu_copy {
  my ($item) = @_;
  my $clipboard = Gtk2::Clipboard->get_for_display
    ($item->get_display, Gtk2::Gdk::Atom->new('PRIMARY'));
  $clipboard->set_text ($item->{'url'});
}

sub set_symbol {
  my ($self, $symbol) = @_;
  if (! defined $symbol) { $symbol = ''; }
  if ($symbol eq $self->{'symbol'}) { return; }

  if ($symbol) {
    $self->set_title (__x('Chart: RawDialog: {symbol}',
                          symbol => $symbol));
  } else {
    $self->set_title (__('Chart: RawDialog'));
  }
  $self->{'symbol'} = $symbol;  # per default GET_PROPERTY
  $self->{'entry'}->set_text ($symbol);
  $self->refresh;
  $self->notify ('symbol');
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if ($pspec->get_name eq 'symbol') {
    $self->set_symbol ($newval);
  } else {
    $self->{$pname} = $newval;   # per default GET_PROPERTY
  }
}

# 'notify::page' signal on the Gtk2::Notebook
sub _do_notebook_page {
  my ($notebook) = @_;
  my $self = $notebook->get_toplevel;
  my $pagenum = $notebook->get_current_page;
  my $pagewidget = $notebook->get_nth_page ($pagenum);

  $self->set_response_sensitive (RESPONSE_APPLY,  $pagewidget->{'datasheet'});
  $self->set_response_sensitive (RESPONSE_UNDO,   $pagewidget->{'datasheet'});
  $self->set_response_sensitive (RESPONSE_DELETE, $pagewidget->{'datasheet'});
  $self->set_response_sensitive (RESPONSE_INSERT, $pagewidget->{'insert_defaults'});

  _refresh_page ($self, $pagewidget);
}

sub _refresh_page {
  my ($self, $pagewidget) = @_;
  ### _refresh_page(): $pagewidget->{'dirty'}
  ### for: $self->{'symbol'}

  if ($pagewidget->{'dirty'}) {
    Gtk2::Ex::WidgetCursor->busy;
    $pagewidget->{'dirty'} = 0;
    my $symbol = $self->{'symbol'};
    if (my $datasheet = $pagewidget->{'datasheet'}) {
      ### datasheet query
      $datasheet->query ({bind_values => [$symbol]}, 0);

    } elsif (my $seriestreeview = $pagewidget->{'seriestreeview'}) {
      my $series;
      if ($symbol) {
        require App::Chart::Series::Database;
        $series = App::Chart::Series::Database->new ($symbol);
      }
      $seriestreeview->set (series => $series);

    } elsif (my $rawlatest = $pagewidget->{'rawlatest'}) {
      $rawlatest->set (symbol => $symbol);

    } elsif (my $rawinfo = $pagewidget->{'rawinfo'}) {
      $rawinfo->set (symbol => $symbol);

    } elsif (my $store = $pagewidget->{'weblinks_store'}) {
      require App::Chart::Weblink;
      my @weblinks = App::Chart::Weblink->links_for_symbol ($symbol);
      ### weblinks for: $symbol, scalar(@weblinks)
      $store->clear;
      foreach my $weblink (@weblinks) {
        $store->set ($store->append,
                     0 => mnemonic_to_markup ($weblink->name),
                     1 => $weblink->url ($symbol),
                     2 => __('Double click to open this URL in a browser'));
      }
    } else {
      die 'Oops, unknown raw refresh';
    }
  }
}

sub refresh {
  my ($self) = @_;
  ### RawDialog refresh()
  my $notebook = $self->{'notebook'};
  $notebook->foreach (sub {
                        my ($scrolled) = @_;
                        $scrolled->{'dirty'} = 1;
                      });
  _do_notebook_page ($notebook); # redraw current page
}

# 'response' signal on ourselves
sub _do_response {
  my ($self, $response) = @_;

  if ($response eq RESPONSE_REFRESH) {
    $self->refresh;

  } elsif ($response eq RESPONSE_INSERT) {
    my $notebook = $self->{'notebook'};
    my $pagenum = $notebook->get_current_page;
    my $pagewidget = $notebook->get_nth_page ($pagenum);
    if ((my $datasheet = $pagewidget->{'datasheet'})
        && (my $defaults_func = $pagewidget->{'insert_defaults'})) {
      $datasheet->insert ($defaults_func->($self, $pagewidget));
    }

  } elsif ($response eq RESPONSE_DELETE) {
    my $notebook = $self->{'notebook'};
    my $pagenum = $notebook->get_current_page;
    my $pagewidget = $notebook->get_nth_page ($pagenum);
    if (my $datasheet = $pagewidget->{'datasheet'}) {
      $datasheet->delete;
    }

  } elsif ($response eq RESPONSE_APPLY) {
    foreach my $datasheet (@{$self->{'datasheets'}}) {
      $datasheet->apply;
    }

  } elsif ($response eq RESPONSE_UNDO) {
    my $notebook = $self->{'notebook'};
    my $pagenum = $notebook->get_current_page;
    my $pagewidget = $notebook->get_nth_page ($pagenum);
    if (my $datasheet = $pagewidget->{'datasheet'}) {
      $datasheet->undo;
    }

  } elsif ($response eq 'close') {
    # as per a keyboard close, defaults to raising 'delete-event', which in
    # turn defaults to a destroy
    $self->signal_emit ('close');

  } elsif ($response eq 'help') {
    require App::Chart::Manual;
    App::Chart::Manual->open(__p('manual-node','Raw Data'), $self);
  }
}

# 'activate' signal on the Gtk2::Entry widget
sub _do_entry_activate {
  my ($entry) = @_;
  my $self = $entry->get_toplevel;
  $self->set_symbol ($entry->get_text);
}

# return true if $str is a valid ISO format date like 2008-05-27
sub validate_date {
  my ($str) = @_;
  return ($str =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/);
}

# return true if $str is a valid number
sub validate_number {
  my ($str) = @_;
  return ($str =~ /^[0-9]*(.[0-9]*)?$/);
}

# return true if $str is a valid number
sub validate_integer {
  my ($str) = @_;
  return ($str =~ /^[0-9]*$/);
}

sub popup {
  my ($class, $symbol, $parent) = @_;
  if (! defined $symbol) { $symbol = ''; }
  require App::Chart::Gtk2::Ex::ToplevelBits;
  return App::Chart::Gtk2::Ex::ToplevelBits::popup
    ($class,
     properties => { symbol => $symbol },
     screen => $parent);
}

1;
__END__

=for stopwords RawDialog

=head1 NAME

App::Chart::Gtk2::RawDialog -- raw data display dialog

=head1 SYNOPSIS

 use App::Chart::Gtk2::RawDialog;
 App::Chart::Gtk2::RawDialog->popup();

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::RawDialog> is a subclass of C<Gtk2::Dialog>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            Gtk2::Dialog
              App::Chart::Gtk2::RawDialog

=head1 DESCRIPTION

A C<App::Chart::Gtk2::RawDialog> widget displays raw daily date, open, high, low,
etc from the database.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::RawDialog->new (key=>value,...) >>

Create and return a new RawDialog dialog widget.

=item C<< App::Chart::Gtk2::RawDialog->popup () >>

=item C<< App::Chart::Gtk2::RawDialog->popup ($symbol, $parent) >>

Create and open a C<RawDialog> dialog showing the data for C<$symbol>.
C<$symbol> can be omitted, or C<undef>, or the empty string, to display
nothing initially.

=back

=cut
