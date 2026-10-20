package Clay::UI::Grid::Row;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Role::Core::Element;
use Clay::UI::Role::Layout::HasLayout;

class Clay::UI::Grid::Row :strict(params)
	:does(Clay::UI::Role::Core::Element)
	:does(Clay::UI::Role::Layout::HasLayout)
{
	field $spans     :param :reader = 0;
	field $height_id :param :reader;

	ADJUST {
		$spans = $spans ? 1 : 0;
	}

	# Clay::UI::Grid keeps a row object when it replaces the row's cells,
	# and turns it into a spanning row or back.
	method _set_spans ($new) {
		$spans = $new ? 1 : 0;
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Grid::Row - row container that Clay::UI::Grid creates for each row

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::UI::Grid;
	use Clay::UI::Text;

	class My::Grid  :strict(params) :does(Clay::UI::Grid) {}
	class My::Label :strict(params) :does(Clay::UI::Text) {}

	my $grid = My::Grid->new(id => 'grid');
	$grid->append_row([ map { My::Label->new(text => $_) } qw(a b c) ]);

	# Rows are created by Clay::UI::Grid; you only meet them when you
	# look at a grid's children.
	for my $row (@{ $grid->children }) {
		say scalar @{ $row->children }, ' cells';
	}

=head1 DESCRIPTION

C<Clay::UI::Grid::Row> is the container L<Clay::UI::Grid> creates for
every row: a left-to-right element whose children are the row's cells.
The grid sets its layout to a C<sizing_grow()> width (every row is as
wide as the grid), a FIT height and C<child_gap> equal to the grid's
C<cell_gap>.

A row composes L<Clay::UI::Role::Core::Element> and
L<Clay::UI::Role::Layout::HasLayout> only. It has no C<add_child> and
no other public way to change its children: the grid alone decides
which cells a row holds (through C<append_row>, C<insert_row>,
C<replace_row>, C<set_cell> and the other row methods of
L<Clay::UI::Grid>). Reading works as for any element widget:
C<children>, C<parent> (the grid), C<layout>, and the two facts the
grid keeps on each row, L</spans> and L</height_id>.

A row has no style of its own (no background, border or corner
radius). To colour a row, such as a header row, see
L<Clay::UI::Grid/STYLING A ROW>.

Application code does not create rows. For a container of your own,
compose L<Clay::UI::Box> in a class.

=head1 CONSTRUCTOR PARAMETERS

L<Clay::UI::Grid> creates every row with these parameters, plus
C<layout>. They are listed so that the readers below make sense; do not
create rows yourself.

=head2 spans

True for a spanning row (one cell across all columns, see
L<Clay::UI::Grid/SPANNING ROWS>). Default 0.

=head2 height_id

The packed group id the grid gives the row's cells as their
C<height_group> (see L<Clay::UI::Grid/GROUP IDS>). Required.

=head1 METHODS

=head2 spans

	my $is_spanning = $row->spans;    # 1 or 0

1 when the row is a spanning row, else 0. The grid changes it when
C<replace_spanning_row> or C<replace_row> turns a row into the other
kind; L<Clay::UI::Grid/is_spanning_row> answers the same by index.

=head2 height_id

	my $height_id = $row->height_id;

The row's height group id. It stays the same for the life of the row,
also when its cells are replaced.

=head1 SEE ALSO

L<Clay::UI::Grid>, L<Clay::UI::Grid::Cell>.

=cut
