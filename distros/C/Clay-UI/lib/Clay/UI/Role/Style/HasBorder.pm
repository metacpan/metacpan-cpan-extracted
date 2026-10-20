package Clay::UI::Role::Style::HasBorder;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::_validate qw(optional validate_border_width clay_struct copy_value);
use Clay::UI::Revision qw(bump_revision);

role Clay::UI::Role::Style::HasBorder {
	field $border_color :param = undef;
	field $border_width :param = undef;

	ADJUST {
		$border_color = optional(clay_struct('Clay_Color'),        border_color => $border_color);
		$border_width = optional(\&validate_border_width, border_width => $border_width);
	}

	method border_color (@new) {
		return copy_value($border_color) unless @new;
		$border_color = optional(clay_struct('Clay_Color'), border_color => @new);
		bump_revision();
		return copy_value($border_color);
	}

	method border_width (@new) {
		return copy_value($border_width) unless @new;
		$border_width = optional(\&validate_border_width, border_width => @new);
		bump_revision();
		return copy_value($border_width);
	}

	method contribute_border ($config) {
		return unless defined $border_color || defined $border_width;

		my %border;
		$border{color} = $border_color if defined $border_color;

		if (defined $border_width) {
			$border{width} = ref $border_width
				? $border_width
				: { left => $border_width, right => $border_width, top => $border_width, bottom => $border_width, between_children => 0 };
		}

		$config->{border} = \%border;
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Style::HasBorder - border attributes for Clay::UI widgets

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI::Role::Core::Container;
	use Clay::UI::Role::Style::HasBorder;

	class My::Panel :strict(params)
		:does(Clay::UI::Role::Core::Container)
		:does(Clay::UI::Role::Style::HasBorder)
	{}

	# The same width on all four sides:
	my $framed = My::Panel->new(border_color => [100, 100, 100, 255], border_width => 2);

	# Per side, plus lines between the children:
	my $list = My::Panel->new(
		border_color => [100, 100, 100, 255],
		border_width => {
			left => 1, right => 1, top => 0, bottom => 0,
			between_children => 1,
		},
	);

	$framed->border_width(undef);    # no border

=head1 DESCRIPTION

C<Clay::UI::Role::Style::HasBorder> gives a widget the C<border_color>
and C<border_width> attributes. The widget adds them to its declaration
(the hash of settings Clay receives for the element) as the C<border>
part, C<< { color => ..., width => ... } >>. L<Clay::UI::Box>,
L<Clay::UI::Grid> and L<Clay::UI::Grid::Cell> compose it.

Clay emits a border render command for the element when at least one
width is greater than 0, whatever the colour, even with an alpha of 0;
C<border_color> alone draws nothing. To hide a border, set its widths to
0 (or C<border_width> to undef), not the colour's alpha to 0. The
renderer draws the border inside the element's box. Lines between
children (C<between_children>) are emitted as rectangles and only when
the colour's alpha is greater than 0. See L<Clay::XS::Structs/border>.


=head1 ATTRIBUTES

Both attributes are constructor parameters and read/write accessors.
Reading returns a new copy (or undef); writing stores a copy of the
value, so changing the array or hash afterwards does not change the
widget. A write bumps the revision (L<Clay::UI::Revision>), takes
effect at the next C<render> and returns a copy of the new value.
Values are checked when they are set, at construction or by the
accessor; a bad value dies naming the attribute.

=head2 border_color

	$widget->border_color([100, 100, 100, 255]);
	$widget->border_color({ r => 100, g => 100, b => 100, a => 255 });

The border colour: undef (the default) or a colour, either C<[$r, $g,
$b, $a]> (exactly four numbers) or C<< { r, g, b, a } >> (a channel
left out is 0). Channels are finite numbers, by convention 0 to 255.
Without a C<border_color>, a border that has a width is drawn with the
colour C<[0, 0, 0, 0]> (transparent black). Errors as for
L<Clay::UI::Role::Style::HasBackground/background_color>.

=head2 border_width

	$widget->border_width(2);
	$widget->border_width({ left => 2, bottom => 1 });

The border widths: undef (the default, no border), a number or a hash.

=over 4

=item a number

The width of all four outer sides. It is an integer from 0 to 65535
and becomes C<< { left => N, right => N, top => N, bottom => N,
between_children => 0 } >> in the declaration. Reading returns the
number.

=item a hash

Any of the keys below, each an integer from 0 to 65535; a key left out
is 0.

=over 4

=item left, right, top, bottom

The width of that outer side.

=item between_children

C<between_children> (camelCase C<betweenChildren>, read back as
C<between_children>) draws a line of that
width between neighbouring children, in the middle of the
C<child_gap>. These lines are emitted as rectangles and only when the
colour's alpha is greater than 0.

=back

=back

Dies for anything else, for example
C<Clay::UI: 'border_width' expected an integer in 0..65535, got '1.5'>.


=head1 METHODS

=head2 contribute_border

Adds the C<border> part to the widget's declaration while
C<border_color> or C<border_width> is set (see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>).

=head1 SEE ALSO

L<Clay::XS::Structs/border>, L<Clay::UI::Box>.

=cut
