package Clay::UI::Grid;
our $VERSION = '0.06';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;

use Clay::XS qw(sizing_fit sizing_grow sizing_percent CLAY_LEFT_TO_RIGHT CLAY_TOP_TO_BOTTOM);
use Clay::UI::_validate qw(required clay_field is_index shown_value USER_GROUP_ID_MAX);
use Clay::UI::Revision qw(bump_revision);
use Clay::UI::Grid::Row;
use Clay::UI::Grid::Cell;
use Clay::UI::Role::Core::Element;
use Clay::UI::Role::Layout::GridCell;
use Clay::UI::Role::Layout::HasLayout;
use Clay::UI::Role::Style::HasBackground;
use Clay::UI::Role::Style::HasBorder;
use Clay::UI::Role::Style::HasCornerRadius;
use Clay::UI::_error qw(croak_ui);

# Group-id encoding: (grid_id << _LOCAL_BITS) | local_index, in Clay's
# 32-bit sizingGroup.
#   - local in 1..USER_GROUP_ID_MAX (_LOCAL_BITS bits, 20), one slot per
#     axis-bucket within an id space; every packed id is above the user range
#   - grid_id in 1.._GRID_ID_MAX, the bits left (12, so 4095), one slot per
#     live id space
# Width-axis and height-axis ids share the local space because Clay equalizes
# per-axis only (width vs height live in separate equality buckets).
use constant {
	_LOCAL_BITS => length(sprintf '%b', USER_GROUP_ID_MAX),
	_LOCAL_MAX  => USER_GROUP_ID_MAX,
};
use constant _GRID_ID_BITS => 32 - _LOCAL_BITS;
use constant _GRID_ID_MAX  => (1 << _GRID_ID_BITS) - 1;

# Process-global pool of 12-bit grid-ids. Monotonic counter for fresh ids;
# the free-list receives ids released when an id space is destroyed, so
# long-running programs that churn grids do not exhaust the namespace.
my @_FREE_GRID_IDS;
my $_NEXT_GRID_ID = 1;

sub _claim_grid_id {
	return shift @_FREE_GRID_IDS if @_FREE_GRID_IDS;
	croak_ui "Clay::UI::Grid: grid-id pool exhausted (max " . _GRID_ID_MAX . " live grids)"
		if $_NEXT_GRID_ID > _GRID_ID_MAX;
	return $_NEXT_GRID_ID++;
}

sub _release_grid_id ($id) {
	push @_FREE_GRID_IDS, $id;
	return;
}

sub _pack_group_id ($grid_id, $local) {
	croak_ui "Clay::UI::Grid: grid_id $grid_id out of range 1.." . _GRID_ID_MAX
		unless $grid_id >= 1 && $grid_id <= _GRID_ID_MAX;
	croak_ui "Clay::UI::Grid: local index $local out of range 1.." . _LOCAL_MAX
		unless $local >= 1 && $local <= _LOCAL_MAX;
	return ($grid_id << _LOCAL_BITS) | $local;
}

sub _is_grid_owned_group ($group_id) {
	return $group_id > _LOCAL_MAX;
}

# Cells leaving a grid drop the group ids it stamped, so a cell attached
# elsewhere afterwards is no longer sized with this grid's columns and rows.
sub _drop_grid_groups (@wrappers) {
	for my $wrapper (@wrappers) {
		my ($width, $height) = ($wrapper->width_group, $wrapper->height_group);
		$wrapper->_set_grid_groups(
			_is_grid_owned_group($width)  ? 0 : $width,
			_is_grid_owned_group($height) ? 0 : $height,
			undef,
		);
	}
	return;
}

# Holds one grid id and returns it to the pool when the last holder is
# freed: the id space, and every cell that still carries ids packed with
# it (a cell kept after its Grid is gone must not share ids with the next
# Grid). It also knows whether its id space still exists: ids packed for
# grids that are all freed size nothing (see
# Clay::UI::Role::Layout::HasSizingGroup). Keeping the id in its own
# object leaves DESTROY free for classes that consume the Grid role.
package Clay::UI::Grid::_IdLease {
	use Scalar::Util qw(weaken);

	sub new ($class, $owner) {
		my $self = bless { id => Clay::UI::Grid::_claim_grid_id(), owner => $owner }, $class;
		weaken $self->{owner};
		return $self;
	}

	sub id ($self) { $self->{id} }

	# True while the id space that claimed the id exists.
	sub is_live ($self) { defined $self->{owner} }

	# True for a group id packed with this lease's grid id.
	sub owns_group ($self, $group) { ($group >> Clay::UI::Grid::_LOCAL_BITS) == $self->{id} }

	sub DESTROY ($self) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
		Clay::UI::Grid::_release_grid_id($self->{id});
		return;
	}
}

# The group ids of one Grid, or of several Grids that share their columns:
# one grid id (the lease), the width id of every column and the height id
# of every row. Grids sharing an id space give their column N the same
# width id, so Clay sizes those columns together, and never give two rows
# the same height id. Every Grid holds its id space; the lease only
# references it weakly.
class Clay::UI::Grid::_IdSpace :strict(params) {
	field $lease;
	field $next_width_local  = 1;
	field $next_height_local = 1;
	field @free_height_ids;
	field @col_width_ids;    # column index -> packed width-axis group id
	field $grids_width_id;   # the width id of the grids themselves, once they share

	ADJUST {
		$lease = Clay::UI::Grid::_IdLease->new($self);
	}

	method lease () { return $lease }

	# The width id that makes the grids sharing this space as wide as each
	# other.
	method grids_width_id () {
		return $grids_width_id //= Clay::UI::Grid::_pack_group_id($lease->id, $next_width_local++);
	}

	# Width ids for columns 0..$width-1. Ids for new columns are only
	# computed here; commit_col_ids records them once nothing can fail.
	method col_ids_for ($width) {
		my @ids  = @col_width_ids;
		my $next = $next_width_local;
		push @ids, Clay::UI::Grid::_pack_group_id($lease->id, $next++) while @ids < $width;
		return (\@ids, $next);
	}

	method commit_col_ids ($ids, $next) {
		@col_width_ids    = @$ids;
		$next_width_local = $next;
		return;
	}

	# Height id for a new row: a released one first, else a fresh one.
	method claim_row_height_id () {
		return pop @free_height_ids if @free_height_ids;
		my $id = Clay::UI::Grid::_pack_group_id($lease->id, $next_height_local);
		$next_height_local++;
		return $id;
	}

	method release_row_height_id ($id) {
		push @free_height_ids, $id;
		return;
	}
}

role Clay::UI::Grid
	:does(Clay::UI::Role::Core::Element)
	:does(Clay::UI::Role::Layout::HasLayout)
	:does(Clay::UI::Role::Style::HasBackground)
	:does(Clay::UI::Role::Style::HasBorder)
	:does(Clay::UI::Role::Style::HasCornerRadius)
{
	use Scalar::Util qw(blessed);

	field $cell_gap :param = 0;
	field $row_gap  :param = 0;

	# The grid's children are its rows (Clay::UI::Grid::Row), and a row's
	# children are its cell wrappers. For each input cell: a widget
	# composing Clay::UI::Role::Layout::GridCell is used directly (so the
	# caller's styling becomes the visible cell); anything else is wrapped
	# in an unstyled Clay::UI::Grid::Cell. The wrapper is what Clay sees
	# with the sizing-group ids set, so its rendered box is exactly the
	# equalized column-width x row-height. A spanning row has one wrapper.
	# Each row carries its span flag and its height id.
	field $_ids;              # the Clay::UI::Grid::_IdSpace

	ADJUST :params ( :$share_columns_with = undef ) {
		$cell_gap = required(clay_field('Clay_LayoutConfig', 'childGap'), cell_gap => $cell_gap);
		$row_gap  = required(clay_field('Clay_LayoutConfig', 'childGap'), row_gap  => $row_gap);
		$_ids     = defined $share_columns_with
			? _id_space_of($share_columns_with)
			: Clay::UI::Grid::_IdSpace->new;
		if (defined $share_columns_with) {
			my $width_id = $_ids->grids_width_id;
			$_->_take_shared_width($width_id) for $share_columns_with, $self;
		}
		undef $share_columns_with;    # ADJUST's pad would keep the other grid alive
	}

	# Grids sharing columns are as wide as the widest of them, so a grid
	# whose rows all span (an empty body below a header) is still as wide
	# as the columns. A width group the user gave the grid stays.
	method _take_shared_width ($width_id) {
		my $width = $self->width_group;
		return unless $width == 0 || _is_grid_owned_group($width);
		$self->_set_grid_groups($width_id, $self->height_group, $_ids->lease);
		return;
	}

	sub _id_space_of ($grid) {
		croak_ui "Clay::UI::Grid: share_columns_with must be a Clay::UI::Grid, got "
			. (blessed $grid ? ref $grid : defined $grid ? "'$grid'" : 'undef')
			unless blessed $grid && $grid->DOES('Clay::UI::Grid');
		return $grid->_id_space;
	}

	method _id_space () { return $_ids }

	method cell_wrappers () {
		return [ map { $_->children } @{ $self->children } ];
	}

	method row_count () { return $self->child_count; }

	method is_spanning_row ($index) {
		$self->_check_row_index($index);
		return $self->_row($index)->spans;
	}

	# The Clay::UI::Grid::Row at a checked index.
	method _row ($index) {
		return $self->child_at($index);
	}

	method row_gap (@new) {
		return $row_gap unless @new;
		$row_gap = required(clay_field('Clay_LayoutConfig', 'childGap'), row_gap => @new);
		bump_revision();
		return $row_gap;
	}

	# The inter-cell gap is baked into each row's layout when the row is
	# built, so a write updates every existing row as well.
	method cell_gap (@new) {
		return $cell_gap unless @new;
		$cell_gap = required(clay_field('Clay_LayoutConfig', 'childGap'), cell_gap => @new);
		$_->layout({ %{ $_->layout }, child_gap => $cell_gap }) for @{ $self->children };
		bump_revision();
		return $cell_gap;
	}

	# Validates widgets that end up below this grid as a whole (the grid
	# is the anchor for the cycle check).
	method _validate_cells (@cells) {
		Clay::UI::Role::Core::Element::_validate_attachment($self, @cells);
		return;
	}

	method _validate_row ($row_cells) {
		croak_ui "Clay::UI::Grid: row must be an arrayref" unless ref $row_cells eq 'ARRAY';
		$self->_validate_cells(@$row_cells);
		return;
	}

	sub _is_grid_cell ($widget) {
		return $widget->DOES('Clay::UI::Role::Layout::GridCell');
	}

	# Stamps the grid's group ids on a wrapper. An axis whose group was set
	# by the user (a cross-grid alignment id below 2**20) is left alone; an
	# undef id clears an axis the grid owns (a spanning row belongs to no
	# column).
	method _stamp ($wrapper, $width_id, $height_id) {
		my $width  = $wrapper->width_group;
		my $height = $wrapper->height_group;
		my $stamp_width  = $width  == 0 || _is_grid_owned_group($width);
		my $stamp_height = $height == 0 || _is_grid_owned_group($height);
		$wrapper->_set_grid_groups(
			$stamp_width  ? $width_id // 0 : $width,
			$stamp_height ? $height_id     : $height,
			($stamp_width || $stamp_height) ? $_ids->lease : undef,
		);
		return $wrapper;
	}

	# Wraps one validated input cell into a cell the grid lays out (see
	# $_ids) and stamps its (column, row) group ids. A wrapper the grid
	# makes adopts the cell without announcing it: the cell is announced
	# once its row is in the grid.
	method _wrap_cell ($cell, $width_id, $height_id) {
		my $wrapper = $cell;
		unless (_is_grid_cell($cell)) {
			$wrapper = Clay::UI::Grid::Cell->new(
				layout => { sizing => { width => sizing_fit(), height => sizing_fit() } },
			);
			$wrapper->_adopt_children($cell);
		}
		return $self->_stamp($wrapper, $width_id, $height_id);
	}

	# The single cell of a spanning row: it belongs to no column and is
	# as wide as the grid without widening it (a wrapper the grid makes is
	# 100% wide, which Clay does not count when it fits the grid to its
	# rows; a cell of your own keeps its layout).
	method _wrap_spanning_cell ($cell, $height_id) {
		my $wrapper = $cell;
		unless (_is_grid_cell($cell)) {
			$wrapper = Clay::UI::Grid::Cell->new(
				layout => { sizing => { width => sizing_percent(1), height => sizing_fit() } },
			);
			$wrapper->_adopt_children($cell);
		}
		return $self->_stamp($wrapper, undef, $height_id);
	}

	method _wrap_row ($row_cells, $col_ids, $height_id) {
		return map { $self->_wrap_cell($row_cells->[$_], $col_ids->[$_], $height_id) } 0 .. $#$row_cells;
	}

	# Rows stretch to the grid's width, so cells with a grow width share
	# the space left in the grid. Unstyled rows paint nothing either way.
	# The row adopts its wrappers; _insert_row_record announces the whole
	# row once it is in the grid.
	method _new_row ($wrappers, $spans, $height_id) {
		my $row = Clay::UI::Grid::Row->new(
			layout => {
				sizing           => { width => sizing_grow(), height => sizing_fit() },
				layout_direction => CLAY_LEFT_TO_RIGHT,
				child_gap        => $cell_gap,
			},
			spans     => $spans,
			height_id => $height_id,
		);
		$row->_adopt_children(@$wrappers);
		return $row;
	}

	# Builds a complete row for index $index. Everything that can fail
	# (validation, then id allocation, the height id last) happens before
	# the grid changes; building the row cannot fail, and the only error
	# after the change is a tree_changed hook's, which _splice_children
	# rethrows once the row is in place.
	method _insert_new_row ($index, $row_cells) {
		$self->_validate_row($row_cells);
		my ($col_ids, $next_width_local) = $_ids->col_ids_for(scalar @$row_cells);
		my $height_id = $_ids->claim_row_height_id;

		$_ids->commit_col_ids($col_ids, $next_width_local);
		my @wrappers = $self->_wrap_row($row_cells, $col_ids, $height_id);
		$self->_insert_row_record($index, \@wrappers, 0, $height_id);
		return;
	}

	method _insert_new_spanning_row ($index, $cell) {
		$self->_validate_cells($cell);
		my $height_id = $_ids->claim_row_height_id;
		my $wrapper   = $self->_wrap_spanning_cell($cell, $height_id);
		$self->_insert_row_record($index, [ $wrapper ], 1, $height_id);
		return;
	}

	method _insert_row_record ($index, $wrappers, $spans, $height_id) {
		$self->_splice_children($index, 0, $self->_new_row($wrappers, $spans, $height_id));
		return;
	}

	method _check_row_index ($index) {
		my $row_count = $self->row_count;
		croak_ui "Clay::UI::Grid: row index " . shown_value($index) . " out of range 0.." . ($row_count - 1)
			unless is_index($index) && $index < $row_count;
		return;
	}

	method _check_insert_index ($index) {
		my $row_count = $self->row_count;
		croak_ui "Clay::UI::Grid: insert index " . shown_value($index) . " out of range 0..$row_count"
			unless is_index($index) && $index <= $row_count;
		return;
	}

	method append_row ($row_cells) {
		$self->_insert_new_row($self->row_count, $row_cells);
		return $self;
	}

	method insert_row ($index, $row_cells) {
		$self->_check_insert_index($index);
		$self->_insert_new_row($index, $row_cells);
		return $self;
	}

	method append_spanning_row ($cell) {
		$self->_insert_new_spanning_row($self->row_count, $cell);
		return $self;
	}

	method insert_spanning_row ($index, $cell) {
		$self->_check_insert_index($index);
		$self->_insert_new_spanning_row($index, $cell);
		return $self;
	}

	method remove_row ($index) {
		$self->_check_row_index($index);
		my $row = $self->_row($index);
		$_ids->release_row_height_id($row->height_id);
		_drop_grid_groups(@{ $row->children });
		$self->_splice_children($index, 1);
		return $self;
	}

	method clear_rows () {
		my @rows = @{ $self->children };
		$_ids->release_row_height_id($_->height_id) for @rows;
		_drop_grid_groups(map { @{ $_->children } } @rows);
		$self->_splice_children(0, scalar @rows);
		return $self;
	}

	method replace_row ($index, $row_cells) {
		$self->_check_row_index($index);
		$self->_validate_row($row_cells);
		my ($col_ids, $next_width_local) = $_ids->col_ids_for(scalar @$row_cells);

		$_ids->commit_col_ids($col_ids, $next_width_local);
		my @wrappers = $self->_wrap_row($row_cells, $col_ids, $self->_row($index)->height_id);
		$self->_replace_row_record($index, \@wrappers, 0);
		return $self;
	}

	method replace_spanning_row ($index, $cell) {
		$self->_check_row_index($index);
		$self->_validate_cells($cell);
		my $wrapper = $self->_wrap_spanning_cell($cell, $self->_row($index)->height_id);
		$self->_replace_row_record($index, [ $wrapper ], 1);
		return $self;
	}

	method _replace_row_record ($index, $wrappers, $spans) {
		my $row = $self->_row($index);
		my $old = $row->children;
		_drop_grid_groups(@$old);
		$row->_set_spans($spans);
		$row->_splice_children(0, scalar @$old, @$wrappers);
		return;
	}

	method set_cell ($r, $c, $widget) {
		$self->_check_row_index($r);
		my $row = $self->_row($r);
		croak_ui "Clay::UI::Grid: row $r spans all columns; use replace_spanning_row or replace_row"
			if $row->spans;
		my $current_row_len = $row->child_count;
		croak_ui "Clay::UI::Grid: col index " . shown_value($c) . " out of range 0.." . $current_row_len
			unless is_index($c) && $c <= $current_row_len;
		$self->_validate_cells($widget);
		my ($col_ids, $next_width_local) = $_ids->col_ids_for($c + 1);

		$_ids->commit_col_ids($col_ids, $next_width_local);
		my $wrapper  = $self->_wrap_cell($widget, $col_ids->[$c], $row->height_id);
		my $replaced = $c < $current_row_len ? 1 : 0;
		_drop_grid_groups($row->child_at($c)) if $replaced;
		$row->_splice_children($c, $replaced, $wrapper);
		return $self;
	}

	# Puts the rows in a new order without detaching any of them: row $k
	# becomes the row that was at $order->[$k]. The cells keep their
	# parents, focus and hover.
	method reorder_rows ($order) {
		$self->_reorder_children($order);
		return $self;
	}

	# The default outer layout (rows stacked TOP_TO_BOTTOM, row_gap between
	# them), merged under any layout slice already present so keys from the
	# user's 'layout' win one by one, whatever order contributors run in.
	method contribute_grid_defaults ($config) {
		$config->{layout} = {
			sizing           => { width => sizing_fit(), height => sizing_fit() },
			layout_direction => CLAY_TOP_TO_BOTTOM,
			child_gap        => $row_gap,
			%{ $config->{layout} // {} },
		};
		return;
	}
}

1;

__END__

=head1 NAME

Clay::UI::Grid - table widget role for Clay::UI with automatically sized columns and rows

=head1 SYNOPSIS

	use v5.22;
	use Object::Pad;
	use Clay::XS qw(CLAY_ALIGN_X_RIGHT);
	use Clay::UI;
	use Clay::UI::Grid;
	use Clay::UI::Grid::Cell;
	use Clay::UI::Text;

	class My::Grid  :strict(params) :does(Clay::UI::Grid) {}
	class My::Label :strict(params) :does(Clay::UI::Text) {}

	sub label ($text) { return My::Label->new(text => $text) }

	# A cell with its content aligned to the right, for numbers.
	sub amount ($text) {
		my $cell = Clay::UI::Grid::Cell->new(
			layout => { child_alignment => { x => CLAY_ALIGN_X_RIGHT } },
		);
		$cell->add_child(label($text));
		return $cell;
	}

	my $grid = My::Grid->new(id => 'people', cell_gap => 8, row_gap => 4);
	$grid->append_row([ label('Name'),  label('E-mail'),            label('Amount') ]);
	$grid->append_row([ label('Alice'), label('alice@example.com'), amount('1234') ]);
	$grid->append_spanning_row(label('Guests'));    # one cell across all columns
	$grid->append_row([ label('Bob'),   label('bob@example.com'),   amount('7') ]);

	# Change it later; the next render shows the change.
	$grid->set_cell(0, 2, label('Total'));
	$grid->reorder_rows([ 0, 3, 2, 1 ]);
	$grid->remove_row(2);

	my $ui = Clay::UI->new(width => 800, height => 600, root => $grid);
	my $commands = $ui->render;

=head1 DESCRIPTION

C<Clay::UI::Grid> lays out widgets in rows and columns, like a table:
every column is as wide as its widest cell and every row as tall as its
tallest cell. You add rows of widgets; the grid works out the sizes in
the same layout pass as the rest of the UI.

=for text Figure: images/grid.png in the distribution.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-clay-xs/v0.06/images/grid.png" alt="A table with a dark header row Name, E-mail, Amount; the rows Alice and Bob; a grey row reading Guests (a spanning row) across all columns; and the row Carol. Every column is as wide as its widest cell and the amounts are right-aligned."></p>

=end html

Like every widget in Clay::UI it is a role: compose it in a class of
your own (as C<My::Grid> above) to get a widget you can construct. A
grid can be the root of a L<Clay::UI> or a child of any container, and
a cell may hold another grid.

This module is a guide as well as a reference. The sections up to
L</CONSTRUCTOR PARAMETERS> explain how to build grids; the reference
follows; L</GROUP IDS> at the end explains the ids the grid uses
internally.

=head2 How it works

A grid is a column of rows. Each row is a L<Clay::UI::Grid::Row>, a
left-to-right container; the grid stacks the rows top to bottom. Each
widget you pass becomes one cell of a row.

Clay lays out every row on its own, so cells in different rows know
nothing of each other. The grid connects them with sizing groups (see
L<Clay::UI::Role::Layout::HasSizingGroup>): it gives every cell of a
column the same C<width_group> and every cell of a row the same
C<height_group>, and Clay raises all members of a group to the size of
the largest one.

The grid's children are its rows. C<children> returns the
L<Clay::UI::Grid::Row> objects, each of which knows whether it spans
(L<Clay::UI::Grid::Row/spans>) and its height id
(L<Clay::UI::Grid::Row/height_id>); use L</cell_wrappers> to get at the
cells. The grid composes L<Clay::UI::Role::Core::Element> but not
L<Clay::UI::Role::Core::Container>: there is no C<add_child>, only the
row methods below change it.

=head1 BUILDING A GRID

Create the grid empty, then add rows:

	my $grid = My::Grid->new(cell_gap => 8, row_gap => 4);
	$grid->append_row([ $name_label, $size_label ]);
	$grid->insert_row(0, [ $header_name, $header_size ]);

=over 4

=item *

A row is an arrayref of widgets (element widgets or text widgets).
Each widget must be free: not attached anywhere else and not in this
grid already.

=item *

Rows may have different lengths. Column N is made of the Nth cells of
all rows; a short row has no cells in the last columns. An empty row
(C<[]>) is allowed.

=item *

Row and column indices count from 0.

=item *

Every method that changes the grid checks all of its input before it
changes anything, so a call that dies leaves the grid as it was (see
L<Clay::UI::Role::Core::Element/ATTACHING CHILDREN>). Every change
bumps the revision (L<Clay::UI::Revision>) and shows at the next
C<render>.

=item *

The methods return the grid, so calls chain.

=back

=head1 CELLS AND WRAPPED WIDGETS

The grid treats the widgets you give it in one of two ways:

=over 4

=item a cell

A widget composing L<Clay::UI::Role::Layout::GridCell> - an instance
of L<Clay::UI::Grid::Cell> or of a cell class of your own - B<is> the
cell. The grid writes the column and row group ids on it, so its box,
background, border and padding cover exactly the column width and the
row height. Use a cell to style it or to align its content:

	my $cell = Clay::UI::Grid::Cell->new(
		background_color => [55, 90, 140, 255],
		layout           => {
			padding         => padding_all(6),
			child_alignment => { x => CLAY_ALIGN_X_RIGHT },
		},
	);
	$cell->add_child(My::Label->new(text => '1,234.00'));

=item any other widget

A text widget, a L<Clay::UI::Box> or anything else is put into a new,
unstyled L<Clay::UI::Grid::Cell> (FIT on both axes) that the grid
creates, and that cell gets the group ids. The widget's own box keeps
its own size inside the cell, at the left and top. This is enough when
only the layout matters.

=back

L</cell_wrappers> returns the cells the grid lays out: your cells, and
the cells it created around other widgets.

The grid keeps a cell's C<layout>. Its width sizing changes the
column:

=over 4

=item *

C<sizing_grow()>: the column takes a share of the space left in a
grid that is wider than its columns (see L</WIDE GRIDS AND GROW
COLUMNS>);

=item *

C<sizing_fit($min, $max)> or C<sizing_grow($min, $max)>: the maximum
limits that cell only, and text in it wraps at that width. The other
cells of the column still widen the column, so give every cell of the
column the same maximum, or the column does not line up;

=item *

C<sizing_fixed($n)>: the cell does not take part in the column sizing
(FIXED members are ignored by sizing groups); give every cell of the
column the same fixed width.

=back

Text in a grid column wraps when the grid is too narrow for its
columns: the cells of a column share the column's widest unwrapped
width and its largest minimum (the longest word), and Clay compresses
them like any other children down to that minimum. Every row of a grid
compresses alike, so the columns stay aligned. To wrap a column at a
chosen width instead, give it a maximum (C<sizing_fit(0, 200)>,
C<sizing_grow(0, 200)>) or a fixed width in every row.

=head1 SPANNING ROWS

A spanning row holds a single cell as wide as the whole grid, for
example a heading for the rows below it:

	$grid->append_spanning_row(My::Label->new(text => 'Guests'));
	$grid->insert_spanning_row(0, $title);

A cell cannot span some of the columns, only all of them: the only way
to span is a whole spanning row.

The cell of a spanning row belongs to no column: it does not widen any
column, and the columns do not size it. It gets a row C<height_group>
like any row.

A widget that is not a cell is put into an unstyled cell with a
C<sizing_percent(1)> width. That cell is as wide as the grid, and Clay
does not count it when it fits the grid to its rows: a long heading
wraps instead of widening the grid. A cell of your own keeps its
layout; give it a C<sizing_percent(1)> width for the same effect. (A
C<sizing_grow()> width fills the row too, but its content then widens a
grid that fits its content.)

L</is_spanning_row> tells the two kinds of rows apart. L</set_cell>
dies on a spanning row; L</replace_row> turns a spanning row into a
normal one and L</replace_spanning_row> the other way round.

=head1 WIDE GRIDS AND GROW COLUMNS

By default a grid is exactly as wide as its columns (FIT). Give it a
wider C<layout> width, for example C<sizing_grow()> or
C<sizing_fixed(600)>, and it gets space left over. Every row is as
wide as the grid, so cells with a C<sizing_grow()> width share that
space:

	my $grid = My::Grid->new(layout => { sizing => { width => sizing_grow() } });
	for my $file (@files) {
		my $name = Clay::UI::Grid::Cell->new(
			layout => { sizing => { width => sizing_grow() } },
		);
		$name->add_child(My::Label->new(text => $file->{name}));
		$grid->append_row([ $name, My::Label->new(text => $file->{size}) ]);
	}

Give the cells of a growing column a C<sizing_grow()> width in
B<every> row. Clay hands out the space row by row; a column that grows
in some rows only does not stay aligned.

=head1 STYLING A ROW

A row (L<Clay::UI::Grid::Row>) has no style of its own: it takes no
C<background_color>, C<border_color> or C<corner_radius>. To colour a
row, such as a header row, either colour each of its cells (use
L<Clay::UI::Grid::Cell> objects with a C<background_color>), with a
C<cell_gap> of 0 and C<padding> in the cells so no gap shows between
them, or give the grid itself a C<background_color>.

	my $grid = My::Grid->new(id => 'files', cell_gap => 0);
	$grid->append_row([
		map {
			my $cell = Clay::UI::Grid::Cell->new(
				background_color => [55, 90, 140, 255],
				layout           => { padding => padding_all(4) },
			);
			$cell->add_child(My::Label->new(text => $_));
			$cell;
		} 'Name', 'Size'
	]);

=head1 SHARING COLUMNS BETWEEN GRIDS

Two grids can share their columns: column N of both is sized as one
column, as wide as the widest cell of column N in either grid. The
typical case is a header that stays put above a body that scrolls:

	my $header = My::Grid->new(id => 'header', cell_gap => 8);
	my $body   = My::Grid->new(id => 'body',   cell_gap => 8, share_columns_with => $header);
	my $scroll = My::ScrollBox->new(
		id     => 'body-scroll',
		layout => { sizing => { height => sizing_fixed(300) } },
	);

	$header->append_row([ map { My::Label->new(text => $_) } 'Name', 'Size' ]);
	$body->append_row([
		My::Label->new(text => $_->{name}),
		My::Label->new(text => $_->{size}),
	]) for @files;

	$scroll->add_child($body);
	$page->add_child($header, $scroll);

(C<My::ScrollBox> is a class composing L<Clay::UI::Box> and
L<Clay::UI::Role::Layout::HasScroll>.)

=over 4

=item *

The grids can be anywhere in the tree.

=item *

Any number of grids can share the columns of one grid. Their rows never
share a height.

=item *

The grids also get a common C<width_group> (unless you gave one to a
grid), so they are as wide as the widest of them. A grid whose rows
all span, or that has no rows yet, is still as wide as the columns.

=item *

Give the grids the same C<cell_gap>, or the columns drift apart by the
difference.

=item *

C<share_columns_with> is a constructor parameter only: grids cannot
start or stop sharing later.

=back

=head1 NESTED GRIDS

A cell may hold another grid; a grid is a widget like any other. The
inner grid sizes its own columns and rows, independently of the outer
grid, and the outer column is as wide as the inner grid:

	my $inner = My::Grid->new(id => 'details');
	$inner->append_row([ My::Label->new(text => 'CPU'), My::Label->new(text => '4 cores') ]);
	$inner->append_row([ My::Label->new(text => 'RAM'), My::Label->new(text => '16 GB') ]);

	$outer->append_row([ My::Label->new(text => 'server-1'), $inner ]);

Every grid uses its own group ids (see L</GROUP IDS>), so nested grids
never get in each other's way.

=head1 THE GRID'S OWN LAYOUT AND STYLE

The grid composes L<Clay::UI::Role::Layout::HasLayout>,
L<Clay::UI::Role::Style::HasBackground>,
L<Clay::UI::Role::Style::HasBorder> and
L<Clay::UI::Role::Style::HasCornerRadius>, so it takes C<layout>,
C<background_color>, C<border_color>, C<border_width> and
C<corner_radius> like a L<Clay::UI::Box>. It has no C<floating> and no
C<fire_event>; it has C<on> (L<Clay::UI::Role::Events::Listener>).

The grid's own layout defaults to:

	{
		sizing           => { width => sizing_fit(), height => sizing_fit() },
		layout_direction => CLAY_TOP_TO_BOTTOM,
		child_gap        => $row_gap,
	}

A C<layout> you give is merged over these defaults one top-level key at
a time. C<< layout => { padding => padding_all(8) } >> keeps the rows
stacked top to bottom with C<row_gap> between them; C<< layout => {
child_gap => 10 } >> replaces C<row_gap>; a C<sizing> replaces the
whole default C<sizing>. Do not change C<layout_direction>: the rows
must stay stacked top to bottom.

=head1 CONSTRUCTOR PARAMETERS

=head2 share_columns_with

	my $body = My::Grid->new(share_columns_with => $header);

Another grid (any object composing C<Clay::UI::Grid>) whose columns
this grid shares; see L</SHARING COLUMNS BETWEEN GRIDS>. Default undef
(no sharing). The grid keeps no reference to the other grid. Dies with
C<Clay::UI::Grid: share_columns_with must be a Clay::UI::Grid, got ...>
for anything else.

The parameters below come from the composed roles. Each is also a
read/write accessor, as documented in the role.

=head2 id

See L<Clay::UI::Role::Core::Element/id>.

=head2 layout

See L<Clay::UI::Role::Layout::HasLayout/layout>; merged with the
grid's defaults (see L</THE GRID'S OWN LAYOUT AND STYLE>).

=head2 background_color

See L<Clay::UI::Role::Style::HasBackground/background_color>.

=head2 border_color

See L<Clay::UI::Role::Style::HasBorder/border_color>.

=head2 border_width

See L<Clay::UI::Role::Style::HasBorder/border_width>.

=head2 corner_radius

See L<Clay::UI::Role::Style::HasCornerRadius/corner_radius>.

=head2 width_group

See L<Clay::UI::Role::Layout::HasSizingGroup/width_group>. A grid
sharing columns with another one gets a common width group unless you
give it one (see L</SHARING COLUMNS BETWEEN GRIDS>).

=head2 height_group

See L<Clay::UI::Role::Layout::HasSizingGroup/height_group>.

=head1 ATTRIBUTES

Both attributes are constructor parameters and read/write accessors.
A write bumps the revision (L<Clay::UI::Revision>), takes effect at the
next C<render> and returns the new value.

=head2 cell_gap

	$grid->cell_gap(8);

The space between the cells of a row, an integer from 0 to 65535.
Default C<0>. A write updates every existing row as well. Dies with
C<Clay::UI: 'cell_gap' expected an integer in 0..65535, got ...> for
anything else.

=head2 row_gap

	$grid->row_gap(4);

The space between rows, an integer from 0 to 65535. Default C<0>. It
is the C<child_gap> of the grid's layout, unless the grid's C<layout>
sets C<child_gap> itself. Errors as for L</cell_gap>.

=head1 METHODS

=head2 row_count

	my $rows = $grid->row_count;

Returns the number of rows, spanning rows included.

=head2 is_spanning_row

	if ($grid->is_spanning_row(2)) { ... }

Returns 1 when the row at the index is a spanning row, 0 otherwise.
Dies with C<Clay::UI::Grid: row index 9 out of range 0..3> for an index
that is not an existing row.

=head2 cell_wrappers

	my $cells = $grid->cell_wrappers;    # [ [ $cell, $cell, ... ], ... ]
	my $cell  = $cells->[$row][$col];

Returns the cells the grid lays out, as a new array of rows, each a new
array of cells: your cells (widgets composing
L<Clay::UI::Role::Layout::GridCell>) and the L<Clay::UI::Grid::Cell>
objects the grid created around other widgets. A spanning row holds
one cell. Changing the arrays does not change the grid; the cells are
the live objects.

=head2 append_row

	$grid->append_row([ $widget, $widget, ... ]);

Adds a row at the bottom. Dies with
C<Clay::UI::Grid: row must be an arrayref> when the argument is not an
array reference, and for the widgets that cannot be attached (see
L<Clay::UI::Role::Core::Element/ATTACHING CHILDREN>), changing nothing.
Returns the grid.


=head2 insert_row

	$grid->insert_row($index, [ $widget, ... ]);

Inserts a row so that it gets index C<$index>; the rows from there on
move down. C<$index> may be C<0> to C<row_count> (the latter appends).
Dies with C<Clay::UI::Grid: insert index 9 out of range 0..3> for
another index, and like L</append_row>. Returns the grid.

=head2 append_spanning_row

	$grid->append_spanning_row($widget);

Adds a spanning row (see L</SPANNING ROWS>) at the bottom. Dies like
L</append_row> for a widget that cannot be attached. Returns the grid.

=head2 insert_spanning_row

	$grid->insert_spanning_row($index, $widget);

Inserts a spanning row at C<$index> (C<0> to C<row_count>). Dies like
L</insert_row>. Returns the grid.

=head2 set_cell

	$grid->set_cell($row, $col, $widget);

Puts C<$widget> into the cell at C<$row>, C<$col>, following the rules
of L</CELLS AND WRAPPED WIDGETS>. The cell that was there is detached.
C<$col> may also be the current length of the row, which appends a
cell to the row. Returns the grid.

Dies, changing nothing:

=over 4

=item *

C<Clay::UI::Grid: row index ... out of range ...> for a row that does
not exist;

=item *

C<Clay::UI::Grid: row 1 spans all columns; use replace_spanning_row or replace_row>
for a spanning row;


=item *

C<Clay::UI::Grid: col index 5 out of range 0..2> for a column beyond
the row's length;

=item *

for a widget that cannot be attached, including one that is already in
this grid.

=back

=head2 replace_row

	$grid->replace_row($index, [ $widget, ... ]);

Replaces all cells of the row at C<$index> with new ones; the old cells
are detached. A spanning row becomes a normal row. The row keeps its
place and its height group. Dies like L</append_row> and for an index
that is not an existing row. Returns the grid.

=head2 replace_spanning_row

	$grid->replace_spanning_row($index, $widget);

Replaces the row at C<$index> with a spanning row holding C<$widget>;
the old cells are detached. Dies like L</replace_row>. Returns the
grid.

=head2 remove_row

	$grid->remove_row($index);

Removes the row at C<$index> and detaches its cells; the rows below
move up. Dies with C<Clay::UI::Grid: row index ... out of range ...>
for an index that is not an existing row. Returns the grid.

=head2 clear_rows

	$grid->clear_rows;

Removes all rows, as C<remove_row> would one by one. Returns the grid.

=head2 reorder_rows

	# Sort a table by its second column, keeping the header row first.
	my @order = (0, sort { $names[$a] cmp $names[$b] } 1 .. $grid->row_count - 1);
	$grid->reorder_rows(\@order);

Puts the rows in a new order: row C<$k> becomes the row that was at
C<< $order->[$k] >>. The order must hold every row index exactly once.
No row is detached, so the cells keep their parents and hover and focus
stay where they were, which is what sorting a table needs. Dies,
changing nothing, with
C<Clay::UI: a new child order must be an array reference of the indices 0..3 in any order>
for anything else. Returns the grid.


=head2 contribute_grid_defaults

Adds the grid's default C<layout> (see
L</THE GRID'S OWN LAYOUT AND STYLE>) to its declaration, under any
C<layout> keys already there (see
L<Clay::UI::Role::Core::Element/EXTENDING THE DECLARATION>).

=head1 REUSING WIDGETS

A widget can be attached whenever it has no parent (see
L<Clay::UI::Role::Layout::HasParent/ATTACHING AND REMOVING>). All row
and cell methods die for a widget that is still attached somewhere,
including in this grid.

Widgets removed by C<remove_row>, C<clear_rows>, C<replace_row>,
C<replace_spanning_row> or C<set_cell> can be attached again, to this
grid or anywhere else. A cell leaving the grid drops the column and row
group ids the grid gave it; ids you set yourself stay.

One detail: a widget the grid put into a cell of its own stays the
child of that cell, and the cells of a removed row stay children of the
row, until the grid lets go of them. That happens at once unless you
keep a reference to the cell or the row (from C<cell_wrappers> or
C<children>); while you do, the widget is not free to be attached
elsewhere.

=head1 GROUP IDS

The grid sizes its columns and rows with C<width_group> and
C<height_group> ids it chooses itself. You rarely need to know how;
this section is for alignment across grids and for reading the ids.

=head2 Overriding group ids

If a cell already has a non-zero C<width_group> or C<height_group>
when the grid receives it, the grid leaves that axis alone. That lets a
cell take part in an alignment group of your own, shared with a widget
elsewhere in the UI, instead of the grid's column or row. To align all
columns of two grids, use L</share_columns_with> instead.

User group ids are 0 to 2**20 - 1; the grid's ids are 2**20 and above,
so the two never collide (see
L<Clay::UI::Role::Layout::HasSizingGroup/width_group>).

=head2 How the grid numbers its groups

Each grid takes a grid number from a pool of 4095 for the whole
process; a grid made with C<share_columns_with> uses the number of the
grid it shares with. The pool size follows from the user range: Clay's
group ids have 32 bits, the index of a group takes the 20 bits of the
user range (C<USER_GROUP_ID_MAX>, 2**20 - 1), and the grid number the
12 that are left (2**12 - 1 = 4095). A group id is C<< (grid_number << 20) | index >>,
where the index counts columns (for width ids) and rows (for height
ids) of that grid. This means:

=over 4

=item *

Different grids never share an id, nested grids included, unless they
share columns on purpose; even then their rows never share a height.

=item *

The grid never renumbers its cells when it grows: a new column or row
takes the next index, or the index of a removed row.

=item *

A cell that still carries a grid's ids (one you kept after the grid
was freed) keeps that grid number taken until the cell is freed or put
into another grid, so no new grid gets the same ids. Once every grid
using a number is freed, its ids size nothing: the kept cells'
C<width_group> and C<height_group> read 0.

=item *

The number goes back to the pool when every grid using it and every
cell carrying its ids are freed, so programs that create and drop many
grids do not run out. More than 4095 grid numbers taken at once makes
the grid constructor die with C<Clay::UI::Grid: grid-id pool exhausted (max 4095 live grids)>.

=item *

Group ids differ between runs of the program; do not store them.

=back

The number is held by a small internal object, not by the grid, so a
class composing C<Clay::UI::Grid> may define its own C<DESTROY>.

=head1 SEE ALSO

L<Clay::UI::Grid::Cell>, L<Clay::UI::Role::Layout::GridCell>,
L<Clay::UI::Grid::Row>, L<Clay::UI::Role::Layout::HasSizingGroup>,
L<Clay::UI>, L<Clay::Manual>, L<Clay::Cookbook>.

=cut
