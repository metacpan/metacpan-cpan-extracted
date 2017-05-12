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

package App::Chart::Gtk2::TickerMain;
use 5.008;
use strict;
use warnings;
use Glib;
use Gtk2;
use List::Util qw(min max);
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::Symlist;
use App::Chart::Gtk2::Ticker;

# uncomment this to run the ### lines
#use Devel::Comments;


use Glib::Object::Subclass
  'Gtk2::Window',
  properties => [Glib::ParamSpec->object
                 ('ticker',
                  'ticker',
                  'Ticker widget (a App::Chart::Gtk2::Ticker) displayed.',
                  'App::Chart::Gtk2::Ticker',
                  'readable')
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->set_title (__('Chart: Ticker'));
  my $screen = $self->get_screen;
  $self->set_default_size ($screen->get_width * 0.9, -1);

  my $ticker = $self->{'ticker'} = App::Chart::Gtk2::Ticker->new;
  $ticker->signal_connect (menu_created => \&_do_menu_created);
  $ticker->show;
  $self->add ($ticker);
}

# 'menu-created' on ticker widget
sub _do_menu_created {
  my ($ticker, $menu) = @_;
  my $self = $ticker->get_toplevel;

  # remove the Hide item
  foreach my $item (grep {$_->get_name eq 'hide'} $menu->get_children) {
    $item->destroy;
  }

  # add a quit instead
  my $item = Gtk2::ImageMenuItem->new_from_stock
    ('gtk-quit', $menu->get_accel_group);
  $item->signal_connect (activate => \&_do_quit,
                         App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
  $item->show;
  $menu->append ($item);
}

# 'activate' on quit menu item
sub _do_quit {
  my ($item, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->destroy;
}

sub main {
  my ($class, $args) = @_;
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  Gtk2->init;

  require Gtk2::Ex::ErrorTextDialog::Handler;
  Glib->install_exception_handler
    (\&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler);
  {
    ## no critic (RequireLocalizedPunctuationVars)
    $SIG{'__WARN__'} = \&Gtk2::Ex::ErrorTextDialog::Handler::exception_handler;
  }
  my $self = $class->new;
  $self->{'ticker'}->set (symlist => args_to_symlist($args));
  $self->signal_connect (destroy => \&_do_destroy_main_quit);
  $self->show_all;
  Gtk2->main;
}

# 'destroy' signal handler on self, only for main()
sub _do_destroy_main_quit {
  Gtk2->main_quit;
}

sub args_to_symlist {
  my ($args) = @_;
  ### args_to_symlist(): $args

  if (@$args == 0) {
    # default favourites
    require App::Chart::Gtk2::Symlist::Favourites;
    return App::Chart::Gtk2::Symlist::Favourites->instance;
  }

  if (@$args == 1 && ref($args->[0])) {
    # single list
    return $args->[0];
  }

  my @symlists;
  my @consts;
  my $flush = sub {
    if (@consts) {
      ### Constructed: @consts
      require App::Chart::Gtk2::Symlist::Constructed;
      push @symlists, App::Chart::Gtk2::Symlist::Constructed->new (@consts);
      @consts = ();
    }
  };
  foreach my $arg (@$args) {
    if (ref $arg) {
      &$flush();
      push @symlists, $arg;

    } elsif ($arg =~ /[[*?]/) {
      &$flush();
      require App::Chart::Gtk2::Symlist::All;
      my $all = App::Chart::Gtk2::Symlist::All->instance;
      require App::Chart::Gtk2::Symlist::Glob;
      push @symlists, App::Chart::Gtk2::Symlist::Glob->new ($all, $arg);
    } else {
      push @consts, $arg;
    }
    &$flush();
  }

  my $symlist;
  if (@symlists > 1) {
    require App::Chart::Gtk2::Symlist::Join;
    $symlist = App::Chart::Gtk2::Symlist::Join->new (@symlists);
    $symlist->{'name'} = __('Command Line');
    $App::Chart::Gtk2::Symlist::instances{$symlist->key} = $symlist;
  } else {
    $symlist = $symlists[0];
  }
  ### final: $symlist
  return $symlist;
}

1;
__END__

=for stopwords toplevel Eg

=head1 NAME

App::Chart::Gtk2::TickerMain -- stock ticker as toplevel window

=for test_synopsis my ($symlist)

=head1 SYNOPSIS

 use App::Chart::Gtk2::TickerMain;
 App::Chart::Gtk2::TickerMain->main ($symlist)

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::TickerMain> is a subclass of C<Gtk2::Window>.

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::Window
            App::Chart::Gtk2::TickerMain

=head1 DESCRIPTION

A C<App::Chart::Gtk2::TickerMain> widget is a toplevel window with a
C<App::Chart::Gtk2::Ticker> widget to show scrolling stock quotes.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::TickerMain->main ($symbol_or_symlist,...) >>

...

=item C<< App::Chart::Gtk2::TickerMain->new (key=>value,...) >>

Create and return a C<App::Chart::Gtk2::TickerMain> widget.  Optional key/value
pairs set initial properties as per C<< Glib::Object->new >>.

The widget is not displayed, but can be using C<show> in the usual way.  Eg.

    my $toplevel = App::Chart::Gtk2::TickerMain->new (symlist => $symlist);
    $toplevel->show;

=back

=head1 PROPERTIES

=over 4

=item C<ticker> (read-only)

The child ticker widget displayed.

=back

=cut

