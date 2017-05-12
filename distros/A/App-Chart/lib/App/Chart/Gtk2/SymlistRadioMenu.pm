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

package App::Chart::Gtk2::SymlistRadioMenu;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2;

use App::Chart::Gtk2::Symlist;
use App::Chart::Gtk2::SymlistListModel (qw(COL_KEY COL_NAME));

# uncomment this to run the ### lines
#use Smart::Comments;

use Gtk2::Ex::MenuView;
use Glib::Object::Subclass
  'Gtk2::Ex::MenuView',
  signals => { activate => \&_do_activate,
               item_create_or_update => \&_do_item_create_or_update,
             },
  properties => [ Glib::ParamSpec->object
                  ('symlist',
                   'symlist',
                   'App::Chart::Gtk2::Symlist object selected, or undef.',
                   'App::Chart::Gtk2::Symlist',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  my $model = App::Chart::Gtk2::SymlistListModel->instance;

  # hack for extra constructed lists ...
  #
  my @symlists = grep {$_->isa('App::Chart::Gtk2::Symlist::Join')}
    values %App::Chart::Gtk2::Symlist::instances;
  if (@symlists) {
    @symlists = sort {$a->key cmp $b->key} @symlists;
    require Gtk2::Ex::TreeModelBits;
    my $store = Gtk2::ListStore->new
      (Gtk2::Ex::TreeModelBits::all_column_types ($model));
    my $pos = 0;
    foreach my $symlist (@symlists) {
      ###   extra: COL_KEY.' '.COL_NAME.' '.$symlist->key
      $store->insert_with_values ($pos++,
                                  COL_KEY, $symlist->key,
                                  COL_NAME, $symlist->name);
    }
    require Gtk2::Ex::ListModelConcat;
    $model = Gtk2::Ex::ListModelConcat->new (models => [ $store, $model ]);
  }

  $self->set (model => $model);
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

sub _do_item_create_or_update {
  my ($self, $item, $model, $path, $iter) = @_;
  ### SymlistRadioMenu _do_item_create_or_update: $item
  if (! $item) {
    my $group = ($self->get_children)[0];
    $item = Gtk2::RadioMenuItem->new_with_label($group,'');
  }
  ###   label: $item->get_child
  $item->get_child->set_text ($model->get_value ($iter, COL_NAME));
  return $item;
}

# 'activate' signal handler on items
sub _do_activate {
  my ($self, $item, $model, $path, $iter) = @_;
  if ($item->get_active) {
    my $key = $model->get_value ($iter, COL_KEY);
    $self->{'symlist'} = App::Chart::Gtk2::Symlist->new_from_key ($key);
    $self->notify ('symlist');
  }
}

sub set_symlist {
  my ($self, $symlist) = @_;
  ### SymlistRadioMenu set_symlist: $self->get_name." to ".($symlist||'[none]')
  if (($self->{'symlist'}||0) == ($symlist||0)) { return; }

  my $key = $symlist->key;
  my $model = $self->get('model');
  my $pos = liststore_find_pos
    ($model, sub { my ($model, $path, $iter) = @_;
                   return ($model->get_value($iter, COL_KEY) eq $key); });
  if (! defined $pos) {
    croak "SymlistRadioMenu: no such list for set_symlist: $key";
  }

  $self->{'symlist'} = undef;
  require Glib::Ex::FreezeNotify;
  { my $freezer = Glib::Ex::FreezeNotify->new ($self);
    if (my $item = $self->item_at_indices ($pos)) {
      $item->set_active (1);
    }
    $self->notify ('symlist');
  }
}

sub liststore_find_pos {
  my ($store, $subr) = @_;
  my $pos;
  $store->foreach (sub {
                     my ($store, $path, $iter) = @_;
                     if ($subr->($store, $path, $iter)) {
                       ($pos) = $path->get_indices;
                       return 1; # stop;
                     }
                     return 0; # continue;
                   });
  return $pos;
}

1;
__END__

=for stopwords symlists undef symlist programmatically

=head1 NAME

App::Chart::Gtk2::SymlistRadioMenu -- radio menu of symbol lists

=head1 SYNOPSIS

 use App::Chart::Gtk2::SymlistRadioMenu;
 my $menu = App::Chart::Gtk2::SymlistRadioMenu->new;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::SymlistRadioMenu> is a subclass of C<Gtk2::Ex::MenuView>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            Gtk2::Ex::MenuView
              App::Chart::Gtk2::SymlistRadioMenu

=head1 DESCRIPTION

A C<App::Chart::Gtk2::SymlistRadioMenu> displays a menu of the available symlists
with C<Gtk2::RadioMenuItem>s, allowing the user to select one of them.  The
currently selected list is in the C<symlist> property.

    +--------------+
    | * Alerts     |
    +--------------+
    |   Favourites |
    +--------------+
    |   All        |
    +--------------+
    |   Historical |
    +--------------+

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::SymlistRadioMenu->new (key=>value,...) >>

Create and return a new C<App::Chart::Gtk2::SymlistRadioMenu> object.  Optional
key/value pairs set initial properties as per C<< Glib::Object->new >>.

=back

=head1 PROPERTIES

=over 4

=item C<symlist> (C<App::Chart::Gtk2::Symlist>, default undef)

The currently selected symlist in the menu radio buttons, or undef for none
selected.  This changes when the user selects a new list, and it can also be
set programmatically.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Symlist>, L<Gtk2::Menu>, L<Gtk2::RadioMenuItem>

=cut
