# Copyright 2008, 2009, 2010, 2011, 2012, 2013 Kevin Ryde

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

package App::Chart::Gtk2::LineStyleComboBox;
use 5.010;
use strict;
use warnings;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use Glib::Object::Subclass
  'Gtk2::ComboBox',
  signals => { changed => \&_do_changed },
  properties => [Glib::ParamSpec->string
                 ('linestyle',
                  'linestyle',
                  'Blurb.',
                  '',
                  Glib::G_PARAM_READWRITE),
                ];

use constant { COL_KEY  => 0,
               COL_NAME => 1 };

use constant::defer _model => sub {
  ### LineStyleComboBox _model()
  my $model = Gtk2::ListStore->new ('Glib::String', 'Glib::String');

  foreach my $elem ([ '', __('Default LineStyle') ],
                    [ 'Candles', __('Candles') ],
                    [ 'OHLC',    __('OHLC') ],
                    [ 'Points',  __('Points') ],
                    [ 'Line',    __('Line') ],
                    [ 'HighLow', __('High/Low') ],
                    [ 'Bars',    __('Bars') ],
                    [ 'Stops',   __('Stops') ],
                    [ 'None',    __('None') ],
                   ) {
    my ($package, $name) = @$elem;
    $model->set ($model->append, COL_KEY, $package, COL_NAME, $name);
  }

  # plus anything extra
  require Module::Find;
  require Gtk2::Ex::TreeModelBits;
  my %extra;
  # hash slice, everything on disk
  @extra{map {s/App::Chart::Gtk2::LineStyle:://;$_}
           Module::Find::findsubmod('App::Chart::Gtk2::LineStyle')} = ();
  ### extra on disk: \%extra
  # hash slice, less already known
  delete @extra{Gtk2::Ex::TreeModelBits::column_contents($model,COL_KEY)};

  ### extra: sort keys %extra
  foreach my $linestyle (sort keys %extra) {
    $model->set ($model->append, COL_KEY, $linestyle, COL_NAME, $linestyle);
  }

  return $model;
};

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->set_model (_model());
  my $renderer = Gtk2::CellRendererText->new;
  $self->pack_start ($renderer, 1);
  $self->set_attributes ($renderer, text => COL_NAME);
}

sub _do_changed {
  my ($self) = @_;
  $self->signal_chain_from_overridden;
  $self->notify ('linestyle');
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  if ($pspec->get_name eq 'linestyle') {
    my $iter = $self->get_active_iter;
    return $self->get_model->get ($iter, COL_KEY);
  }
}
sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  if ($pspec->get_name eq 'linestyle') {
    my $linestyle = $newval;
    if (! defined $linestyle) {
      $self->set_active (-1);
    } else {
      my $found;
      $self->get_model->foreach
        (sub {
           my ($model, $path, $iter) = @_;
           if ($model->get($iter, COL_KEY) eq $linestyle) {
             $self->set_active_iter ($iter);
             $found = 1;
             return 1; # stop looping
           }
           return 0; # continue
         });
      if (! $found) {
        Glib->warning
          (undef, "LineStyleComboBox: no such line style \"$linestyle\"");
      }
    }
  }
}

1;
__END__
