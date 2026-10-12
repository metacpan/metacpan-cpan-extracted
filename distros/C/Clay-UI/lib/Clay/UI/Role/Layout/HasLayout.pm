package Clay::UI::Role::Layout::HasLayout;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::_validate qw(required clay_struct copy_value);
use Clay::UI::Revision qw(bump_revision);

role Clay::UI::Role::Layout::HasLayout {
	field $layout :param = {};

	ADJUST {
		$layout = required(clay_struct('Clay_LayoutConfig'), layout => $layout);
	}

	method layout (@new) {
		return copy_value($layout) unless @new;
		$layout = required(clay_struct('Clay_LayoutConfig'), layout => @new);
		bump_revision();
		return copy_value($layout);
	}

	# Merges the user's layout over any slice another contributor wrote
	# (e.g. Clay::UI::Grid's defaults), key by key, into a fresh hash.
	method contribute_layout ($config) {
		return unless defined $layout && scalar(keys(%$layout)) > 0;
		$config->{layout} = { %{ $config->{layout} // {} }, %$layout };
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Layout::HasLayout - layout attribute for Clay::UI widgets

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(
		sizing_grow sizing_fixed padding_all CLAY_TOP_TO_BOTTOM CLAY_ALIGN_X_CENTER
	);
	use Clay::UI::Role::Core::Container;
	use Clay::UI::Role::Layout::HasLayout;

	class My::Column :strict(params)
		:does(Clay::UI::Role::Core::Container)
		:does(Clay::UI::Role::Layout::HasLayout)
	{}

	my $column = My::Column->new(
		layout => {
			sizing           => { width => sizing_grow(), height => sizing_fixed(300) },
			padding          => padding_all(10),
			child_gap        => 4,
			child_alignment  => { x => CLAY_ALIGN_X_CENTER },
			layout_direction => CLAY_TOP_TO_BOTTOM,
		},
	);

	my $layout = $column->layout;                  # a copy
	$layout->{child_gap} = 8;
	$column->layout($layout);                      # write it back

=head1 DESCRIPTION

C<Clay::UI::Role::Layout::HasLayout> gives a widget the C<layout>
attribute: how the element is sized, how much padding it has and how it
places its children. The widget adds it to its declaration (the hash of
settings Clay receives for the element) as the C<layout> part.
L<Clay::UI::Box>, L<Clay::UI::Grid>, L<Clay::UI::Grid::Cell> and
L<Clay::UI::Grid::Row> compose it.

=head1 ATTRIBUTES

=head2 layout

	my $layout = $widget->layout;           # read: a copy
	$widget->layout({ child_gap => 8 });    # write: replaces the whole hash
	$widget->layout({});                    # back to Clay's defaults

A constructor parameter and a read/write accessor. The value is a
hashref with any of these keys (snake_case, or Clay's camelCase; the
reader returns snake_case):

=over 4

=item C<sizing>

C<< { width => $axis, height => $axis } >>, each axis built with
C<sizing_fit>, C<sizing_grow>, C<sizing_fixed> or C<sizing_percent>
from L<Clay::XS>. An axis left out is FIT. A maximum of 0 means "no maximum",
so C<sizing_fixed(0)> does not make an element 0 wide: it behaves like
FIT.

=item C<padding>

C<< { left, right, top, bottom } >>, integers 0 to 65535;
C<padding_all($n)> from L<Clay::XS> builds one. A single number dies.

=item C<child_gap>

The space between children along the layout direction, an integer 0
to 65535.

=item C<child_alignment>

C<< { x => CLAY_ALIGN_X_*, y => CLAY_ALIGN_Y_* } >>.

=item C<layout_direction>

C<CLAY_LEFT_TO_RIGHT> (the default), C<CLAY_TOP_TO_BOTTOM>,
C<CLAY_LEFT_TO_RIGHT_WRAP> (children flow into lines) or
C<CLAY_BACK_TO_FRONT> (children stacked on top of each other).

=item C<line_gap>

For C<CLAY_LEFT_TO_RIGHT_WRAP>: the space between lines, an integer 0
to 65535.

=item C<line_sizing>

For C<CLAY_LEFT_TO_RIGHT_WRAP>: C<CLAY_LINE_SIZING_FIT> or
C<CLAY_LINE_SIZING_GROW>.

=back

See L<Clay::XS::Structs/layout> for what each field does in Clay.

Default C<{}>: the declaration gets no C<layout> part and Clay uses its
defaults (FIT on both axes, no padding, no gap, C<CLAY_LEFT_TO_RIGHT>,
children at the left and top).

Reading returns a new deep copy; writing stores a deep copy of the
value, so changing a hash after passing it in, or one a read returned,
does not change the widget. A write replaces the whole hash (it does
not merge with the old one), bumps the revision
(L<Clay::UI::Revision>), takes effect at the next C<render> and returns
a copy of the new value.

The value is checked when it is set, at construction or by the
accessor, and a bad value dies naming the attribute and the path inside
it, for example:

=for highlighter language=text

	Clay::UI: 'layout' has unknown key 'paddin' (known keys: sizing, padding, ...)
	Clay::UI: 'layout.padding.left' expected an integer in 0..65535, got '-5'
	Clay::UI: 'layout.padding' expected a hash reference, got '5' (padding_all(N) builds one)
	Clay::UI: 'layout' must be defined

A key given in both spellings (C<child_gap> and C<childGap>) dies as
well.

=head1 METHODS

=head2 contribute_layout

Adds the C<layout> part to the widget's declaration (see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>). It writes
nothing while C<layout> is empty. Otherwise it merges the widget's
C<layout> over a C<layout> part another role already wrote, one
top-level key at a time: L<Clay::UI::Grid> supplies default keys that
way, and every key the user set wins. The merge is shallow: a C<sizing>
you give replaces the whole default C<sizing>.

=head1 SEE ALSO

L<Clay::XS::Structs/layout>, L<Clay::UI::Box>, L<Clay::Manual>.

=cut
