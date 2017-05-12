# Copyright 2008, 2009, 2010, 2011, 2013, 2014 Kevin Ryde

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

package App::Chart::Gtk2::IndicatorComboBox;
use 5.010;
use strict;
use warnings;
use Module::Load;
use Gtk2;

use App::Chart;

use Glib::Object::Subclass
  'Gtk2::ComboBox',
  signals => { changed => \&_do_changed },
  properties => [Glib::ParamSpec->string
                 ('key',
                  'key',
                  'Blurb.',
                  '',
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('type',
                  'type',
                  'Blurb.',
                  '',
                  Glib::G_PARAM_READWRITE),
                ];

Gtk2::Rc->parse_string (<<'HERE');
style "App__Chart__Gtk2__GUI_appears_as_list_style" {
  GtkComboBox::appears-as-list = 1
}
class "App__Chart__Gtk2__IndicatorComboBox" style:gtk "App__Chart__Gtk2__GUI_appears_as_list_style"
HERE

sub INIT_INSTANCE {
  my ($self) = @_;

  require App::Chart::Gtk2::IndicatorModel;
  my $model = App::Chart::Gtk2::IndicatorModel->instance;
  $self->set_model ($model);
  $self->set (active => 0,
              add_tearoffs => 1);

  my $renderer = Gtk2::CellRendererText->new;
  $self->pack_start ($renderer, 0);
  $self->set_attributes ($renderer, text => $model->{'COL_NAME'});
}

# 'changed' class closure from Gtk2::ComboBox
sub _do_changed {
  my ($self) = @_;
  $self->signal_chain_from_overridden;
  $self->notify ('key');
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  if ($pspec->get_name eq 'key') {
    return $self->get_key;
  } else {
    return $self->{$pname};
  }
}
sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'key') {
    $self->set_key ($newval);
  } elsif ($pname eq 'type') {
    my $type = $self->{'type'} = $newval;
    my $key = $self->get_key;
    $self->set_model (App::Chart::Gtk2::IndicatorModel->by_type($type));
    $self->set_key ($key);
  }
}
sub get_key {
  my ($self) = @_;
  my $iter = $self->get_active_iter || return undef;
  my $model = $self->get_model;
  $model->get ($iter, $model->{'COL_KEY'});
}
sub set_key {
  my ($self, $key) = @_;
  if (! defined $key) {
    $self->set_active (-1);
    return;
  }
  my $found = 0;
  my $model = $self->get_model;
  $model->foreach
    (sub {
       my ($model, $path, $iter) = @_;
       if ($key eq ($model->get($iter, $model->{'COL_KEY'})//'')) {
         $self->set_active_iter ($iter);
         $found = 1;
         return 1; # stop looping
       }
       return 0; # continue
     });
  if (! $found) {
    $self->set_active (-1);
  }
}

# return a node name string for the manual, eg. "Simple Moving Average"
sub get_manual {
  my ($self) = @_;
  my $key = $self->get_key || return undef;
  $key !~ /::/ || return undef;
  my $mod = "App::Chart::Series::$key";
  eval { Module::Load::load ($mod) } || return undef;
  my $func = $mod->can('manual') || return undef;
  return $mod->$func;
}

1;
__END__
