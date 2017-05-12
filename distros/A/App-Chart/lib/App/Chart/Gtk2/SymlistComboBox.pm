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

package App::Chart::Gtk2::SymlistComboBox;
use 5.010;
use strict;
use warnings;
use Carp;
use Gtk2;
use App::Chart::Gtk2::Symlist;

use Glib::Object::Subclass
  'Gtk2::ComboBox',
  signals => { changed => \&_do_changed },
  properties => [ Glib::ParamSpec->object
                  ('symlist',
                   'symlist',
                   'The symlist selected.',
                   'App::Chart::Gtk2::Symlist',
                   Glib::G_PARAM_READWRITE)
                ];

sub INIT_INSTANCE {
  my ($self) = @_;

  require App::Chart::Gtk2::SymlistListModel;
  my $model = App::Chart::Gtk2::SymlistListModel->instance;
  $self->set (model => $model,
              active => 0);

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (ypad => 0);
  $self->pack_start ($renderer, 1);
  $self->set_attributes ($renderer, text => $model->COL_NAME);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;

  if ($pname eq 'symlist') {
    if (defined $newval) {
      $newval->isa('App::Chart::Gtk2::Symlist') or croak 'Not a App::Chart::Gtk2::Symlist';
    }
  }

  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symlist') {
    my $symlist = $newval;
    my $pos = -1;
    if (defined $symlist) {
      my $key = $symlist->key;
      my $model = $self->get_model;
      $pos = $model->key_to_pos ($key);
    }
    $self->set_active ($pos);
  }
}

# 'changed' class closure
sub _do_changed {
  my ($self) = @_;
  ### SymlistComboBox _do_changed()
  my $model = $self->get_model;
  my $iter = $self->get_active_iter;
  my $key = $iter && $model->get_value ($iter, $model->COL_KEY);
  ### to key: $key
  my $new_symlist = $key && App::Chart::Gtk2::Symlist->new_from_key ($key);
  if (($new_symlist//0) != ($self->{'symlist'}//0)) {
    $self->{'symlist'} = $new_symlist;
    $self->notify('symlist');
  }
  return shift->signal_chain_from_overridden(@_);
}

1;
__END__

=for stopwords combobox symlist symlists ComboBox programmatically

=head1 NAME

App::Chart::Gtk2::SymlistComboBox -- combobox symlist selector

=head1 SYNOPSIS

 use App::Chart::Gtk2::SymlistComboBox;
 my $combobox = App::Chart::Gtk2::SymlistComboBox->new;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::SymlistComboBox> is a subclass of C<Gtk2::ComboBox>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ComboBox
            App::Chart::Gtk2::SymlistComboBox

=head1 DESCRIPTION

C<App::Chart::Gtk2::SymlistComboBox> displays the available symlists, as a
convenient combination of C<Gtk2::ComboBox> and
C<App::Chart::Gtk2::SymlistListModel>.  The C<symlist> property changes according
to the list selected.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Gtk2::SymlistComboBox->new (key=>value,...) >>

Create and return a new C<App::Chart::Gtk2::SymlistComboBox> object.  Optional
key/value pairs set initial properties as per C<< Glib::Object->new >>.

=back

=head1 PROPERTIES

=over 4

=item C<symlist> (C<App::Chart::Gtk2::Symlist> object, default first symlist)

The current symlist selected in the ComboBox.  This changes with the user's
choice, and can be set programmatically to update the ComboBox display.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::Symlist>

=cut
