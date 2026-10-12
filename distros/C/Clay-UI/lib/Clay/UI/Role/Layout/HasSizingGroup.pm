package Clay::UI::Role::Layout::HasSizingGroup;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Scalar::Util qw(looks_like_number);

use Clay::UI::_validate qw(required validate_group_id);
use Clay::UI::Revision qw(bump_revision);

role Clay::UI::Role::Layout::HasSizingGroup {
	field $width_group  :param = 0;
	field $height_group :param = 0;

	# The lease of the Grid whose packed ids this widget carries: while the
	# widget holds them, no other Grid can be given the same grid id.
	field $_grid_lease;

	ADJUST {
		$width_group  = required(\&validate_group_id, width_group  => $width_group);
		$height_group = required(\&validate_group_id, height_group => $height_group);
	}

	method width_group (@new) {
		return $self->_group_in_effect($width_group) unless @new;
		my $written = _write_group(width_group => $width_group, @new);
		bump_revision() if $written != $width_group;
		$width_group = $written;
		return $self->_group_in_effect($width_group);
	}

	method height_group (@new) {
		return $self->_group_in_effect($height_group) unless @new;
		my $written = _write_group(height_group => $height_group, @new);
		bump_revision() if $written != $height_group;
		$height_group = $written;
		return $self->_group_in_effect($height_group);
	}

	# The group the widget is sized with: an id a Grid packed means nothing
	# once that Grid is freed, so cells kept from it do not keep equalizing
	# with each other.
	method _group_in_effect ($group) {
		return $group unless defined $_grid_lease && $_grid_lease->owns_group($group);
		return $_grid_lease->is_live ? $group : 0;
	}

	# Writing back the current id is a no-op, even for an id Grid owns.
	sub _write_group ($name, $current, @new) {
		return $current
			if @new == 1 && defined $new[0] && !ref $new[0] && looks_like_number($new[0]) && $new[0] == $current;
		return required(\&validate_group_id, $name => @new);
	}

	# Clay::UI::Grid stamps its packed (grid id << 20 | index) group ids
	# here, with the lease of its grid id (undef once none are left); they
	# are outside the range users may set.
	method _set_grid_groups ($width, $height, $lease) {
		$width_group  = $width;
		$height_group = $height;
		$_grid_lease  = $lease;
		return;
	}

	method contribute_sizing_group ($config) {
		my $width  = $self->_group_in_effect($width_group);
		my $height = $self->_group_in_effect($height_group);
		return if $width == 0 && $height == 0;
		$config->{sizing_group} = { width => $width, height => $height };
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Role::Layout::HasSizingGroup - give unrelated widgets a common width or height

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(padding_all CLAY_TOP_TO_BOTTOM);
	use Clay::UI;
	use Clay::UI::Box;
	use Clay::UI::Text;

	class My::Box   :strict(params) :does(Clay::UI::Box) {}
	class My::Label :strict(params) :does(Clay::UI::Text) {}

	# Form labels in different rows, all as wide as the widest one.
	my $form = My::Box->new(id => 'form', layout => { layout_direction => CLAY_TOP_TO_BOTTOM });
	for my $caption ('Name', 'E-mail address', 'Phone') {
		my $row   = My::Box->new;
		my $label = My::Box->new(width_group => 1, layout => { padding => padding_all(4) });
		$label->add_child(My::Label->new(text => $caption));
		$row->add_child($label, My::Label->new(text => '...'));
		$form->add_child($row);
	}

	my $ui = Clay::UI->new(width => 800, height => 600, root => $form);
	my $commands = $ui->render;

=head1 DESCRIPTION

C<Clay::UI::Role::Layout::HasSizingGroup> gives a widget the
C<width_group> and C<height_group> attributes. Every element widget has
them: L<Clay::UI::Role::Core::Element> composes this role.

Elements with the same non-zero C<width_group> get the same width,
wherever they are in the tree: the width of the widest member. The same
holds for C<height_group> and heights. Clay first sizes each element to
its content, then raises every member of a group to the largest size in
the group, before it hands out space to GROW elements. The width and
height ids are separate: width group 1 and height group 1 have nothing
to do with each other.

Typical uses are form labels of a common width and buttons of a common
height in different containers. L<Clay::UI::Grid> sizes its columns and
rows with sizing groups and assigns the ids itself; use this role
directly for alignment a grid does not cover.

Sizing groups are a feature of the C<clay.h> shipped with this
distribution (a patch to upstream Clay); see
L<Clay::XS::Structs/sizingGroup>.

=head2 How sizing types take part

=over 4

=item *

FIT and GROW members are equalized. For GROW members, the group size
is computed from their content (FIT) size, before GROW space is shared
out.

=item *

FIXED and PERCENT members are ignored: their size does not depend on
their content, so they neither raise the group size nor are raised.

=item *

A member never exceeds its own maximum: with C<sizing_fit(0, 50)> it
stays at most 50 wide even if another member is wider.

=item *

Groups may nest: a member may contain members of other groups (a grid
inside a grid cell). Clay repeats the equalization until the sizes
settle. Groups that contain each other on the same axis are a cycle,
reported as the Clay error C<CLAY_ERROR_TYPE_SIZING_GROUP_CYCLE>.

=item *

Members share the group's largest I<minimum> as well (for text, its
longest word), so a parent that is too small compresses them like any
other children, down to that minimum, and text inside them wraps.
Members stay aligned as long as their parents compress alike (the rows
of a grid do); members in differently sized parents may end up with
different widths. Give members a maximum (C<sizing_fit(0, 200)>,
C<sizing_grow(0, 200)>) or a fixed width to wrap text at a chosen
width instead.

=back

=head1 ATTRIBUTES

=head2 width_group

	my $group = $widget->width_group;    # 0: no group
	$widget->width_group(17);

The width group of the widget: an integer from 0 to 2**20 - 1
(1048575). C<0>, the default, means no group. A constructor parameter
and a read/write accessor; a write of another group bumps the revision
(L<Clay::UI::Revision>; writing the current group back changes nothing),
takes effect at the next C<render> and returns the group in effect.

Dies with
C<Clay::UI: 'width_group' must be an integer in 0..1048575 (larger ids are reserved for Clay::UI::Grid)>
for anything else.


Ids above that range belong to L<Clay::UI::Grid>, which writes them on
the cells it lays out (see L<Clay::UI::Grid/GROUP IDS>). On such a
cell:

=over 4

=item *

reading returns the grid's id; writing that same value back is allowed
and changes nothing, writing another id above the range dies;

=item *

the grid's id is in effect while the grid (or a grid sharing its
columns) exists; on a cell kept after every such grid is freed it reads
C<0> and the cell is sized alone;

=item *

a cell removed from its grid drops the grid's ids (they become C<0>);
an id you set yourself stays.

=back

=head2 height_group

	$widget->height_group(3);

The height group of the widget; the same rules as L</width_group>.

=head1 METHODS

=head2 contribute_sizing_group

Adds the C<sizing_group> part (C<< { width => ..., height => ... } >>)
to the widget's declaration while at least one of the two groups in
effect is non-zero (see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>).

=head1 SEE ALSO

L<Clay::UI::Grid>, L<Clay::XS::Structs/sizingGroup>, L<Clay::Manual>.

=cut
