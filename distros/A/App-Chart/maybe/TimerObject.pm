# Glib timer as an object, and weak reference to its data.

# Copyright 2007, 2008, 2010, 2011 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Chart is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::TimerObject;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;
use base 'Gtk2::Ex::SourceObject';


#------------------------------------------------------------------------------
# timer object

sub _establish {
  my ($self) = @_;
  if (my $id = delete $self->{'source_id'}) {
    Glib::Source->remove ($id);
  }

  if (my $period = $self->{'period'}) {
    my $weak_self = $self;
    Scalar::Util::weaken ($weak_self);
    $self->{'source_id'} = Glib::Timeout->add
      ($period,
       \&Gtk2::Ex::SourceObject::_source_callback, \$weak_self,
       $self->{'priority'} || Glib::G_PRIORITY_DEFAULT);
    ### timer id: "$self $self->{'source_id'}"
  }
}

sub set_period {
  my ($self, $period) = @_;
  my $old_period = $self->{'period'};
  $self->{'period'} = $period;
  if (($period||0) != ($old_period||0)) { _establish ($self); }
}

sub new {
  my $class = shift;
  my $self = $class->SUPER::new (@_);
  _establish ($self);
  return $self;
}

1;
__END__

=head1 NAME

Gtk2::Ex::TimerObject -- oop Glib timer

=head1 SYNOPSIS

 use Gtk2::Ex::TimerObject;
 my $timer = Gtk2::Ex::TimerObject->new
     (period   => 1000,    # milliseconds
      callback => \&my_func,
      userdata => 'some value');

 # or weak reference to a widget
 my $timer = Gtk2::Ex::TimerObject->new
     (period        => 500,
      run           => 0,    # start off stopped too
      callback      => \&my_update_func,
      userdata      => $widget,
      weak_userdata => 1);

 $timer->set_period (100);
 $timer->start;
 $timer->stop;

=head1 DESCRIPTION

C<Gtk2::Ex::TimerObject> is an object-oriented wrapper around the
C<< Glib::Timeout->add >> timer mechanism.  A timer object can be stopped
and later restarted, and is automatically stopped if the object is destroyed
(when all references to it are dropped).

The "C<weak>" option allows only a weak reference to be kept to the userdata
passed to the callback function.  If the userdata object or widget is
destroyed then the timer stops.  This is good if the timer is part of a
widget implementation (the weakening avoid a circular reference).

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::TimerObject->new (key=>value, ...) >>

Create and return a new timer object.  Parameters are taken as key/value
pairs.  The following keys are supported

    period       time in milliseconds, or undef
    callback     function to call
    userdata     parameter to each callback call
    weak         if true then weaken userdata (default false)
    priority     Glib main loop level (default G_PRIORITY_DEFAULT)

When the timer is running the given C<callback> function is called every
C<period> milliseconds,

    $callback->($timerobj, $userdata);

Any return value from it is ignored, but it can change the period or stop
the timer within that callback, if desired.

If C<period> is C<undef> it means the timer should not run, and no calls to
the C<callback> function are made.  This can be good for an initialization
function where a timer should be created, but it shouldn't run until some
later setups.

If the C<weak> option is true then the C<userdata> value is kept only as a
weak reference (if it is in fact a reference).  If that value is garbage
collected (because nothing else is using it) then the timer stops.

The C<priority> parameter controls the priority of the timer within the Glib
main loop.  The default is C<Glib::G_PRIORITY_DEFAULT>, which is 0.
Positive values are lower priority, negative values higher.

=item C<< $timer->set_period ($milliseconds) >>

Set the period of C<$timer> to C<$milliseconds>, or stop it if
C<$milliseconds> is C<undef>.

In the current implementation, if the timer is running and the period is
changed then it starts counting down again from a whole new C<$milliseconds>
period.  Perhaps in the future it'll be possible to take into account how
long since the last firing, to keep it running smoothly if merely making
small adjustments to the period, but current Glib (version 2.14) doesn't
allow that (not with the basic C<< Glib::Timeout->add >>).

=item C<< $timer->stop >>

Stop C<$timer>, so no further calls to its C<$callback> are made.  This is
the same as a C<< $timer->set_period(undef) >>.  The timer can be restarted
later by a new C<set_period>, if desired.

=back

=head1 OTHER NOTES

C<TimerObject> is currently implemented as a Perl object holding a timer ID
from C<< Glib::Timeout->add >>.  If C<GSource> was available at the Perl
level in the future then perhaps C<TimerObject> could become a subclass of
that.

=head1 SEE ALSO

L<Glib::MainLoop>, L<Gtk2::Ex::IdleObject>, L<Glib::Ex::SignalObject>

=cut

