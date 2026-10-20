package Clay::UI::Role::Style::HasCornerRadius;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::_validate qw(optional clay_struct copy_value);
use Clay::UI::Revision qw(bump_revision);

role Clay::UI::Role::Style::HasCornerRadius {
	field $corner_radius :param = undef;

	ADJUST {
		$corner_radius = optional(clay_struct('Clay_CornerRadius'), corner_radius => $corner_radius);
	}

	method corner_radius (@new) {
		return copy_value($corner_radius) unless @new;
		$corner_radius = optional(clay_struct('Clay_CornerRadius'), corner_radius => @new);
		bump_revision();
		return copy_value($corner_radius);
	}

	method contribute_corner_radius ($config) {
		return unless defined $corner_radius;

		$config->{corner_radius} = ref $corner_radius
			? copy_value($corner_radius)
			: { top_left => $corner_radius, top_right => $corner_radius, bottom_left => $corner_radius, bottom_right => $corner_radius };
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Style::HasCornerRadius - corner radius attribute for Clay::UI widgets

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI::Role::Core::Container;
	use Clay::UI::Role::Style::HasCornerRadius;

	class My::Panel :strict(params)
		:does(Clay::UI::Role::Core::Container)
		:does(Clay::UI::Role::Style::HasCornerRadius)
	{}

	# The same radius on all four corners:
	my $card = My::Panel->new(corner_radius => 6);

	# Per corner: rounded at the top only.
	my $tab = My::Panel->new(
		corner_radius => {
			top_left    => 6, top_right    => 6,
			bottom_left => 0, bottom_right => 0,
		},
	);

=head1 DESCRIPTION

C<Clay::UI::Role::Style::HasCornerRadius> gives a widget the
C<corner_radius> attribute. The widget adds it to its declaration (the
hash of settings Clay receives for the element) as C<corner_radius>
(C<cornerRadius> for Clay). Clay does not use it for layout; it passes
it on in the element's C<RECTANGLE>, C<BORDER>, C<IMAGE> and C<CUSTOM>
render commands, for the renderer to round the corners.
L<Clay::UI::Box>, L<Clay::UI::Grid> and L<Clay::UI::Grid::Cell> compose
it.


=head1 ATTRIBUTES

=head2 corner_radius

	my $radius = $widget->corner_radius;    # read: a copy, or undef
	$widget->corner_radius(8);
	$widget->corner_radius({ top_left => 8, bottom_right => 8 });

A constructor parameter and a read/write accessor. The value is one of:

=over 4

=item undef

No corner radius (the default); the declaration gets no corner radius.

=item a number

The radius of all four corners. It becomes C<< { top_left => N,
top_right => N, bottom_left => N, bottom_right => N } >> in the
declaration. Reading returns the number.

=item a hash

Any of the keys C<top_left>, C<top_right>, C<bottom_left> and
C<bottom_right> (or Clay's camelCase; reading returns snake_case); a
key left out is 0.

=back

The radii are finite numbers; Clay::UI does not reject negative ones.
See L<Clay::XS::Structs/cornerRadius>.

Reading returns a new copy (or undef); writing stores a copy of the
value. A write bumps the revision (L<Clay::UI::Revision>), takes effect
at the next C<render> and returns a copy of the new value. The value is
checked when it is set; anything else dies naming the attribute, for
example C<Clay::UI: 'corner_radius' has unknown key ...>.

=head1 METHODS

=head2 contribute_corner_radius

Adds C<corner_radius> to the widget's declaration while the attribute
is set (see L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>).

=head1 SEE ALSO

L<Clay::XS::Structs/cornerRadius>, L<Clay::UI::Box>.

=cut
