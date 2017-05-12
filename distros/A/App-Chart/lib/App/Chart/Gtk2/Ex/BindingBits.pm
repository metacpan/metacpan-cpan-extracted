# binding set replaced by an rc parse_string in program,
#
# lookup through widget bindings won't take Pointer_Button1 etc



# Copyright 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Gtk2::Ex::BindingBits;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Scalar::Util;

# uncomment this to run the ### lines
#use Smart::Comments;


# Think it's better to croak for an unknown bindingset name than to return 0
# for not activated, on the basis it picks up typos or bad names.
#
sub activate_button_event {
  my ($bindings, $event, $object) = @_;

  unless (Scalar::Util::blessed($bindings)
          && $bindings->isa('Gtk2::BindingSet')) {
    $bindings = Gtk2::BindingSet->find ($bindings)
      || croak 'No BindingSet called ',$bindings;
  }
  my $keyval = Gtk2::Gdk->keyval_from_name('Pointer_Button' . $event->button)
    || do {
      ### activate_button_event() unknown: 'Pointer_Button' . $event->button
      return 0;
    };

  my $modifiers = $event->get_state;
  if ($event->type eq 'button-release') { $modifiers |= 'release-mask'; }
  ###   type     : $event->type
  ###   modifiers: "$modifiers"

  my $found = $bindings->activate ($keyval, $modifiers, $object);
  ### activate_button() found: $found
  return $found;
}

1;
__END__

=for stopwords Ryde Chart

=head1 NAME

App::Chart::Gtk2::Ex::BindingBits -- helpers for Gtk2::BindingSet etc

=head1 SYNOPSIS

 use App::Chart::Gtk2::Ex::BindingBits;

=head1 FUNCTIONS

=over 4

=item C<< $bool = App::Chart::Gtk2::Ex::BindingBits::activate_button_event ($bindings, $event, $object) >>

Activate bindings for a button press C<$event>.  The return is true if a
binding was found and activated or false if not.

C<$event> should be a C<Gtk2::Gdk::Event::Button>.  The button number is
turned into keyval C<Pointer_Button1> etc, modifiers get C<release-mask>
added if it's a C<button-release> event, then simply

    $bindings->activate ($keyval, $modifiers, $object)

C<$bindings> can be either a C<Gtk2::BindingSet> object or a string name of
a binding set for C<< Gtk2::BindingSet->find >>.  As of Gtk 2.18 there's
keyvals for buttons 1 through 5.  If C<< $event->button >> is somehow
another value then C<activate_button_event> returns 0 as there cannot be any
bindings for it.

See F<examples/binding-button-event.pl> in the sources for a sample program.

=back

=head1 OTHER NOTES

For reference, as of Gtk 2.18 the C<Gtk2::Object> method
C<< $object->bindings_activate >> is no good for C<Pointer_Button1> etc as
that C<bindings_activate> trys to go from keyval to hardware keycode then
back to keyvals, but there's normally no keycode for the pointer buttons, so
it doesn't lookup anything in the BindingSet.

=head1 SEE ALSO

L<Gtk2::BindingSet>, L<Gtk2::Ex::WidgetBits>, L<Gtk2::Gdk::Event::Button>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENSE

Copyright 2009, 2010 Kevin Ryde

Chart is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Chart is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Chart.  If not, see L<http://www.gnu.org/licenses/>.

=cut

# junk, probably
#
# sub activate_event {
#   my ($bindings, $event, $object) = @_;
#   unless (Scalar::Util::blessed($bindings)
#           && $bindings->isa('Gtk2::BindingSet')) {
#     $bindings = Gtk2::BindingSet->find ($bindings)
#       || croak "No BindingSet called '$bindings'";
#   }
# 
#   my $keyval;
#   if ($event->can('keyval')) {
#     $keyval = $event->keyval;
#   } elsif ($event->can('button')) {
#     my $button = $event->button;
#     $keyval = Gtk2::Gdk->keyval_from_name("Pointer_Button$button")
#       || do { warn "BindingBits ignoring unrecognised button number $button";
#               return 0; };
#   } else {
#     croak "Unrecognised event type $event";
#   }
# 
#   my $found = $bindings->activate ($keyval, $event->get_state, $object);
#   ### activate_event_keyval() found: $found
#   return $found;
# }
