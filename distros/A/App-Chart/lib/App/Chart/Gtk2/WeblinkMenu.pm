# Copyright 2007, 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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

package App::Chart::Gtk2::WeblinkMenu;
use 5.010;
use strict;
use warnings;
use Glib;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use Glib::Ex::ObjectBits 'set_property_maybe';;
use Glib::Ex::ConnectProperties 13;  # v.13 for model-rows
use Gtk2::Ex::MenuView;

use App::Chart::Weblink;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::Ex::MenuView',
  signals => { activate  => \&_do_activate,
               item_create_or_update => \&_do_item_create_or_update,
               notify => \&_do_notify },
  properties => [Glib::ParamSpec->string
                 ('symbol',
                   __('Symbol'),
                  'The stock or commodity symbol to display weblinks for.',
                  '',  # default
                  Glib::G_PARAM_READWRITE)];


sub INIT_INSTANCE {
  my ($self) = @_;
  ### WeblinkMenu INIT_INSTANCE()
  $self->set (model => Gtk2::ListStore->new ('Glib::Scalar'));
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### WeblinkMenu SET_PROPERTY(): $pname
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  # $pname eq 'symbol'
  _update_model_contents ($self);
  _update_parent_sensitive ($self);
}

sub _do_notify {
  my ($self, $pspec) = @_;
  ### WeblinkMenu _do_notify: $pspec->get_name
  if ($pspec->get_name eq 'attach_widget') {
    my $parent = $self->get_attach_widget;
    ### attached: "$parent"
    ### model: $self->get('model')
    $self->{'connp'} = Glib::Ex::ConnectProperties->dynamic
      ([$self->get('model'), 'model-rows#not-empty'],
       [$parent, 'sensitive']);
  }
  # return shift->signal_chain_from_overridden(@_);
}

sub _update_model_contents {
  my ($self) = @_;
  ### WeblinkMenu _update_model_contents()
  my $model = $self->get('model');
  my $symbol = $self->get('symbol');
  my $i = 0;
  if (defined $symbol) {
    foreach my $weblink (App::Chart::Weblink->links_for_symbol ($symbol)) {
      my $iter = $model->iter_nth_child(undef,$i++) || $model->append;
      $model->set ($iter, 0 => $weblink);
    }
  }
  while (my $iter = $model->iter_nth_child(undef,$i)) {
    $model->remove ($iter);
  }
}
sub _update_parent_sensitive {
  my ($self) = @_;
  return;

  ### WeblinkMenu _update_parent_sensitive: $self->get_attach_widget
  my $parent_item = $self->get_attach_widget || return;
  my $model = $self->get('model');
  $parent_item->set_sensitive ($model->get_iter_first);
}

# 'item-create-or-update' class closure handler
sub _do_item_create_or_update {
  my ($self, $item, $model, $path, $iter) = @_;
  my $weblink = $model->get_value ($iter, 0);
  if (! $item) {
    $item = Gtk2::MenuItem->new_with_label ('');
    $item->show;
  }
  $item->get_child->set_text_with_mnemonic ($weblink->name);
  set_property_maybe
    ($item,
     sensitive      => $weblink->sensitive($self->get('symbol')),
     # tooltip-markup new in 2.12
     tooltip_markup => Glib::Markup::escape_text($weblink->{'desc'} || ''));
  return $item;
}

# 'activate' class closure
sub _do_activate {
  my ($self, $item, $model, $path, $iter) = @_;
  my $weblink = $model->get_value ($iter, 0);
  my $symbol = $self->get('symbol');
  $weblink->open ($symbol);
}

1;
__END__

=for stopwords weblinks weblink WeblinkMenu

=head1 NAME

App::Chart::Gtk2::WeblinkMenu -- menu of weblinks for stock symbol

=head1 SYNOPSIS

 use App::Chart::Gtk2::WeblinkMenu;
 my $menu = App::Chart::Gtk2::WeblinkMenu->new;

=head1 DESCRIPTION

A App::Chart::Gtk2::WeblinkMenu widget displays a menu of the weblinks (see
L<App::Chart::Weblink>) for a given stock symbol.  Clicking on one of the
menu items opens the corresponding weblink in a browser as per
C<< $weblink->open >>.

    +---------------------------+
    | FOOEX Company Information |
    | Google Stock Page         |
    | Yahoo Stock Page          |
    +---------------------------+

Any parent menu item holding the WeblinkMenu is set sensitive or insensitive
according to whether there's weblinks for the given symbol, including
insensitive when the symbol is the empty string.

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::WeblinkMenu> is a subclass of C<Gtk2::Menu>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            App::Chart::Gtk2::WeblinkMenu

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::WeblinkMenu->new (key=>value,...) >>

Create and return a new C<App::Chart::Gtk2::WeblinkMenu> object.  Optional
key/value pairs can be given to set initial properties as per
C<< Glib::Object->new >>.

=back

=head1 PROPERTIES

=over 4

=item C<symbol> (string, default empty "")

The stock or commodity symbol (a string) to display links for.  This can be
an empty string "" for no symbol (and hence no links showing).

=back

=head1 SEE ALSO

L<App::Chart::Weblink>, L<Gtk2::Menu>, L<Gtk2::MenuItem>

=cut
