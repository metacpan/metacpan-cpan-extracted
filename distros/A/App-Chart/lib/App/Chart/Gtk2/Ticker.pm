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

package App::Chart::Gtk2::Ticker;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2 1.200; # for working TreeModelFilter modify_func
use Gtk2::Ex::TickerView;
use List::Util qw(min max);
use Locale::TextDomain 'App-Chart';

use App::Chart::Glib::Ex::MoreUtils;
use Glib::Ex::SignalIds;
use Gtk2::Ex::Units;
use App::Chart;
use App::Chart::Gtk2::GUI;
use App::Chart::Gtk2::Symlist;

# uncomment this to run the ### lines
#use Smart::Comments;

BEGIN {
  Glib::Type->register_enum ('App::Chart::Gtk2::Ticker::menu_position',
                             'centre'  => 0,
                             'pointer' => 1);
}
use Glib::Object::Subclass
  'Gtk2::Ex::TickerView',
  signals => { button_press_event => \&_do_button_press_event,

               menu_created => { param_types => ['Gtk2::Menu'],
                                 return_type => undef,
                               },
               menu_popup => { param_types   => ['Glib::Int',
                                                 'App::Chart::Gtk2::Ticker::menu_position'],
                               return_type   => undef,
                               class_closure => \&_do_menu_popup_action,
                               flags         => [ 'run-last', 'action' ],
                             },
             },
  properties => [Glib::ParamSpec->object
                 ('symlist',
                  'symlist',
                  'App::Chart::Gtk2::Symlist object for the symbols to display.',
                  # App::Chart::Gtk2::Symlist::Join is a ListModelConcat not
                  # a Symlist subclass, allow that by just Glib::Object here
                  'Glib::Object',
                  Glib::G_PARAM_READWRITE),
                ];
App::Chart::Gtk2::GUI::chart_style_class (__PACKAGE__);

# priority level "gtk" treating this as widget level default, for overriding
# by application or user RC
Gtk2::Rc->parse_string (<<'HERE');
binding "App__Chart__Gtk2__Ticker_keys" {
  bind "F10"             { "menu_popup" (0, centre) }
  bind "Pointer_Button3" { "menu_popup" (3, pointer) }
}
class "App__Chart__Gtk2__Ticker" binding:gtk "App__Chart__Gtk2__Ticker_keys"
HERE

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->add_events (['button-press-mask', 'key-press-mask']);
  $self->set (fixed_height_mode => 1);
  $self->set_flags ('can-focus');

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (xpad => Gtk2::Ex::Units::em($self));
  $self->pack_start ($renderer, 0);
  $self->set_attributes ($renderer, markup => 0);

  require App::Chart::Gtk2::Symlist::Favourites;
  my $symlist = App::Chart::Gtk2::Symlist::Favourites->instance;
  if ($symlist->is_empty) {
    require App::Chart::Gtk2::Symlist::All;
    my $all = App::Chart::Gtk2::Symlist::All->instance;
    if (! $all->is_empty) {
      $symlist = $all;
    }
  }
  $self->set (symlist => $symlist);
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  # Gtk2::Menu doesn't go away just by weakening if currently popped-up
  # (because it's then a toplevel presumably); doing ->popdown() works, but
  # ->destroy() seems the best idea
  if (my $menu = $self->{'menu'}) {
    $menu->destroy;
  }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $oldval = $self->{$pname};

  if ($pname eq 'symlist' && ($newval||0) != ($oldval||0)) {
    ### Ticker: "$self changed symlist"
    my $symlist = $newval;
    if (defined $symlist && ! $symlist->isa('App::Chart::Gtk2::Symlist')) {
      croak "App::Chart::Gtk2::Ticker.symlist must be a App::Chart::Gtk2::Symlist";
    }
    $self->{$pname} = $newval;  # per default GET_PROPERTY

    require App::Chart::Gtk2::TickerModel;
    my $model = $self->{'symlist_model'}
      = $symlist && App::Chart::Gtk2::TickerModel->new ($symlist);

    my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak ($self);
    $self->{'symlist_model_ids'} = $model && do {
      Glib::Ex::SignalIds->new
          ($model,
           $model->signal_connect (row_deleted => \&_do_row_deleted,
                                   $ref_weak_self),
           $model->signal_connect (row_inserted => \&_do_row_inserted,
                                   $ref_weak_self))
        };

    $self->set (model => $model);
    $self->{'showing_empty'} = 0;
    _check_empty ($self);

  } else {
    $self->{$pname} = $newval;  # per default GET_PROPERTY
  }
}

# 'button-press-event' class closure
sub _do_button_press_event {
  my ($self, $event) = @_;
  require App::Chart::Gtk2::Ex::BindingBits;
  App::Chart::Gtk2::Ex::BindingBits::activate_button_event
      ('App__Chart__Gtk2__Ticker_keys', $event, $self);
  return shift->signal_chain_from_overridden(@_);
}

# 'menu-popup' action signal class closure
sub _do_menu_popup_action {
  my ($self, $button, $where) = @_;
  ### Ticker: "menu-popup action $button $where"

  my $position_func; # undef for mouse position if $where empty or undef
  if ($where && $where ne 'pointer') {
    $position_func = $self->can("menu_position_func_$where");
    unless ($position_func) {
      Glib->warning (undef, warn "Ticker: unrecognised menu position '$where', default to mouse pointer");
    }
  }
  my $symbol;
  if (! $where || $where eq 'pointer') {
    my $event = Gtk2->get_current_event;
    require Gtk2::Ex::WidgetBits;
    if (my ($x,$y) = Gtk2::Ex::WidgetBits::xy_root_to_widget ($self,
                                                              $event->x_root,
                                                              $event->y_root)) {
      if (my $path = $self->get_path_at_pos ($x, $y)) {
        if (my $model = $self->get('symlist')) {
          if (my $iter = $model->get_iter ($path)) {
            $symbol = $model->get($iter, $model->COL_SYMBOL);
          }
        }
      }
    }
  }
  my $menu = $self->menu;
  $menu->set_screen ($self->get_screen);
  $menu->set (symbol => $symbol);
  $menu->popup (undef,  # parent menushell
                undef,  # parent menuitem
                $position_func,
                App::Chart::Glib::Ex::MoreUtils::ref_weak($self),  # position func data
                $button,
                Gtk2->get_current_event_time);
}

# 'row-deleted' signal on symlist model
sub _do_row_deleted {
  my ($model, $path, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  _check_empty ($self);
}
# 'row-inserted' signal on symlist model
sub _do_row_inserted {
  my ($model, $path, $iter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  _check_empty ($self);
}
sub _check_empty {
  my ($self) = @_;
  my $symlist = $self->{'symlist'};
  my $empty = !$symlist || $symlist->is_empty;

  if ($empty && ! $self->{'showing_empty'}) {
    # become empty
    my $empty_model = ($self->{'empty_model'} ||= do {
      my $liststore = Gtk2::ListStore->new ('Glib::String');
      $liststore->append;
      $liststore;
    });
    my $message = $symlist
      ? __x('{symlistname} list is empty ... ',
            symlistname => $symlist->name)
        : __('No symlist ... ');
    $empty_model->set_value ($empty_model->get_iter_first,
                             0 => $message);
    $self->set (model => $empty_model);
    $self->{'showing_empty'} = 1;

  } elsif ($self->{'showing_empty'} && ! $empty) {
    $self->set (model => $self->{'symlist_model'});
    $self->{'showing_empty'} = 0;
  }
}

# create and return Gtk2::Menu widget
sub menu {
  my ($self) = @_;
  return ($self->{'menu'} ||= do {
    ### Ticker menu doesn't exist, creating
    require App::Chart::Gtk2::TickerMenu;
    my $menu = App::Chart::Gtk2::TickerMenu->new (ticker => $self);
    $self->signal_emit ('menu-created', $menu);
    $menu;
  });
}

# and also 'activate' signal on Help menu item
sub help {
  require App::Chart::Manual;
  App::Chart::Manual->open(__p('manual-node','Ticker'));
}

#------------------------------------------------------------------------------
# position funcs

sub menu_position_func_centre {
  require Gtk2::Ex::MenuBits;
  goto &Gtk2::Ex::MenuBits::position_widget_topcentre;
}


1;
__END__

=for stopwords symlist submenu Symlist boolean ie

=head1 NAME

App::Chart::Gtk2::Ticker -- stock ticker widget

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ticker;
 my $ticker = App::Chart::Gtk2::Ticker->new;

 my $symlist = App::Chart::Gtk2::Symlist::All->instance;
 $ticker->set (symlist => $symlist);

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::Ticker> is a subclass of C<Gtk2::Ex::TickerView>,

    Gtk2::Widget
      ...
        Gtk2::Ex::TickerView
          App::Chart::Gtk2::Ticker

=head1 DESCRIPTION

A C<App::Chart::Gtk2::Ticker> widget showing stock quotes scrolling across the
window for a given symlist (L<App::Chart::Gtk2::Symlist>)

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ticker->new (key => value, ...) >>

Create and return a C<App::Chart::Gtk2::Ticker> widget.  Optional key/value pairs
can be given to set initial properties as per C<< Glib::Object->new >>.

=item C<< $ticker->menu() >>

Return the C<Gtk2::Menu> which is popped up by mouse button 3 in the ticker.
An application can add items to this, such as "Hide" or "Quit", or perhaps a
submenu to change what's displayed.

=item C<< $ticker->refresh() >>

Download fresh prices for the symbols displayed.  This is the "Refresh" item
in the button-3 menu.

=item C<< $ticker->help() >>

Open the Chart manual at the section on the ticker.  This is the "Help" item
in the button-3 menu.

=back

=head1 PROPERTIES

=over 4

=item symlist (C<App::Chart::Gtk2::Symlist>, default favourites or all)

A Symlist object which is the stock symbols to display.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::TickerMain>, L<App::Chart::Gtk2::Symlist>, C<Gtk2::Ex::TickerView>

=cut

