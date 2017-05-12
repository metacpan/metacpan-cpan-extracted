# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::IntradayModeComboBox;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Locale::TextDomain ('App-Chart');

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart::Intraday;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Gtk2::ComboBox',
  signals => { changed => \&_do_changed },
  properties => [ Glib::ParamSpec->string
                  ('symbol',
                   __('Symbol'),
                   'The symbol for which to display modes.',
                   '',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('mode',
                   'mode',
                   'The currently selected mode, or empty when no modes at all.',
                   '',
                   Glib::G_PARAM_READWRITE)];

use constant { COL_MODE => 0,
               COL_NAME => 1,
               NUM_COLUMNS => 2 };

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'symbol'} = '';
  $self->{'mode'} = '';

  my $model = Gtk2::ListStore->new (('Glib::String') x NUM_COLUMNS);
  $self->set_model ($model);

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (ypad => 0);
  $self->pack_start ($renderer, 1);
  $self->set_attributes ($renderer, markup => COL_NAME);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  my $model = $self->get_model;

  my $oldval = $self->{$pname};
  if ($oldval eq $newval) { return; }

  if ($pname eq 'mode') {
    my $mode = $newval;

    my $found = 0;
    $model->foreach (sub {
                       my ($model, $path, $iter) = @_;
                       if ($mode eq $model->get_value ($iter, COL_MODE)) {
                         $found = 1;
                         $self->{'mode'} = $mode;
                         $self->set_active_iter ($iter);
                         return 1; # stop
                       }
                       return 0; # continue
                     });
    if (! $found) {
      Glib->warning (undef, "IntradayModeComboBox: no such mode \"$mode\"");
    }
    return;
  }

  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'symbol') {
    my $symbol = $newval;
    $model->clear;
    my $old_mode = $self->{'mode'};

    # create and fill the accelgroup always for now, since the intraday
    # dialog always wants it
    my $accelgroup = $self->accelgroup;
    my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak($self);

    # remove old entries
    my $accelgroup_keyvals = $self->{'accelgroup_keyvals'};
    while (my $keyval = pop @$accelgroup_keyvals) {
      $accelgroup->disconnect_key ($keyval, ['mod1-mask']);
    }

    require App::Chart::IntradayHandler;
    my @handler_list
      = $symbol ? App::Chart::IntradayHandler->handlers_for_symbol ($symbol)
        : ();
    ### symbol handler count: $symbol." ".scalar(@handler_list)

    my $active_pos = 0;
    foreach my $i (0 .. $#handler_list) {
      my $h = $handler_list[$i];
      my $name = $h->name_as_markup;
      my $mode = $h->{'mode'};
      if ($mode eq $old_mode) {
        $active_pos = $i;
      }
      $model->set ($model->append,
                   COL_MODE, $mode,
                   COL_NAME, $name);

      if ($accelgroup && defined (my $key = $h->name_mnemonic_key)) {
        my $keyval = Gtk2::Gdk->keyval_from_name($key);
        push @$accelgroup_keyvals, $keyval;
        $accelgroup->connect ($keyval, ['mod1-mask'], [],
                              sub { _do_accelgroup ($ref_weak_self, $mode) });

      }
    }
    $self->set_active ($active_pos);
    $self->set_sensitive (@handler_list != 0);
  }
}

# 'changed' class closure
sub _do_changed {
  my ($self) = @_;
  my $model = $self->get_model;
  my $iter = $self->get_active_iter || return;  # possibly nothing
  my $mode = $model->get_value ($iter, COL_MODE);
  if ($self->{'mode'} ne $mode) {
    $self->{'mode'} = $mode;
    $self->notify ('mode');
  }
}

sub accelgroup {
  my ($self) = @_;
  return ($self->{'accelgroup'} ||= Gtk2::AccelGroup->new);
}

sub _do_accelgroup {
  my ($ref_weak_self, $mode) = @_;
  my $self = $$ref_weak_self || return;
  $self->set (mode => $mode);
}

1;
__END__

=for stopwords combobox intraday ComboBox programmatically

=head1 NAME

App::Chart::Gtk2::IntradayModeComboBox -- combobox intraday mode selector

=head1 SYNOPSIS

 use App::Chart::Gtk2::IntradayModeComboBox;
 my $combobox = App::Chart::IntradayModeCombo->new;

=head1 WIDGET HIERARCHY

C<App::Chart::Gtk2::IntradayModeComboBox> is a subclass of C<Gtk2::ComboBox>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ComboBox
            App::Chart::Gtk2::IntradayModeComboBox

=head1 DESCRIPTION

C<App::Chart::Gtk2::IntradayModeComboBox> presents available intraday data
modes, like "1 Day" or "5 Days", for a given stock symbol.  The C<mode>
property changes according to the mode selected.

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::IntradayModeCombo->new (key=>value,...) >>

Create and return a new C<App::Chart::IntradayModeCombo> object.  Optional
key/value pairs set initial properties as per C<< Glib::Object->new >>.

=back

=head1 PROPERTIES

=over 4

=item C<symbol> (string, default empty "")

The symbol for which to display intraday modes.  If the symbol has no
intraday handlers at all then the ComboBox is empty and insensitive.

When changing the symbol if the current C<mode> is not available in the new
symbol then it changes to the first mode of that new symbol.

=item C<mode> (string, default empty "")

The selected intraday mode key, such as C<"1d">.  This changes with the user
selection, and can be set programmatically to change the ComboBox display.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::IntradayDialog>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
