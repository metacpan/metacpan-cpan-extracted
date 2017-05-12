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


# tracking widget position in root coords, with watching for reparenting
#


package App::Chart::Gtk2::Ex::WidgetPositionTracker;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Glib::Ex::SignalIds;
use Scalar::Util 1.18 'refaddr'; # 1.18 for pure-perl refaddr() fix

use App::Chart::Glib::Ex::MoreUtils;
use App::Chart::Glib::Ex::TieWeakNotify;

# uncomment this to run the ### lines
#use Smart::Comments;

use Glib::Object::Subclass
  'Glib::Object',
  properties => [Glib::ParamSpec->object
                 ('widget',
                  'widget',
                  'Blurb.',
                  'Gtk2::Widget',
                  Glib::G_PARAM_READWRITE),
                ],
  signals => { moved => { param_types => [],
                          return_type => undef },
             };

my %realized_instances;
my $configure_event_hook_id;

sub INIT_INSTANCE {
  my ($self) = @_;
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  delete $realized_instances{refaddr($self)};
  delete $self->{'alloc_ids'};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;

  if ($pname eq 'widget') {
    FINALIZE_INSTANCE ($self);
    delete $self->{'realize_ids'};
    App::Chart::Glib::Ex::TieWeakNotify->set ($self, $pname, $newval);

    if ($newval) {
      if ($newval->flags & 'no-window') {
        $self->{'alloc_ids'} = Glib::Ex::SignalIds->new
          ($newval,
           $newval->signal_connect (size_allocate => \&_do_size_allocate,
                                    App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
      }
      ### realized: $newval->realized
      if ($newval->realized) {
        _do_realize ($newval, \$self);
      } else {
        _connect_realize ($self, $newval);
      }
    }
  }
}

# called for size changes as well as position changes, and by the time reach
# here the old size is apparently not available any more: $allocation in
# $parameter->[1] is the same as $widget->allocation.
#
sub _do_size_allocate {
  my ($widget, $alloc, $ref_weak_self) = @_;
  ### size_allocate signal: $widget
  my $self = $$ref_weak_self || return;
  $self->signal_emit ('moved');
}

sub _connect_realize {
  my ($self, $widget) = @_;
  ### connect realize
  $self->{'realize_ids'} = Glib::Ex::SignalIds->new
    ($widget,
     $widget->signal_connect (realize => \&_do_realize,
                              App::Chart::Glib::Ex::MoreUtils::ref_weak($self)));
  ### ids: $self->{'realize_ids'}
}

sub _do_realize {
  my ($widget, $ref_weak_self) = @_;
  ### realize signal, window: $widget->window
  my $self = $$ref_weak_self || return;
  delete $self->{'realize_ids'};
  Scalar::Util::weaken ($realized_instances{refaddr($self)} = $self);
  $configure_event_hook_id ||= Gtk2::Widget->signal_add_emission_hook
    (configure_event => \&_do_configure_event);
}

sub _do_configure_event {
  my ($invocation_hint, $parameters) = @_;
  my $changed_widget = $parameters->[0];
  ### configure event: $changed_widget

  foreach my $self (values %realized_instances) {
    if (my $widget = $self->{'widget'}) {
      if ($widget->window) {
        if ($changed_widget == $widget
            || $widget->is_ancestor ($changed_widget)) {
          $self->signal_emit ('moved');
        }
      } else {
        # was unrealized
        FINALIZE_INSTANCE ($self);
        _connect_realize ($self, $widget);
      }
    } else {
      # widget weakened away
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

1;
__END__

, values %instances_nowin
        $size_allocate_id ||= Gtk2::Widget->signal_add_emission_hook
          (size_allocate => \&_do_size_allocate);
sub _do_size_allocate {
  my ($invocation_hint, $parameters) = @_;
    unless (%instances_nowin) {
      undef $size_allocate_id;
      return 0; # disconnect
    }

  my $changed_widget = $parameters->[0];
  foreach my $self (values %{$changed_widget->{(__PACKAGE__)}}) {
    $self->signal_emit ('moved');
  }
  return 1; # stay connected
}

  if (my $widget = $self->{'widget'}) {
    if (my $href = $widget->{(__PACKAGE__)}) {
      delete $href->{refaddr($self)};
      if (! %$href) {
        delete $widget->{(__PACKAGE__)};
      }
    }
  }

        my $href = ($newval->{(__PACKAGE__)} ||= {});
        $href->{refaddr($self)} = $self;
        Scalar::Util::weaken ($href->{refaddr($self)});

  my $changed_alloc = $parameters->[1];
      my $alloc = $widget->allocation;
      print $alloc->width, $changed_alloc->width,"\n";

sub _do_moved {
  my ($widget, $allocation, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->signal_emit ('moved');
}

    } else {
      delete $self->{'ids'};
    }

use Glib::Ex::SignalIds 5;  # version 5 for ->add()

sub _update_connections {
  my ($self) = @_;
  my $connections = $self->{'connections'};
  @$connections = ();
  my $widget = $self->{'widget'} || return;
  my $ref_weak_self = App::Chart::Glib::Ex::MoreUtils::ref_weak($self);

  if ($widget->flags & 'no-window') {
    push @$connections,
      Glib::Ex::SignalIds->new
          ($widget,
           $widget->signal_connect (size_allocate => \&_do_moved,
                                    $ref_weak_self));
  }

  do {
    my $ids = Glib::Ex::SignalIds->new
      ($widget,
       $widget->signal_connect ('notify::parent', \&_do_reparent,
                                $ref_weak_self));
    if ($widget == $self->{'widget'}
        || ! ($widget->flags & 'no-window')) {
      $ids->add ($widget->signal_connect (size_allocate => \&_do_move,
                                          $ref_weak_self));
    }
    push @$connections, $ids;

  } while ($widget = $widget->get_parent);
}

sub _do_reparent {
  my $ref_weak_self = $_[-1];
  my $self = $$ref_weak_self || return;
  _update_connections ($self);
  $self->signal_emit ('moved');
}

sub _do_moved {
  my $ref_weak_self = $_[-1];
  my $self = $$ref_weak_self || return;
  $self->signal_emit ('moved');
}

