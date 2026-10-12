package Clay::UI::Role::Layout::HasScroll;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::_validate qw(optional required clay_struct clay_field copy_value);
use Clay::UI::Revision qw(bump_revision);
use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Core::Stateful;
use Clay::UI::Role::Events::Emitter;

role Clay::UI::Role::Layout::HasScroll
	:does(Clay::UI::Role::Core::Stateful)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Events::Emitter)
{
	field $horizontal   :param = 0;
	field $vertical     :param = 1;
	field $child_offset :param = undef;

	ADJUST {
		$horizontal   = required(clay_field('Clay_ClipElementConfig', 'horizontal'),    horizontal   => $horizontal);
		$vertical     = required(clay_field('Clay_ClipElementConfig', 'vertical'),    vertical     => $vertical);
		$child_offset = optional(clay_struct('Clay_Vector2'), child_offset => $child_offset);
	}

	method horizontal (@new) {
		return $horizontal unless @new;
		$horizontal = required(clay_field('Clay_ClipElementConfig', 'horizontal'), horizontal => @new);
		bump_revision();
		return $horizontal;
	}

	method vertical (@new) {
		return $vertical unless @new;
		$vertical = required(clay_field('Clay_ClipElementConfig', 'vertical'), vertical => @new);
		bump_revision();
		return $vertical;
	}

	method child_offset (@new) {
		return copy_value($child_offset) unless @new;
		$child_offset = optional(clay_struct('Clay_Vector2'), child_offset => @new);
		bump_revision();
		return copy_value($child_offset);
	}

	method contribute_clip ($config) {
		my %clip = (horizontal => $horizontal, vertical => $vertical);
		$clip{child_offset} = $child_offset if defined $child_offset;
		$config->{clip} = \%clip;
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Layout::HasScroll - make a Clay::UI widget a scroll container

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);
	use Clay::UI;
	use Clay::UI::Text;
	use Clay::UI::Role::Layout::HasScroll;
	use Clay::UI::Role::Layout::HasLayout;

	class My::LogView :strict(params)
		:does(Clay::UI::Role::Layout::HasScroll)
		:does(Clay::UI::Role::Layout::HasLayout)
	{}
	class My::Line :strict(params) :does(Clay::UI::Text) {}

	my $log = My::LogView->new(
		id       => 'log',    # required
		vertical => 1,
		layout   => {
			sizing           => { width => sizing_grow(), height => sizing_fixed(300) },
			layout_direction => CLAY_TOP_TO_BOTTOM,
		},
	);
	$log->add_child(map { My::Line->new(text => "line $_") } 1 .. 100);

	my $ui = Clay::UI->new(width => 800, height => 600, root => $log);
	$ui->render;    # one frame first: scrolling works on the last frame's layout
	$ui->render(
		pointer_state => { x => 10, y => 10, down => 0 },
		scroll_delta  => { x => 0, y => -4 },    # wheel input: 40 units down
	);
	$ui->scroll_to($log, { y => 0 });               # back to the top

=head1 DESCRIPTION

C<Clay::UI::Role::Layout::HasScroll> turns a widget into a scroll
container: an element that clips its children to its own box and moves
them by a scroll offset. Only a widget composing this role scrolls:

=over 4

=item *

the layout pass (the part of L<Clay::UI/render> that declares the tree
to Clay) gives only it Clay's scroll offset;

=item *

only it receives L<Clay::UI::Events::OnScroll>;

=item *

only it works with L<Clay::UI/scroll_state> and L<Clay::UI/scroll_to>.

=back

A widget that writes a C<clip> part into its declaration without this
role is clipped but does not scroll.

The role composes:

=over 4

=item *

L<Clay::UI::Role::Core::Stateful>: C<id> is required, because Clay
keeps the scroll position under the element id from frame to frame;

=item *

L<Clay::UI::Role::Core::Container>: the scrolled content is added with
C<add_child>;

=item *

L<Clay::UI::Role::Events::Emitter>: events can be fired on it.

=back

C<render> scrolls the containers itself: it passes its C<scroll_delta>
and C<enable_drag_scrolling> arguments to Clay once per frame (wheel
input moves the container under the pointer, by ten times
C<scroll_delta>; negative values scroll down and right). Wheel input
has no momentum. Drag scrolling moves the container with the pointer
and, after the release, lets it glide on with momentum for some frames.
Scrolling uses the
layout of the previous frame, so it starts working after one completed
C<render>. Leave C<Clay_UpdateScrollContainers> to C<render>: movement
from a call of your own between renders goes unnoticed, since C<render>
compares the positions it finds at its start with those after its own
call (no C<OnScroll>, no revision bump).

=head1 CONSTRUCTOR PARAMETERS

=head2 id

Required. See L<Clay::UI::Role::Core::Element/id>. The constructor dies
with C<Clay::UI::Role::Core::Stateful: widget '...' requires an explicit 'id'> without one.

=head1 ATTRIBUTES

Each attribute is a constructor parameter and a read/write accessor:
call it without an argument to read, with one argument to write. A
write bumps the revision (L<Clay::UI::Revision>), takes effect at the
next C<render> and returns the new value. Values are checked when they
are set; a bad value dies naming the attribute.

=head2 horizontal

	$scroll->horizontal(1);

Whether the container clips and scrolls horizontally. A plain scalar,
used as a Perl boolean. Default C<0>. Undef dies with
C<Clay::UI: 'horizontal' must be defined>, a reference with
C<Clay::UI: 'horizontal' expected a plain boolean value>.


=head2 vertical

	$scroll->vertical(0);

Whether the container clips and scrolls vertically, like
L</horizontal>. Default C<1>.

=head2 child_offset

	$scroll->child_offset({ x => 0, y => -120 });    # you place the content
	$scroll->child_offset(undef);                    # Clay scrolls again

Where the content is placed, relative to the container's top left
corner. Default undef: each frame the layout pass uses Clay's own
scroll position, which C<render> updates from wheel and drag input.
Set C<< { x, y } >> (or C<[x, y]>) to place the content yourself:
the offset is used as it is, and input no longer moves the content.
Clay still tracks its own scroll position meanwhile: wheel and drag
input still change C<position> in L<Clay::UI/scroll_state>, fire
L<Clay::UI::Events::OnScroll> and bump the revision, although the
content does not move.
Negative values move the content up and left, like scrolling down and
right. Set it back to undef to give control back to Clay.

Reading returns a new copy (or undef); writing stores a copy. An unknown
key or a non-number dies, for example
C<Clay::UI: 'child_offset' has unknown key 'z' (known keys: x, y)>.


To scroll to a position while keeping Clay in control (and its limits
to the content size), use L<Clay::UI/scroll_to> instead.

=head1 METHODS

=head2 contribute_clip

Adds the C<clip> part to the widget's declaration (see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION> and
L<Clay::XS::Structs/clip>): C<horizontal>, C<vertical> and, when set,
C<child_offset>.

=head1 SEE ALSO

L<Clay::UI/scroll_state>, L<Clay::UI/scroll_to>,
L<Clay::UI::Events::OnScroll>, L<Clay::XS::Structs/clip>,
L<Clay::Manual>.

=cut
