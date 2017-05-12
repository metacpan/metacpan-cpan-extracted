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

package App::Chart::Gtk2::WatchlistSymbolMenu;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Gtk2::Symlist;
use App::Chart::Gtk2::Ex::ToplevelBits;

use Glib::Object::Subclass
  'Gtk2::Menu',
  properties => [ Glib::ParamSpec->string
                  ('symbol',
                   __('Symbol'),
                   'Stock or commodity symbol string.',
                   '', # default
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('symlist',
                   'symlist',
                   'The symlist the symbol is from.',
                   'App::Chart::Gtk2::Symlist',
                   Glib::G_PARAM_READWRITE),

                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  ### WatchlistSymbolMenu INIT_INSTANCE()
  {
    my $menu_title = $self->{'menu_title'} = Gtk2::Label->new ("X");
    $menu_title->set_alignment (0.5, 0);  # centre horizontally
    my $item = Gtk2::MenuItem->new;
    $item->add ($menu_title);
    $self->append ($item);
  }
  $self->append (Gtk2::SeparatorMenuItem->new);

  {
    my $item = Gtk2::ImageMenuItem->new_from_stock ('gtk-refresh');
    $item->set_tooltip_text (__('Download a new quote for this symbol'));
    $item->signal_connect (activate => \&_do_refresh);
    $self->append ($item);
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
  }
  {
    my $item = Gtk2::MenuItem->new_with_mnemonic (__('_Web'));
    $self->append ($item);
    require App::Chart::Gtk2::WeblinkMenu;
    my $weblinkmenu = $self->{'weblinkmenu'} = App::Chart::Gtk2::WeblinkMenu->new;
    $item->set_submenu ($weblinkmenu);
  }
  $self->show_all;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol') {
    my $symbol = $newval;
    $self->{'menu_title'}->set_text ($symbol);
    $self->{'menu_intraday'}->set_sensitive
      (App::Chart::Gtk2::WatchlistDialog::symbol_intraday_sensitive($symbol));
    $self->{'weblinkmenu'}->set (symbol => $symbol);
  }
}

# open the main chart display on the current symbol
sub _do_chart {
  my ($menuitem) = @_;
  my $self = $menuitem->get_ancestor (__PACKAGE__);
  require App::Chart::Gtk2::Main;
  my $main = App::Chart::Gtk2::Main->find_for_dialog ($self->{'watchlist'});
  $main->goto_symbol ($self->{'symbol'}, $self->{'symlist'});
  $main->present;
}

sub _do_refresh {
  my ($menuitem) = @_;
  my $self = $menuitem->get_ancestor (__PACKAGE__);
  require App::Chart::Gtk2::Job::Latest;
  App::Chart::Gtk2::Job::Latest->start ([$self->{'symbol'}]);
}

sub _do_intraday {
  my ($menuitem) = @_;
  my $self = $menuitem->get_ancestor(__PACKAGE__) || return;
  ### WatchlistSymbolMenu intraday: $self->{'symbol'}
  App::Chart::Gtk2::Ex::ToplevelBits::popup
      ('App::Chart::Gtk2::IntradayDialog',
       properties => { symbol => $self->get('symbol') },
       screen => $self);
}

sub popup_from_treeview {
  my ($class_or_self, $event, $treeview) = @_;
  my $self = ref $class_or_self ? $class_or_self : $class_or_self->new;

  my $watchlist = $treeview->get_toplevel;
  require Scalar::Util;
  Scalar::Util::weaken ($self->{'watchlist'} = $watchlist);

  my ($path) = $treeview->get_path_at_pos ($event->x, $event->y);
  if (! $path) { return; }

  my $model = $treeview->get_model;  # App::Chart::Gtk2::WatchlistModel
  my $symlist = $model->get_symlist;
  my $iter = $symlist->get_iter ($path);
  my $symbol = $symlist->get_value ($iter, $model->COL_SYMBOL);
  $self->set (symbol => $symbol,
              symlist => $symlist);
  $self->set_screen ($treeview->get_screen);
  $self->popup (undef, undef, undef, undef, $event->button, $event->time);
}

1;
__END__

=for stopwords watchlist Watchlist WatchlistSymbolMenu Popup undef clickable symlist

=head1 NAME

App::Chart::Gtk2::WatchlistSymbolMenu -- menu for watchlist symbol

=for test_synopsis my ($event, $treeview)

=head1 SYNOPSIS

 use App::Chart::Gtk2::WatchlistSymbolMenu;
 App::Chart::Gtk2::WatchlistSymbolMenu->popup_from_treeview ($event, $treeview);

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::WatchlistSymbolMenu> is a subclass of C<Gtk::Menu>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            App::Chart::Gtk2::WatchlistSymbolMenu

=head1 DESCRIPTION

A C<App::Chart::Gtk2::WatchlistSymbolMenu> shows the following things which can be
done from a symbol in the Watchlist.  It's split out from the main Watchlist
code to keep the size there down and since it may not be needed at all if
not used.

    +----------+
    | <SYMBOL> |
    +----------+
    | Chart    |    view the full chart
    | Refresh  |    get a new quote
    | Intraday |    view an intraday graph
    | Web >    |    web links from App::Chart::Gtk2::WeblinkMenu
    +----------+

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::WatchlistSymbolMenu->new (key=>value,...) >>

Create and return a new C<App::Chart::Gtk2::WatchlistSymbolMenu> object.  Optional
key/value pairs set initial properties as per C<< Glib::Object->new >>.

=item C<< App::Chart::Gtk2::WatchlistSymbolMenu->popup_from_treeview ($event, $treeview) >>

=item C<< $wsmenu->popup_from_treeview ($event, $treeview) >>

Popup the given C<$wsmenu>, or as a class method create and popup a new
menu, in both cases for the symbol under the mouse pointer in C<$treeview>.

C<$event> should be a C<Gtk2::Gdk::Event> giving the mouse position and the
model in C<$treeview> is expected to be a C<App::Chart::Gtk2::WatchlistModel>.

=back

=head1 PROPERTIES

=over 4

=item C<symbol> (C<App::Chart::Gtk2::Job>, default undef)

The stock or commodity symbol string to be acted on by the menu.  This is
shown in a non-clickable entry in the menu.

=item C<symlist> (C<App::Chart::Gtk2::Symlist> object, default undef)

The symlist the C<symbol> is from.  This is only used for the "Chart" menu
item to give a symlist to the main view so Next/Prev will go from within
that symlist.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::WatchlistDialog>, L<App::Chart::Gtk2::Symlist>

=cut
