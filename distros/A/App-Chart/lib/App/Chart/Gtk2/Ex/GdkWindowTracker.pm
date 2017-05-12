# Copyright 2009, 2010 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Chart is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.


# tracking window position in root coords, with watching for reparenting
#


package App::Chart::Gtk2::Ex::GdkWindowTracker;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Scalar::Util 1.18 'refaddr'; # 1.18 for pure-perl refaddr() fix

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Glib::Object',
  properties => [Glib::ParamSpec->object
                 ('window',
                  'window',
                  'Blurb.',
                  'Gtk2::Window',
                  Glib::G_PARAM_READWRITE),
                ],
  signals => { moved => { param_types => [],
                          return_type => undef },
             };

my %realized_instances;
my $configure_event_hook_id;

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  delete $realized_instances{refaddr($self)};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;

  if ($pname eq 'window') {
    FINALIZE_INSTANCE ($self);
    App::Chart::Glib::Ex::TieWeakNotify->set ($self, $pname, $newval);

    if ($newval) {
      Scalar::Util::weaken ($realized_instances{refaddr($self)} = $self);
      $configure_event_hook_id ||= Gtk2::Window->signal_add_emission_hook
        (configure_event => \&_do_configure_event);
    }
  }
}

sub _do_configure_event {
  my ($invocation_hint, $parameters) = @_;
  my $changed_window = $parameters->[0];
  ### configure event: $changed_window

  foreach my $self (values %realized_instances) {
    if (my $window = $self->{'window'}) {
      if (_window_is_ancestor_or_self ($changed_window, $window)) {
        $self->signal_emit ('moved');
      }
    } else {
      # window weakened away
      FINALIZE_INSTANCE ($self);
    }
  }
  if (%realized_instances) {
    return 1; # stay connected
  } else {
    ### disconnect hook
    undef $configure_event_hook_id;
    return 0; # disconnect
  }
}

sub _window_is_ancestor_or_self {
  my ($window, $child) = @_;
  for (;;) {
    if ($window == $child) { return 1; }
    $window = $window->get_parent || return 0;
  }
}


1;
__END__
