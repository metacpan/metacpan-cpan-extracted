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

package Gtk2::Ex::IdleObject;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;
use base 'Gtk2::Ex::SourceObject';

# uncomment this to run the ### lines
#use Smart::Comments;

sub _establish {
  my ($self) = @_;
  if (my $id = delete $self->{'source_id'}) {
    Glib::Source->remove ($id);
  }

  my $weak_self = $self;
  Scalar::Util::weaken ($weak_self);
  $self->{'source_id'} = Glib::Idle->add
    (\&Gtk2::Ex::SourceObject::_source_callback,
     \$weak_self,
     $self->{'priority'} || Glib::G_PRIORITY_DEFAULT);
  ### new: $self
  ### idle id: $self->{'source_id'}
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

Gtk2::Ex::IdleObject -- oop Glib idle calls

=head1 SYNOPSIS

 use Gtk2::Ex::IdleObject;

 # idle as a perl object
 $idle = Gtk2::Ex::IdleObject->new (callback => \&my_callback);

 # idle on a widget, firing for as long as the widget lives
 $idle = Gtk2::Ex::IdleObject->new (callback => \&my_callback,
                                    userdata => $my_widget,
                                    weak     => 1);

 $idle->stop;    # explicit stop
 $idle = undef;  # or just drop it

=head1 DESCRIPTION

C<Gtk2::Ex::IdleObject> is an object-oriented wrapper around the
C<< Glib::Idle->add >> mechanism.  It automatically removes the idle from
the main loop just by forgetting the object, and an idle object can be
associated with a widget to have it stop if/when that widget is destroyed.

Automatic removal saves you fiddling about with C<< Glib::Source->remove >>
in a cleanup, and the widget version uses weak references so the widget
doesn't stay alive forever just because it's in an idle handler.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::IdleObject->new ($callback, [$userdata, [$priority]]) >>

Create and return a new idle object.  The parameters are the same as for
C<< Glib::Idle->add >>, but the return is an object instead of an ID number.

=item C<< Gtk2::Ex::IdleObject->new_weak ($callback, [$userdata, [$priority]]) >>

Create and return a new idle object which keeps only a weak reference to
its C<$userdata>, if C<$userdata> is a reference.

If the C<$userdata> object is being used nowhere other than the idle then
it's garbage collected and the idle makes no further C<$callback> calls.
This is an easy way to ensure the mere fact an idle is operating on a Perl
object won't keep it alive when nothing else is interested in it.

If C<$userdata> is not a reference then C<new_weak> is the same as plain
C<new> above.

=item C<< Gtk2::Ex::IdleObject->new_for_widget ($callback, $widget, [$priority]) >>

Create and return a new idle object with a C<Gtk2::Widget> as the
C<$userdata>.  The idle keeps only a weak reference to the widget, so that
if/when it's no longer used anywhere else then the widget is destroyed and
the idle stops.

This is the same as C<new_weak> above, except that it can use the widget
C<destroy> signal to immediately remove the idle from the C<Glib> main loop,
whereas the C<new_weak> only notices the object gone at the next idle call.
In practice this makes very little difference, but it gets defunct idles out
of the main loop sooner.

The idle object can be stored in the instance data of the widget without
creating a circular reference.  In fact that's the recommended place to keep
it since then the idle is garbage collected at the same time as the widget.

    $widget->{'my_idle'} = Gtk2::Ex::IdleObject->new
                                (\&my_idle_callback, $widget);

=item C<< $idle->stop >>

Stop C<$idle>, so no further calls to its C<$callback> will be made.
C<stop> can be called either inside or outside the C<$callback> function,
though of course from inside the callback it also suffices to return 0 to
have the idle stop, in the usual way.

=back

=head1 OTHER NOTES

The idle object is currently implemented as a Perl object holding the idle
ID from C<< Glib::Idle->add >>.  If C<GSource> was available at the Perl
level in the future then perhaps C<Gtk2::Ex::IdleObject> could use that.

=head1 SEE ALSO

L<Glib::MainLoop>

=cut

