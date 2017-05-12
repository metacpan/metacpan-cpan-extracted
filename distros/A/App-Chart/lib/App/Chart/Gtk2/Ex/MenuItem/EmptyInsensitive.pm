# a subclass of Gtk2::Menu can act on its attached parent item directly ...


# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Gtk2::Ex::MenuItem::EmptyInsensitive;
use 5.008;
use strict;
use warnings;
use Gtk2;
use List::Util;

use App::Chart::Glib::Ex::MoreUtils;
use Glib::Ex::SignalIds;



# 'notify' is a no-hooks signal, so can't use an emission hook to have just
# one handler installed.  The add and remove signals could be done that way
# though.  It'd depend whether the speed lost to seeing every emission was
# was the memory saving of just one handler setup.
#

# if nothing except tearoff and separators visible then consider empty
my @ignored_menuitem_classes = ('Gtk2::SeparatorMenuItem',
                                'Gtk2::TearoffMenuItem');

sub new {
  my ($class, $item) = @_;
  my $self = bless {}, $class;
  my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak($self);

  $self->{'item_ids'} = Glib::Ex::SignalIds->new
    ($item,
     $item->signal_connect ('notify::submenu' => \&_notify_submenu,
                            $ref_weak_self));
  _notify_submenu ($item, undef, $ref_weak_self);
  return $self;
}

# 'notify' of item "submenu" property, also called for initial setups
sub _notify_submenu {
  my ($item, $pspec, $ref_weak_self) = @_;
  my $submenu = $item->get_submenu;
  ### SubmenuInsensitive _notify_submenu: $submenu
  my $self = $$ref_weak_self || return;

  $self->{'submenu_ids'} = $submenu && do {
    Glib::Ex::SignalIds->new
        ($submenu,
         $submenu->signal_connect (add    => \&_add_or_remove_child,
                                   $ref_weak_self),
         $submenu->signal_connect (remove => \&_add_or_remove_child,
                                   $ref_weak_self))
      };
  _update_submenu_signals ($self, $item, $ref_weak_self);
}
# 'add' or 'remove' signals on submenu
sub _add_or_remove_child {
  my ($submenu, $subitem, $ref_weak_self) = @_;
  ### SubmenuInsensitive _add_or_remove_child
  my $self = $$ref_weak_self || return;
  my $item = $submenu->get_attach_widget || return;
  _update_submenu_signals ($self, $item, $ref_weak_self);
}

sub _update_submenu_signals {
  my ($self, $item, $ref_weak_self) = @_;
  my $submenu = $item->get_submenu;

  # could add or remove for the changed child, but it's easier to just redo
  # the lot the same as for initial setups
  $self->{'subitem_ids_array'} = $submenu && do {
    my @subitem_ids;
    foreach my $subitem ($submenu->get_children) {
      if (_is_ignored($subitem)) { next; }
      push @subitem_ids, Glib::Ex::SignalIds->new
        ($subitem,
         $subitem->signal_connect ('notify::visible' => \&_notify_visible,
                                   $ref_weak_self))
      }
    \@subitem_ids
  };
  _update_sensitive ($item);
}
# 'notify' of subitem "visible" property
sub _notify_visible {
  my ($subitem) = @_;
  ### SubmenuInsensitive _notify_visible
  my $submenu = $subitem->get_parent || return;
  my $item = $submenu->get_attach_widget || return;
  _update_sensitive ($item);
}

sub _update_sensitive {
  my ($item) = @_;
  ### SubmenuInsensitive _update_sensitive
  $item->set_sensitive (_want_sensitive ($item));
}
sub _want_sensitive {
  my ($item) = @_;
  my $submenu = $item->get_submenu || return 0;
  return List::Util::first { !_is_ignored($_)
                               && $_->visible } $submenu->get_children;
}
sub _is_ignored {
  my ($subitem) = @_;
  return List::Util::first {$subitem->isa($_)} @ignored_menuitem_classes;
}

1;
__END__

=for stopwords submenu Gtk ie

=head1 NAME

App::Chart::Gtk2::Ex::MenuItem::EmptyInsensitive -- menu item insensitive when submenu empty

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::MenuItem::EmptyInsensitive;

 my $item = Gtk2::MenuItem->new;
 App::Chart::Gtk2::Ex::MenuItem::EmptyInsensitive->setup ($item);

=head1 DESCRIPTION

C<App::Chart::Gtk2::Ex::MenuItem::EmptyInsensitive> sets up a C<Gtk2::MenuItem> so that
it's insensitive if its submenu is empty, or all the items are hidden, or
there's no submenu set at all.

Sensitivity updates with items added or removed from the submenu, or made
hidden or visible.  In Gtk 2.12 and the sensitivity is updated for a new
submenu, ie. C<set_submenu>, but in prior versions there's no signal when
that happens and you must call C<setup> below again.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::Ex::MenuItem::EmptyInsensitive->setup ($item) >>

Setup C<$item> to be insensitive if its submenu is empty.

=back

=head1 SEE ALSO

L<Gtk2::MenuItem>, L<Gtk2::Menu>

=cut
