package Clay::UI::Role::Layout::HasFloating;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::_validate qw(optional clay_struct copy_value);
use Clay::UI::Revision qw(bump_revision);

role Clay::UI::Role::Layout::HasFloating {
	field $floating :param = undef;

	ADJUST {
		$floating = optional(clay_struct('Clay_FloatingElementConfig'), floating => $floating);
	}

	method floating (@new) {
		return copy_value($floating) unless @new;
		$floating = optional(clay_struct('Clay_FloatingElementConfig'), floating => @new);
		bump_revision();
		return copy_value($floating);
	}

	method contribute_floating ($config) {
		return unless defined $floating;
		$config->{floating} = { %$floating };
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Layout::HasFloating - floating attribute for Clay::UI widgets

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(
		CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_CENTER_BOTTOM CLAY_ATTACH_POINT_CENTER_TOP
	);
	use Clay::UI::Role::Core::Container;
	use Clay::UI::Role::Layout::HasFloating;

	class My::Tooltip :strict(params)
		:does(Clay::UI::Role::Core::Container)
		:does(Clay::UI::Role::Layout::HasFloating)
	{}

	# Below the parent, centred, 4 units lower, drawn above its siblings.
	my $tooltip = My::Tooltip->new(
		floating => {
			attach_to     => CLAY_ATTACH_TO_PARENT,
			attach_points => {
				parent  => CLAY_ATTACH_POINT_CENTER_BOTTOM,
				element => CLAY_ATTACH_POINT_CENTER_TOP,
			},
			offset        => { x => 0, y => 4 },
			z_index       => 10,
		},
	);

	$tooltip->floating(undef);    # back to normal layout

=head1 DESCRIPTION

C<Clay::UI::Role::Layout::HasFloating> gives a widget the C<floating>
attribute. A floating element is taken out of its parent's layout and
placed relative to another element (its parent, an element with a
given id, or the root), for tooltips, menus, popups and overlays. The
widget adds the value to its declaration (the hash of settings Clay
receives for the element) as the C<floating> part.
L<Clay::UI::Box> composes this role.

=head1 ATTRIBUTES

=head2 floating

	my $floating = $widget->floating;    # read: a copy, or undef
	$widget->floating({ attach_to => CLAY_ATTACH_TO_ROOT, offset => { x => 10, y => 10 } });
	$widget->floating(undef);            # not floating

A constructor parameter and a read/write accessor. The value is undef
(not floating) or a hashref with any of these keys (snake_case, or
Clay's camelCase; the reader returns snake_case):

=over 4

=item C<attach_to>

What the element is attached to: C<CLAY_ATTACH_TO_NONE>,
C<CLAY_ATTACH_TO_PARENT>, C<CLAY_ATTACH_TO_ELEMENT_WITH_ID> (the
element named by C<parent_id>) or C<CLAY_ATTACH_TO_ROOT>. B<The element
floats only when C<attach_to> is set to something other than
C<CLAY_ATTACH_TO_NONE>>, which is what an omitted C<attach_to> means.

=item C<parent_id>

For C<CLAY_ATTACH_TO_ELEMENT_WITH_ID>: a numeric element id or an id
hash from C<Clay_GetElementId> (for a widget with an C<id>,
C<Clay_GetElementId($widget-E<gt>id)>).

=item C<attach_points>

C<< { element => CLAY_ATTACH_POINT_*, parent => CLAY_ATTACH_POINT_* } >>:
which point of the floating element is placed on which point of the
element it is attached to. Both default to C<CLAY_ATTACH_POINT_LEFT_TOP>.

=item C<offset>

C<< { x, y } >> or C<[x, y]>: moves the element from its attach point.

=item C<expand>

C<< { width, height } >> or C<[width, height]>: enlarges the box of
the floating element by C<width> on the left and on the right and by
C<height> at the top and at the bottom. Its render commands and
L<Clay::UI/bounding_box> report the enlarged box, and its children are
placed from the enlarged box's top-left corner (see
L<Clay::XS::Structs/expand>).

=item C<z_index>

An integer -32768 to 32767 for the element and everything inside it.
Clay sorts floating elements by ascending C<z_index>, so higher values
are drawn later (on top).

=item C<pointer_capture_mode>

C<CLAY_POINTER_CAPTURE_MODE_CAPTURE> (the default; the element blocks
pointer hits below it) or C<CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH>.

=item C<clip_to>

C<CLAY_CLIP_TO_NONE> (the default; the element is not clipped by the
scroll containers around it) or C<CLAY_CLIP_TO_ATTACHED_PARENT>
(clipped like the element it is attached to).

=back

See L<Clay::XS::Structs/floating> for the exact Clay semantics.

Default undef: the declaration gets no C<floating> part.

Reading returns a new deep copy (or undef); writing stores a deep copy
of the value, so changing a hash after passing it in, or one a read
returned, does not change the widget. A write replaces the whole hash,
bumps the revision (L<Clay::UI::Revision>), takes effect at the next
C<render> and returns a copy of the new value.

The value is checked when it is set, at construction or by the accessor:
anything but undef or a hashref of the keys above with values of the
right shape dies, naming the attribute and the key, for example
C<Clay::UI: 'floating.z_index' expected an integer in -32768..32767, got '99999'>
or C<Clay::UI: 'floating' has unknown key ...>.


=head1 METHODS

=head2 contribute_floating

Adds the C<floating> part (a new hash) to the widget's declaration
while C<floating> is set (see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>).

=head1 SEE ALSO

L<Clay::XS::Structs/floating>, L<Clay::UI::Box>, L<Clay::Manual>,
L<Clay::Cookbook>.

=cut
