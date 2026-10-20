package Clay::UI::Revision;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';

use Clay::XS ();

our @EXPORT_OK = qw(bump_revision current_revision);

# One counter for the whole process: a renderer only needs to know whether
# anything changed, not what or in which Clay::UI. Scroll positions are
# written in Clay::XS, which counts them itself, as it counts the
# transition handler calls Clay makes while an element animates.
my $revision = 0;

sub bump_revision () {
	$revision++;
	return current_revision();
}

sub current_revision () {
	return $revision + Clay::XS::_scroll_position_writes() + Clay::XS::_transition_handler_calls();
}

1;

__END__
=head1 NAME

Clay::UI::Revision - process-wide counter that grows whenever a Clay::UI frame would look different

=head1 SYNOPSIS

	use v5.22;
	use warnings;

	use Object::Pad;
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Revision qw(current_revision);

	class My::Panel :strict(params) :does(Clay::UI::Box) {}

	my $root = My::Panel->new(id => 'root', background_color => [40, 50, 60, 255]);
	my $ui   = Clay::UI->new(width => 800, height => 600, root => $root);

	my $drawn;    # the revision of the frame on screen
	for my $frame (1 .. 3) {
		# render runs every frame: input reaches the widgets only through it.
		my $commands = $ui->render(pointer_state => { x => 10, y => 10, down => 0 });
		next if defined $drawn && $drawn == $ui->laid_out_revision;
		$drawn = $ui->laid_out_revision;
		say "frame $frame: drawing ", scalar @$commands, ' commands';
	}
	$root->background_color([0, 0, 0, 255]);      # a change ...
	say 'stale' if current_revision() != $drawn;   # ... makes the drawn frame stale

=head1 DESCRIPTION

The I<revision> is a non-negative integer that grows whenever something
that a frame lays out or draws has changed. A renderer remembers the
revision of the frame it drew and skips drawing while the revision is
still the same. It still calls L<Clay::UI/render> every frame: pointer
and scroll input reach the widgets only through C<render>, and the
changes they cause (hover states, scrolling) bump the revision there.
L<Clay::UI/laid_out_revision> tells which revision a frame shows.

These bump the revision:

=over 4

=item *

every widget setter that changes what a frame lays out or draws:
attributes (C<layout>, C<background_color>, C<text>, ...), the children
of a widget, user states (C<add_state> and friends), C<disabled>;

=item *

the C<width>, C<height> and C<measure_text> writers of a L<Clay::UI>;

=item *

a change of the hovered, armed, pressed or focused widgets in a
L<Clay::UI::Interaction>, because they drive the derived C<hovered>,
C<pressed> and C<focused> states;

=item *

a scroll container moving inside C<render> (wheel input, drag
scrolling or the momentum after drag scrolling), L<Clay::UI/scroll_to> and
L<Clay::XS/set_scroll_position>;

=item *

C<mark_changed> (L<Clay::UI::Role::Core::Element/mark_changed>), which
widget classes that keep state of their own call from their setters,
and C<request_prepare> (L<Clay::UI::Role::Core::Preparable>).

=item *

every frame in which Clay runs a transition handler
(L<Clay::XS::Structs/transition>), that is, animates an element: its
render commands differ from the frame before, and the frame after the
last step shows the final state. The counting happens in L<Clay::XS>,
so the revision moves during C<render>, after L<Clay::UI/laid_out_revision>
was recorded; the next frame then shows a new revision.

=back

Reading an attribute never bumps the revision; neither does writing
C<can_focus>, which changes nothing drawn (unless it takes the focus
away).

There is one revision for the whole process, shared by every
Clay::UI: a change in any of them makes every renderer draw again. Only
equality is meaningful. The value starts at 0 and only grows, but how
far it grows per change is unspecified (one write may bump it more than
once).

=head1 FUNCTIONS

Nothing is exported by default; import the functions by name.

=head2 current_revision

	my $revision = current_revision();

Returns the current revision.

=head2 bump_revision

	my $revision = bump_revision();

Increments the revision and returns the new value. Widget code calls it
from setters that change what a frame shows; most widget classes call
C<< $widget->mark_changed >> instead, which does the same.

=head1 SEE ALSO

L<Clay::UI/laid_out_revision>, L<Clay::UI>, L<Clay::Manual>.

=cut
