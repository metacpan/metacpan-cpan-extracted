package Clay::UI::Grid::Cell;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::UI::Role::Core::Container;
use Clay::UI::Role::Layout::GridCell;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Style::HasBackground;
use Clay::UI::Role::Style::HasBorder;
use Clay::UI::Role::Style::HasCornerRadius;

class Clay::UI::Grid::Cell :strict(params)
	:does(Clay::UI::Role::Core::Container)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Style::HasBackground)
	:does(Clay::UI::Role::Style::HasBorder)
	:does(Clay::UI::Role::Style::HasCornerRadius)
	:does(Clay::UI::Role::Layout::GridCell)
{}

1;

__END__

=head1 NAME

Clay::UI::Grid::Cell - styled cell container for Clay::UI::Grid

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(padding_all CLAY_ALIGN_X_RIGHT);
	use Clay::UI;
	use Clay::UI::Grid;
	use Clay::UI::Grid::Cell;
	use Clay::UI::Text;

	class My::Grid  :strict(params) :does(Clay::UI::Grid) {}
	class My::Label :strict(params) :does(Clay::UI::Text) {}

	my $header = Clay::UI::Grid::Cell->new(
		layout           => { padding => padding_all(8) },
		background_color => [55, 90, 140, 255],
	);
	$header->add_child(My::Label->new(text => 'Total'));

	my $value = Clay::UI::Grid::Cell->new(
		layout => {
			padding         => padding_all(8),
			child_alignment => { x => CLAY_ALIGN_X_RIGHT },
		},
		background_color => [30, 30, 30, 255],
	);
	$value->add_child(My::Label->new(text => '1,234.00'));

	my $grid = My::Grid->new(id => 'report');
	$grid->append_row([ $header, $value ]);

	my $ui = Clay::UI->new(width => 800, height => 600, root => $grid);
	my $commands = $ui->render;

=head1 DESCRIPTION

C<Clay::UI::Grid::Cell> is a ready-to-use class (not a role) for one
cell of a L<Clay::UI::Grid>. Pass it in a row to style the cell or to
align its content; the grid uses it as the cell itself and writes the
column and row group ids on it, so its background, border and padding
cover exactly the column width and the row height. See
L<Clay::UI::Grid/CELLS AND WRAPPED WIDGETS>.

The grid also creates unstyled C<Clay::UI::Grid::Cell> objects itself,
around every widget you pass that is not a cell.

A cell is a container with layout and style, but without floating and
without C<fire_event>. It composes:

=over 4

=item *

L<Clay::UI::Role::Core::Container>: C<add_child> and the other child
methods put content into it (and through it
L<Clay::UI::Role::Core::Element>: C<id>, C<children>, C<width_group>,
C<height_group>, C<parent>, C<on>, ...);

=item *

L<Clay::UI::Role::Layout::HasLayout>: C<layout>;

=item *

L<Clay::UI::Role::Style::HasBackground>: C<background_color>;

=item *

L<Clay::UI::Role::Style::HasBorder>: C<border_color>, C<border_width>;

=item *

L<Clay::UI::Role::Style::HasCornerRadius>: C<corner_radius>;

=item *

L<Clay::UI::Role::Layout::GridCell>: the marker that makes a grid use
it as the cell.

=back

For a cell with more abilities (floating, events, interaction), write a
class of your own that composes L<Clay::UI::Role::Layout::GridCell>.

=head1 CONSTRUCTOR PARAMETERS

The class is C<:strict(params)>: an unknown parameter dies.

=head2 layout

How the cell sizes itself and places its content; see
L<Clay::UI::Role::Layout::HasLayout/layout>. Default C<{}> (FIT on both
axes). The width sizing changes the column; see
L<Clay::UI::Grid/CELLS AND WRAPPED WIDGETS>.

=head2 background_color

See L<Clay::UI::Role::Style::HasBackground/background_color>.

=head2 border_color

See L<Clay::UI::Role::Style::HasBorder/border_color>.

=head2 border_width

See L<Clay::UI::Role::Style::HasBorder/border_width>.

=head2 corner_radius

See L<Clay::UI::Role::Style::HasCornerRadius/corner_radius>.

=head2 id

See L<Clay::UI::Role::Core::Element/id>.

=head2 width_group

Normally left alone: the grid writes its column id here. A non-zero
id you give stays, and the cell then takes part in your group instead
of the column; see L<Clay::UI::Grid/Overriding group ids> and
L<Clay::UI::Role::Layout::HasSizingGroup/width_group>.

=head2 height_group

Like L</width_group>, for the row.

All of them are read/write accessors as well, as documented in the
linked roles.

=head1 SEE ALSO

L<Clay::UI::Grid>, L<Clay::UI::Role::Layout::GridCell>,
L<Clay::UI::Box>.

=cut
