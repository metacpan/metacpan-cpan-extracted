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

package App::Chart::Gtk2::Ex::RadioGroup;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Scalar::Util;

use Glib::Ex::SignalIds;

use Glib::Object::Subclass
  'Glib::Object',
  signals => { changed => { param_types => [],
                            return_type => undef },
             },
  properties => [ Glib::ParamSpec->scalar
                  ('members',
                   'members',
                   'Arrayref of Gtk2::Widget members of the group.',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  $self->{'members'} = [];
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  # my $pname = $pspec->get_name;
  my $members = $self->{'members'};
  @$members = grep {defined} @$members;
  return $members;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  # my $pname = $pspec->get_name;

  $self->clear;
  $self->add (@$newval);
}

sub _purge {
  my ($self) = @_;
  my $members = $self->{'members'};
  @$members = grep {defined $_ && $_->get_group} @$members;
}

sub clear {
  my ($self) = @_;
  my $members = $self->{'members'};
  if (@$members) {
    require Glib::Ex::FreezeNotify;
    my $freezer = Glib::Ex::FreezeNotify->new ($self);
    foreach my $object (@$members) {
      if ($object) {
        $self->remove ($object);
      }
    }
  }
}

sub remove {
  my ($self, $object) = @_;
  $object->set (group => undef);
  delete $object->{__PACKAGE__.'.ids'};
  my $members = $self->{'members'};
  @$members = grep {defined && $_ != $object} @$members;
  $self->notify ('members');
}

sub add {
  my $self = shift;
  my $members = $self->{'members'};
  Scalar::Util::weaken (my $weak_self = $self);

  while (@_) {
    my $object = shift;
    $object->set (group => $self->representative);
    $object->{__PACKAGE__.'.ids'} = Glib::Ex::SignalIds->new
      ($object,
       $object->signal_connect ('notify::group',
                                \&_do_group_changed, \$weak_self));
    push @$members, $object;
    Scalar::Util::weaken ($members->[-1]);
  }
  $self->notify ('members');
}

sub _do_group_changed {
  my ($object, $pspec, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  $self->remove ($object);
}

sub members {
  my ($self) = @_;
  _purge($self);
  return @{$self->{'members'}};
}

sub representative {
  my ($self) = @_;
  _purge($self);
  return $self->{'members'}->[0];
}

sub active_item {
  my ($self) = @_;
  return List::Util::first {$_->get('active') && $_->get_group} $self->members;
}

1;
__END__
