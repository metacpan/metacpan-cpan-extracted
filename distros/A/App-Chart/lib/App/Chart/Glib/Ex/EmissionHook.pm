# Copyright 2009, 2010, 2011, 2016 Kevin Ryde

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

package App::Chart::Glib::Ex::EmissionHook;
use 5.008;
use strict;
use warnings;
use Scalar::Util;

sub new {
  my ($class, $target_class, $signal_name, $handler, @userdata) = @_;
  my $self = bless { target_class => $target_class,
                     signal_name  => $signal_name,
                     handler      => $handler,
                     userdata     => \@userdata,
                   }, $class;
  my $weak_self = $self;
  Scalar::Util::weaken ($weak_self);
  $self->{'hook_id'} = $target_class->signal_add_emission_hook
    ($signal_name, \&_handler, \$weak_self);
  return $self;
}

sub _handler {
  my ($invocation_hint, $parameters, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return 0; # disconnect
  my $stay_connected = &{$self->{'handler'}}
    ($invocation_hint, $parameters, @{$self->{'userdata'}});
  if (! $stay_connected) {
    delete $self->{'hook_id'};
  }
  return $stay_connected;
}

# Had some trouble in the past removing an emission hook under global
# destruction when the class had already removed all hooks, or something
# like that.
#
sub DESTROY {
  my ($self) = @_;
  $self->remove;
}

sub remove {
  my ($self) = @_;
  my $hook_id = delete $self->{'hook_id'} || return; # already removed
  $self->{'target_class'}->signal_remove_emission_hook
    ($self->{'signal_name'}, $hook_id);
}

1;
__END__

=for stopwords Ryde ObjectBits

=head1 NAME

App::Chart::Glib::Ex::EmissionHook -- object oriented emission_hook connection

=for test_synopsis my ($hook, $userdata)

=head1 SYNOPSIS

 use App::Chart::Glib::Ex::EmissionHook;
 $hook = App::Chart::Glib::Ex::EmissionHook->new
   ('Gtk2::Widget', 'button_press_event', \&my_handler, $userdata);

=head1 DESCRIPTION

This is an object-oriented approach to the Glib C<signal_add_emission_hook()>.

=head1 FUNCTIONS

=over 4

=item C<< $eobj = App::Chart::Glib::Ex::EmissionHook->new ($target_class, $signal_name, $handler, $userdata) >>

=back

=head1 SEE ALSO

L<Glib::Ex::SignalIds>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2009, 2010, 2011, 2016 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<@chartdatadir@/COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
