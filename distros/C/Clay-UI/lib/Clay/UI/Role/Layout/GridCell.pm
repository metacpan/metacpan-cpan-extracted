package Clay::UI::Role::Layout::GridCell;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

# A marker: Clay::UI::Grid lays out a widget composing this role as the
# cell itself, stamping the column and row sizing groups on it, instead of
# wrapping it in an unstyled Clay::UI::Grid::Cell. The methods it needs
# come from Clay::UI::Role::Core::Element (HasSizingGroup).
role Clay::UI::Role::Layout::GridCell {
	method width_group;
	method height_group;
	method _set_grid_groups;
}

1;

__END__

=head1 NAME

Clay::UI::Role::Layout::GridCell - mark a widget as a cell that Clay::UI::Grid uses as it is

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(padding_all);
	use Clay::UI::Box;
	use Clay::UI::Grid;
	use Clay::UI::Text;
	use Clay::UI::Role::Layout::GridCell;

	class My::Grid  :strict(params) :does(Clay::UI::Grid) {}
	class My::Label :strict(params) :does(Clay::UI::Text) {}

	# A cell class of your own: a Box (so it has floating and fire_event)
	# that a Grid takes as the cell.
	class My::Cell :strict(params)
		:does(Clay::UI::Box)
		:does(Clay::UI::Role::Layout::GridCell) {}

	my $cell = My::Cell->new(
		background_color => [40, 40, 60, 255],
		layout           => { padding => padding_all(6) },
	);
	$cell->add_child(My::Label->new(text => 'styled'));

	my $grid = My::Grid->new(id => 'table');
	$grid->append_row([ $cell, My::Label->new(text => 'wrapped') ]);

=head1 DESCRIPTION

L<Clay::UI::Grid> sizes its columns and rows by giving every cell a
column C<width_group> and a row C<height_group> (see
L<Clay::UI::Role::Layout::HasSizingGroup>). A widget composing
C<Clay::UI::Role::Layout::GridCell> becomes that cell itself: the grid
writes the group ids on it, so its box, background and border cover
exactly the column width and row height. Any other widget is first
wrapped in an unstyled L<Clay::UI::Grid::Cell>, and only the wrapper
gets the ids.

The role is a marker: it adds no attributes and implements no
methods. It requires Element's sizing-group methods (C<width_group>,
C<height_group> and the internal C<_set_grid_groups>), which
L<Clay::UI::Role::Core::Element> provides, so the widget must compose
that role as well (directly, or through
L<Clay::UI::Role::Core::Container>, L<Clay::UI::Box> or a superclass).
L<Clay::UI::Grid::Cell> composes it.

Write a cell class of your own when L<Clay::UI::Grid::Cell> does not
offer enough, for example C<floating> and C<fire_event> (L<Clay::UI::Box>
has both), an interaction role such as
L<Clay::UI::Role::Interaction::Pressable>, or attributes your renderer
reads. The grid keeps the cell's
C<layout> as it is:

=over 4

=item *

a C<sizing_grow()> width makes its column take a share of the space
left in a grid that is wider than its columns;

=item *

a C<sizing_fit($min, $max)> width limits that cell only (text inside
wraps); the other cells of the column still widen the column, so give
every cell of the column the same maximum, or the column does not line
up;

=item *

in a spanning row (see L<Clay::UI::Grid/append_spanning_row>), give it
a C<sizing_percent(1)> width to fill the row without widening the grid.

=back

=head1 SEE ALSO

L<Clay::UI::Grid>, L<Clay::UI::Grid::Cell>.

=cut
