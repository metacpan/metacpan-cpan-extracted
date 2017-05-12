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


#   return ($self->{'symbol_history'} ||= do {
#     require App::Chart::SymbolHistory;
#     my $history = App::Chart::SymbolHistory->new
#       (back_action    => $self->{'actiongroup'}->get_action('Back'),
#        forward_action => $self->{'actiongroup'}->get_action('Forward'),
#        back_button    => $self->{'ui'}->get_widget("/ToolBar/Back"),
#        forward_button => $self->{'ui'}->get_widget("/ToolBar/Forward"));
#     $history->signal_connect
#       (menu_activate => \&_do_symbol_history_menu_activate, $self);
#     $history;
#   });
# sub _do_symbol_history_menu_activate {
#   my ($history, $symbol, $symlist, $self) = @_;
#   $self->goto_symbol ($symbol, $symlist);
# }

  #   $actiongroup->get_action('Back')->set_sensitive (0);
  #   $actiongroup->get_action('Forward')->set_sensitive (0);




package App::Chart::SymbolHistory;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use Scalar::Util;
use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart;

# set this to 1 for some diagnostic prints
use constant DEBUG => 0;

use constant MAX_HISTORY => 40;


use Glib::Object::Subclass
  'Glib::Object',
  signals => { menu_activate => { param_types => ['Glib::String',
                                                  'Glib::Scalar'],
                                  return_type => undef },
             },
  properties => [ Glib::ParamSpec->object
                  ('back-action',
                   'back-action',
                   'Blurb.',
                   'Glib::Object',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('forward-action',
                   'forward-action',
                   'Blurb.',
                   'Glib::Object',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('back-button',
                   'back-button',
                   'Blurb.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('forward-button',
                   'forward-button',
                   'Blurb.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),
                ];

use constant { COL_SYMBOL => 0,
               COL_SYMLIST => 1 };


#------------------------------------------------------------------------------

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'back_model'} = Gtk2::ListStore->new ('Glib::String','Glib::Scalar');
  $self->{'forward_model'} = Gtk2::ListStore->new ('Glib::String','Glib::Scalar');
  $self->{'current'} = undef;
  App::Chart::chart_dirbroadcast()->connect_for_object
      ('delete-symbol', \&_do_delete_symbol, $self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak ($self);

  if ($pname eq 'forward_button') {
    my $button = $newval;
    if ($button->isa ('Gtk2::ToolButton')) {
      $button = $button->get_child;
    }
    $button->signal_connect (button_press_event => \&_do_forward_button_press,
                             $ref_weak_self);

  } elsif ($pname eq 'back_button') {
    my $button = $newval;
    if ($button->isa ('Gtk2::ToolButton')) {
      $button = $button->get_child;
    }
    $button->signal_connect (button_press_event => \&_do_back_button_press,
                             $ref_weak_self);
  }
}

# 'button-press-event' handler on the back button
sub _do_back_button_press {
  my ($button, $event, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if ($button->sensitive && $event->button == 3) {
    $self->back_menu->popup (undef,undef,undef,undef,
                             $event->button, $event->time);
  }
  return Gtk2::EVENT_PROPAGATE;
}

# 'button-press-event' handler on the forward button
sub _do_forward_button_press {
  my ($button, $event, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  if ($button->sensitive && $event->button == 3) {
    $self->forward_menu->popup (undef,undef,undef,undef,
                                $event->button, $event->time);
  }
  return Gtk2::EVENT_PROPAGATE;
}

sub goto {
  my ($self, $symbol, $symlist) = @_;
  if (DEBUG) { print "SymbolHistory goto $symbol $symlist\n"; }

  if ($self->{'current_symbol'}
      && $symbol ne $self->{'current_symbol'}) {
    if (DEBUG) { print "  push back ",$self->{'current_symbol'},
                   " ",$self->{'current_symlist'},"\n"; }
    my $back_model = $self->{'back_model'};
    $back_model->insert_with_values
      (0,
       COL_SYMBOL,  $self->{'current_symbol'},
       COL_SYMLIST, $self->{'current_symlist'});
    _update_actions ($self);
    _limit ($back_model);
  } else {
    if (DEBUG) { print "  skip same as current\n"; }
  }
  $self->{'current_symbol'} = $symbol;
  $self->{'current_symlist'} = $symlist;
}

sub back {
  my ($self) = @_;
  my $back_model = $self->{'back_model'};
  my $iter = $back_model->get_iter_first;
  if (! $iter) { return (undef, undef); }

  if (defined $self->{'current_symbol'}) {
    my $forward_model = $self->{'forward_model'};
    $forward_model->insert_with_values
      (0,
       COL_SYMBOL, $self->{'current_symbol'},
       COL_SYMLIST, $self->{'current_symlist'});
    _limit ($forward_model);
  }

  my $symbol = $back_model->get_value ($iter, COL_SYMBOL);
  my $symlist = $back_model->get_value ($iter, COL_SYMLIST);
  $back_model->remove ($iter);
  _update_actions ($self);

  if (DEBUG) { print "SymbolHistory back to $symbol $symlist\n"; }
  return ($self->{'current_symbol'} = $symbol,
          $self->{'current_symlist'} = $symlist);
}

sub forward {
  my ($self) = @_;
  my $forward_model = $self->{'forward_model'};
  my $iter = $forward_model->get_iter_first;
  if (! $iter) { return (undef, undef); }

  my $symbol = $forward_model->get_value ($iter, COL_SYMBOL);
  my $symlist = $forward_model->get_value ($iter, COL_SYMLIST);
  $forward_model->remove ($iter);
  _update_actions ($self);

  if (DEBUG) { print "SymbolHistory forward to $symbol $symlist\n"; }
  $self->goto ($symbol, $symlist);
  return ($self->{'current_symbol'},
          $self->{'current_symlist'});
}

# set the 'forward-action' and 'back-action' objects sensitive or not
# according to there being something to go forward or back to
sub _update_actions {
  my ($self) = @_;
  if (my $action = $self->{'forward_action'}) {
    my $model = $self->{'forward_model'};
    $action->set_sensitive ($model->get_iter_first);
  }
  if (my $action = $self->{'back_action'}) {
    my $model = $self->{'back_model'};
    $action->set_sensitive ($model->get_iter_first);
  }
}

# enforce MAX_HISTORY on the given liststore model
# if it's too big then remove elements from the end
sub _limit {
  my ($model) = @_;
  my $len = $model->iter_n_children (undef);
  for (my $pos = $len - 1; $pos >= MAX_HISTORY; $pos--) {
    $model->remove ($model->iter_nth_child (undef, $pos));
  }
}

# 'delete-symbol' notify handler
sub _do_delete_symbol {
  my ($self, $symbol) = @_;
  foreach my $model ($self->{'back_model'}, $self->{'forward_model'}) {
    require Gtk2::Ex::TreeModelBits;
    Gtk2::Ex::TreeModelBits::remove_matching_rows
        ($model, sub {
           my ($model, $iter) = @_;
           return ($model->get_value ($iter, COL_SYMBOL) eq $symbol);
         });
  }
}

#------------------------------------------------------------------------------
# menu

sub back_menu {
  my ($self) = @_;
  return _make_menu ($self, 'back_menu', 'back_model',
                     __('Chart: Back'));
}
sub forward_menu {
  my ($self) = @_;
  return _make_menu ($self, 'forward_menu', 'forward_model',
                     __('Chart: Forward'));
}
sub _make_menu {
  my ($self, $menu_key, $model_key, $tearoff_title) = @_;
  return ($self->{$menu_key} ||= do {
    require Gtk2::Ex::MenuView;
    require Gtk2::Ex::Dashes::MenuItem;
    my $menuview = Gtk2::Ex::MenuView->new
      (model          => $self->{$model_key},
#        tearoff_items  => 'top',
#        tearoff_title  => $tearoff_title,
#        tearoff_type   => 'Gtk2::Ex::Dashes::MenuItem',
      );
    $menuview->signal_connect
      (item_create_or_update => \&_do_item_create_or_update);
    $menuview->signal_connect
      (activate => \&_do_menu_activate, App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
#     $menuview->signal_connect
#       (tearoff => \&_do_menu_tearoff, App::Chart::Glib::Ex::MoreUtils::ref_weak($self));
    $menuview;
  });
}

# MenuView 'tearoff'
# sub _do_menu_tearoff {
#   my ($menuview, $ref_weak_self) = @_;
#   my $self = $$ref_weak_self || return;
#   require App::Chart::BrowseHistoryDialog;
#   my $dialog = App::Chart::BrowseHistoryDialog->new
#     (back_model    => $self->{'back_model'},
#      forward_model => $self->{'forward_model'});
#   $dialog->present;
# }

# MenuView 'item-create-or-update'
sub _do_item_create_or_update {
  my ($menuview, $item, $model, $path, $iter) = @_;
  $item ||= Gtk2::MenuItem->new_with_label ('');
  $item->show;
  my $symbol = $model->get_value ($iter, COL_SYMBOL);
  require App::Chart::Database;
  my $name = App::Chart::Database->symbol_name ($symbol);
  $item->get_child->set_text ($symbol . ($name ? ' - ' . $name : ''));
  return $item;
}

sub _do_menu_activate {
  my ($menuview, $model, $path, $iter, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  my ($pos) = $path->get_indices;
  if ($model == $self->{'back_model'}) {
    foreach (0 .. $pos) { $self->back; }
  } else {
    foreach (0 .. $pos) { $self->forward; }
  }
  $self->signal_emit ('menu_activate',
                      $self->{'current_symbol'},
                      $self->{'current_symlist'})
}

1;
__END__

=for stopwords symlist undef

=head1 NAME

App::Chart::SymbolHistory -- previously visited symbols

=head1 SYNOPSIS

 use App::Chart::SymbolHistory;
 my $history = App::Chart::SymbolHistory->new;

=head1 OBJECT HIERARCHY

C<App::Chart::SymbolHistory> is a subclass of C<Glib::Object>.

    Glib::Object
      App::Chart::SymbolHistory

=head1 DESCRIPTION

A C<App::Chart::SymbolHistory> object records a history of visited symbol and
symlist, allowing navigation back or forward in the list.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::SymbolHistory->new >>

Create and return a new symbol history object.

=cut

=item C<< $history->goto ($symbol, $symlist) >>

Add symbol+symlist to C<$history> as the currently viewed position.  If this
is different than previously noted then that previous symbol+symlist is
added to the "back" list.

=item C<< $history->back() >>

=item C<< $history->forward() >>

Go back or forward in C<$history>.  The return is values C<($symbol,
$symlist)> which is where to go to, or C<(undef,undef)> if nothing further
to go to.

=item C<< $history->back_menu >>

=item C<< $history->forward_menu >>

Return a C<Gtk2::Menu> of symbols to go back or forward to.

=back

=head1 PROPERTIES

=over 4

=item C<back-action> (C<Gtk2::Action>, default undef)

=item C<forward-action> (C<Gtk2::Action>, default undef)

Action objects to be set sensitive or insensitive according to whether
there's anything to go back or forward to.

=back

=head1 SIGNALS

=over 4

=item C<menu-activate> (parameters: history, symbol, symlist)

Emitted when an item symbol+symlist is selected from the back or forward
menus (as created by the C<back_menu> etc functions above).

=back

=head1 SEE ALSO

L<Gtk2::Ex::MenuView>

=cut
