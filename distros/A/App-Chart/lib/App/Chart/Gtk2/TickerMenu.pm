# Copyright 2006, 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::TickerMenu;
use 5.010;
use strict;
use warnings;
use Scalar::Util;
use Gtk2;
use Glib::Ex::ConnectProperties;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Gtk2::Ticker;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Menu',
  properties => [ Glib::ParamSpec->string
                  ('symbol',
                   __('Symbol'),
                   'Stock or commodity symbol string.',
                   '', # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('ticker',
                   'Ticker',
                   'Ticker widget.',
                   'App::Chart::Gtk2::Ticker',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  ### TickerMenu INIT_INSTANCE()

  { my $item = Gtk2::ImageMenuItem->new_from_stock
      ('gtk-refresh', $self->get_accel_group);
    $item->signal_connect (activate => \&_do_menu_refresh);
    $self->append ($item);
  }

  { my $item = Gtk2::MenuItem->new_with_mnemonic (__('_Symbols'));
    $self->append ($item);

    require App::Chart::Gtk2::SymlistRadioMenu;
    my $symlist_menu = $self->{'symlist_menu'}
      = App::Chart::Gtk2::SymlistRadioMenu->new;
    $item->set_submenu ($symlist_menu);
  }

  { my $item = $self->{'run_item'}
      = Gtk2::CheckMenuItem->new_with_mnemonic (__('R_un'));
    $self->append ($item);
  }

  $self->append (Gtk2::SeparatorMenuItem->new);

  my @symbol_items;
  $self->{'symbol_items'} = \@symbol_items;
  {
    my $label = $self->{'symbol_label'} = Gtk2::Label->new (' ');
    $label->set_alignment (0.5, 0);  # centre horizontally

    my $item = Gtk2::MenuItem->new;
    $item->add ($label);
    $self->append ($item);
    push @symbol_items, $item;
  }
  {
    my $item = Gtk2::MenuItem->new_with_mnemonic (__('_Chart'));
    $item->set_tooltip_text (__('Go to this symbol in the main Chart window'));
    $item->signal_connect (activate => \&_do_chart);
    $self->append ($item);
  }
  {
    my $item = $self->{'menu_intraday'}
      = Gtk2::MenuItem->new_with_mnemonic (__('_Intraday'));
    $item->set_tooltip_text (__('View intraday graphs for this symbol'));
    $item->signal_connect (activate => \&_do_intraday);
    $self->append ($item);
    push @symbol_items, $item;
  }
  {
    my $item = Gtk2::MenuItem->new_with_mnemonic (__('_Web'));
    $self->append ($item);

    require App::Chart::Gtk2::WeblinkMenu;
    my $webmenu = $self->{'weblinkmenu'} = App::Chart::Gtk2::WeblinkMenu->new;
    $item->set_submenu ($webmenu);
    push @symbol_items, $item;
  }

  $self->append (Gtk2::SeparatorMenuItem->new);

  {
    my $item = Gtk2::ImageMenuItem->new_from_stock
      ('gtk-help', $self->get_accel_group);
    $item->signal_connect (activate => \&_do_help);
    $self->append ($item);
  }
  {
    my $item = Gtk2::MenuItem->new_with_mnemonic (__('_Hide'));
    $item->set_name ('hide');
    $item->signal_connect ('activate', \&_do_hide);
    $self->append ($item);
  }

  foreach ($self->get_children) {
    $_->show_all;
  }

  $self->show_all;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### TickerMenu SET_PROPERTY(): $pspec->get_name
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol') {
    $self->{'symbol_label'}->set_text (defined $newval ? $newval : '--');
    $self->{'weblinkmenu'}->set (symbol => $newval);

    my $sens = (defined $newval && $newval ne '');
    foreach my $item (@{$self->{'symbol_items'}}) {
      $item->set_sensitive ($sens);
    }
  }

  if ($pname eq 'ticker') {
    $self->{'run_conn'} = $newval
      && Glib::Ex::ConnectProperties->new ([$newval,'run'],
                                           [$self->{'run_item'},'active']);
    $self->{'symlist_conn'} = $newval
      && Glib::Ex::ConnectProperties->new ([$newval, 'symlist'],
                                           [$self->{'symlist_menu'}, 'symlist']);
    Scalar::Util::weaken ($self->{$pname});
  }
}

# 'activate' signal on Refresh menu item
sub _do_menu_refresh {
  my ($menuitem) = @_;
  my $self = $menuitem->get_parent || return;
  my $ticker = $self->get('ticker') || return;
  my $symlist = $ticker->get('symlist');
  require App::Chart::Gtk2::Job::Latest;
  App::Chart::Gtk2::Job::Latest->start_symlist ($symlist);
}

# Help menu item 'activate' handler
sub _do_help {
  my ($menuitem) = @_;
  my $self = $menuitem->get_parent || return;
  my $ticker = $self->get('ticker') || return;
  $ticker->help;
}

# 'activate' signal on Hide menu item
sub _do_hide {
  my ($menuitem) = @_;
  ### TickerMenu _do_hide()
  my $self = $menuitem->get_parent || return;
  my $ticker = $self->get('ticker') || return;
  $ticker->hide;
}

sub _do_intraday {
  my ($menuitem) = @_;
  my $self = $menuitem->get_parent || return;
  ### TickerMenu intraday: $self->{'symbol'}
  require  App::Chart::Gtk2::Ex::ToplevelBits;
  App::Chart::Gtk2::Ex::ToplevelBits::popup
      ('App::Chart::Gtk2::IntradayDialog',
       properties => { symbol => $self->get('symbol') },
       screen => $self);
}

# open the main chart display on the current symbol
sub _do_chart {
  my ($menuitem) = @_;
  my $self = $menuitem->get_parent || return;
  my $ticker = $self->get('ticker');
  require App::Chart::Gtk2::Main;
  my $main = App::Chart::Gtk2::Main->find_for_dialog ($ticker || $self);
  $main->goto_symbol ($self->{'symbol'}, $ticker && $ticker->get('symlist'));
  $main->present;
}

# sub popup_from_ticker {
#   my ($class_or_self, $event, $treeview) = @_;
#   my $self = ref $class_or_self ? $class_or_self : $class_or_self->instance;
# 
#   my $watchlist = $treeview->get_toplevel;
#   require Scalar::Util;
#   Scalar::Util::weaken ($self->{'watchlist'} = $watchlist);
# 
#   my ($path) = $treeview->get_path_at_pos ($event->x, $event->y);
#   if (! $path) { return; }
# 
#   my $model = $treeview->get_model;  # App::Chart::Gtk2::WatchlistModel
#   my $symlist = $model->get_symlist;
#   my $iter = $symlist->get_iter ($path);
#   my $symbol = $symlist->get_value ($iter, $model->COL_SYMBOL);
#   $self->set (symbol => $symbol,
#               symlist => $symlist);
#   $self->set_screen ($treeview->get_screen);
#   $self->popup (undef, undef, undef, undef, $event->button, $event->time);
# }

1;
__END__

=for stopwords watchlist Watchlist TickerMenu Popup undef clickable symlist

=head1 NAME

App::Chart::Gtk2::TickerMenu -- menu for ticker

=for test_synopsis my ($event, $ticker)

=head1 SYNOPSIS

 use App::Chart::Gtk2::TickerMenu;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::TickerMenu> is a subclass of C<Gtk::Menu>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            App::Chart::Gtk2::TickerMenu

=head1 DESCRIPTION

A C<App::Chart::Gtk2::TickerMenu> shows the following things which can be done
from a symbol in the ticker.  It's split out from the main Ticker code to
keep the size there down and since it may not be needed at all if not used.

    +----------+
    | Refresh  |    update quotes
    | Symbols  |    the symlist to display
    | Run      |    whether to scroll the ticker
    +----------+
    | <SYMBOL> |
    | Intraday |    view an intraday graph
    | Web >    |    web links from App::Chart::Gtk2::WeblinkMenu
    +----------+
    | Help     |
    | Quit     |    or hide
    +----------+

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::TickerMenu->new (key=>value,...) >>

Create and return a new C<App::Chart::Gtk2::TickerMenu> object.  Optional
key/value pairs set initial properties as per C<< Glib::Object->new >>.

=back

=head1 PROPERTIES

=over 4

=item C<symbol> (C<App::Chart::Gtk2::Job>, default undef)

The stock or commodity symbol string to show, or C<undef> if none.  This is
shown in a non-clickable entry in the menu.

=item C<ticker> (C<App::Chart::Gtk2::Ticker> object, default undef)

The ticker to act on.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Ticker>

=cut
