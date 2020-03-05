#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013-2015 -- leonerd@leonerd.org.uk

use Object::Pad 0.09;

class Tickit::Widget::GridBox 0.29
   extends Tickit::ContainerWidget;

use Tickit::Style;

use Carp;

use Tickit::Utils 0.29 qw( distribute );

use List::Util qw( sum max );

=head1 NAME

C<Tickit::Widget::GridBox> - lay out a set of child widgets in a grid

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::GridBox;
 use Tickit::Widget::Static;

 my $gridbox = Tickit::Widget::GridBox->new(
    style => {
       col_spacing => 2,
       row_spacing => 1,
    },
    children => [
      [ Tickit::Widget::Static->new( text => "top left" ),
        Tickit::Widget::Static->new( text => "top right" ) ],
      [ Tickit::Widget::Static->new( text => "bottom left" ),
        Tickit::Widget::Static->new( text => "bottom right" ) ],
    ],
 );

 Tickit->new( root => $gridbox )->run;

=head1 DESCRIPTION

This container widget holds a set of child widgets distributed in a regular
grid shape across rows and columns.

=head1 STYLE

The default style pen is used as the widget pen.

The following style keys are used:

=over 4

=item col_spacing => INT

The number of columns of spacing between columns

=item row_spacing => INT

The number of rows of spacing between rows

=back

=cut

style_definition base =>
   row_spacing => 0,
   col_spacing => 0;

style_reshape_keys qw( row_spacing col_spacing );

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=head2 $gridbox = Tickit::Widget::GridBox->new( %args )

Constructs a new C<Tickit::Widget::GridBox> object.

Takes the following named arguments:

=over 8

=item children => ARRAY[ARRAY[Tickit::Widget]]

Optional. If present, should be a 2D ARRAYref of ARRAYrefs containing the
C<Tickit::Widget> children to display in the grid. They are all added with no
additional options.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   exists $args{$_} and $args{style}{$_} = delete $args{$_} for qw( row_spacing col_spacing );

   my $self = $class->SUPER::new( %args );

   $self->{grid} = [];
   $self->{max_col} = -1;

   if( my $children = $args{children} ) {
      foreach my $row ( 0 .. $#$children ) {
         foreach my $col ( 0 .. $#{ $children->[$row] } ) {
            $self->add( $row, $col, $children->[$row][$col] );
         }
      }
   }

   return $self;
}

sub lines
{
   my $self = shift;
   my $row_spacing = $self->get_style_values( "row_spacing" );
   my $max_row = $#{$self->{grid}};
   my $max_col = $self->{max_col};
   return ( sum( map {
         my $r = $_;
         max map {
            my $c = $_;
            my $child = $self->{grid}[$r][$c];
            $child ? $child->requested_lines : 0;
         } 0 .. $max_col
      } 0 .. $max_row ) ) +
      $row_spacing * $max_row;
}

sub cols
{
   my $self = shift;
   my $col_spacing = $self->get_style_values( "col_spacing" );
   my $max_row = $#{$self->{grid}};
   my $max_col = $self->{max_col};
   return ( sum( map {
         my $c = $_;
         max map {
            my $r = $_;
            my $child = $self->{grid}[$r][$c];
            $child ? $child->requested_cols : 0;
         } 0 .. $max_row
      } 0 .. $max_col ) ) +
      $col_spacing * $max_col;
}

sub children
{
   my $self = shift;
   my $grid = $self->{grid};
   map {
      my $r = $_;
      map {
         $grid->[$r][$_] ? ( $grid->[$r][$_] ) : ()
      } 0 .. $self->{max_col}
   } 0.. $#$grid;
}

=head1 METHODS

=cut

=head2 $count = $gridbox->rowcount

=head2 $count = $gridbox->colcount

Returns the number of rows or columns in the grid.

=cut

sub rowcount
{
   my $self = shift;
   return scalar @{ $self->{grid} }
}

sub colcount
{
   my $self = shift;
   return $self->{max_col} + 1;
}

=head2 $gridbox->add( $row, $col, $child, %opts )

Sets the child widget to display in the given grid cell. Cells do not need to
be explicitly constructed; the grid will automatically expand to the size
required. This method can also be used to replace an existing child at the
given cell location. To remove a cell entirely, use the C<remove> method.

The following options are recognised:

=over 8

=item col_expand => INT

=item row_expand => INT

Values for the C<expand> setting for this column or row of the table. The
largest C<expand> setting for any cell in a given column or row sets the value
used to distribute space to that column or row.

=back

=cut

sub add
{
   my $self = shift;
   my ( $row, $col, $child, %opts ) = @_;

   if( my $old_child = $self->{grid}[$row][$col] ) {
      $self->SUPER::remove( $old_child );
   }

   $self->{max_col} = $col if $col > $self->{max_col};

   $self->{grid}[$row][$col] = $child;
   $self->SUPER::add( $child,
      col_expand => $opts{col_expand} || 0,
      row_expand => $opts{row_expand} || 0,
   );
}

=head2 $gridbox->remove( $row, $col )

Removes the child widget on display in the given cell. May shrink the grid if
this was the last child widget in the given row or column.

=cut

sub remove
{
   my $self = shift;
   my ( $row, $col ) = @_;

   my $grid = $self->{grid};

   my $child = $grid->[$row][$col];
   undef $grid->[$row][$col];

   # Tidy up the row
   my $max_col = 0;
   foreach my $col ( reverse 0 .. $#{ $grid->[$row] } ) {
      next if !defined $grid->[$row][$col];

      $max_col = $col+1;
      last;
   }

   splice @{ $grid->[$row] }, $max_col;

   # Tidy up the grid
   my $max_row = 0;
   foreach my $row ( reverse 0 .. $#$grid ) {
      next if !defined $grid->[$row] or !@{ $grid->[$row] };

      $max_row = $row+1;
      last;
   }

   splice @$grid, $max_row;

   $self->{max_col} = max map { $_ ? $#$_ : 0 } @$grid;

   my $childrect = $child->window ? $child->window->rect : undef;

   $self->SUPER::remove( $child );

   $self->window->expose( $childrect ) if $childrect;
}

=head2 $child = $gridbox->get( $row, $col )

Returns the child widget at the given cell in the grid. If the row or column
index are beyond the bounds of the grid, or if there is no widget in the given
cell, returns C<undef>.

=cut

sub get
{
   my $self = shift;
   my ( $row, $col ) = @_;

   return undef if $row >= @{ $self->{grid} };
   return $self->{grid}[$row][$col];
}

=head2 @children = $gridbox->get_row( $row )

=head2 @children = $gridbox->get_col( $col )

Convenient shortcut to call C<get> on an entire row or column of the grid.

=cut

sub get_row
{
   my $self = shift;
   my ( $row ) = @_;
   return map { $self->get( $row, $_ ) } 0 .. $self->colcount - 1;
}

sub get_col
{
   my $self = shift;
   my ( $col ) = @_;
   return map { $self->get( $_, $col ) } 0 .. $self->rowcount - 1;
}

=head2 $gridbox->insert_row( $before_row, [ @children ] )

Inserts a new row into the grid by moving the existing rows after it lower
down. Any child widgets in the referenced array will be set on the cells of
the new row, at an column corresponding to its index in the array. A child of
C<undef> will be skipped over.

=cut

sub insert_row
{
   my $self = shift;
   my ( $row, $children ) = @_;

   splice @{ $self->{grid} }, $row, 0, [];

   foreach my $col ( 0 .. $#$children ) {
      next unless my $child = $children->[$col];

      $self->add( $row, $col, $child ); # No options
   }
}

=head2 $gridbox->insert_col( $before_col, [ @children ] )

Inserts a new column into the grid by moving the existing columns after it to
the right. Any child widgets in the referenced array will be set on the cells
of the new column, at a row corresponding to its index in the array. A child
of C<undef> will be skipped over.

=cut

sub insert_col
{
   my $self = shift;
   my ( $col, $children ) = @_;

   my $grid = $self->{grid};
   $self->{max_col}++;

   foreach my $row ( 0 .. max( $self->rowcount, scalar @$children ) - 1 ) {
      splice @{ $grid->[$row] //= [ ( undef ) x $col ] }, $col, 0, ( undef );

      next unless my $child = $children->[$row];

      $self->add( $row, $col, $child ); # No options
   }
}

=head2 $gridbox->append_row( [ @children ] )

Shortcut to inserting a new row after the end of the current grid.

=cut

sub append_row
{
   my $self = shift;
   $self->insert_row( $self->rowcount, @_ );
}

=head2 $gridbox->append_col( [ @children ] )

Shortcut to inserting a new column after the end of the current grid.

=cut

sub append_col
{
   my $self = shift;
   $self->insert_col( $self->colcount, @_ );
}

=head2 $gridbox->delete_row( $row )

Deletes a row of the grid by moving the existing rows after it higher up.

=cut

sub delete_row
{
   my $self = shift;
   my ( $row ) = @_;

   $self->remove( $row, $_ ) for 0 .. $self->colcount - 1;

   splice @{ $self->{grid} }, $row, 1, ();
   $self->children_changed;
}

=head2 $gridbox->delete_col( $col )

Deletes a column of the grid by moving the existing columns after it to the
left.

=cut

sub delete_col
{
   my $self = shift;
   my ( $col ) = @_;

   $self->remove( $_, $col ) for 0 .. $self->rowcount - 1;

   splice @{ $self->{grid}[$_] }, $col, 1, () for 0 .. $self->rowcount - 1;
   $self->{max_col}--;
   $self->children_changed;
}

sub reshape
{
   my $self = shift;
   my $win = $self->window or return;

   my @row_buckets;
   my @col_buckets;

   my $max_row = $self->rowcount - 1;
   my $max_col = $self->colcount - 1;

   my ( $row_spacing, $col_spacing ) = $self->get_style_values(qw( row_spacing col_spacing ));

   foreach my $row ( 0 .. $max_row ) {
      push @row_buckets, { fixed => $row_spacing } if @row_buckets;

      my $base = 0;
      my $expand = 0;

      foreach my $col ( 0 .. $max_col ) {
         my $child = $self->{grid}[$row][$col] or next;

         $base   = max $base, $child->requested_lines;
         $expand = max $expand, $self->child_opts( $child )->{row_expand};
      }

      push @row_buckets, {
         row    => $row,
         base   => $base,
         expand => $expand,
      };
   }

   foreach my $col ( 0 .. $max_col ) {
      push @col_buckets, { fixed => $col_spacing } if @col_buckets;

      my $base = 0;
      my $expand = 0;

      foreach my $row ( 0 .. $max_row ) {
         my $child = $self->{grid}[$row][$col] or next;

         $base   = max $base, $child->requested_cols;
         $expand = max $expand, $self->child_opts( $child )->{col_expand};
      }

      push @col_buckets, {
         col    => $col,
         base   => $base,
         expand => $expand,
      };
   }

   distribute( $win->lines, @row_buckets );
   distribute( $win->cols,  @col_buckets );

   my @rows;
   foreach ( @row_buckets ) {
      $rows[$_->{row}] = [ $_->{start}, $_->{value} ] if defined $_->{row};
   }

   my @cols;
   foreach ( @col_buckets ) {
      $cols[$_->{col}] = [ $_->{start}, $_->{value} ] if defined $_->{col};
   }

   foreach my $row ( 0 .. $max_row ) {
      foreach my $col ( 0 .. $max_col ) {
         my $child = $self->{grid}[$row][$col] or next;

         # Don't try to use zero-sized rows or cols
         next unless $rows[$row][1] and $cols[$col][1];

         my @geom = ( $rows[$row][0], $cols[$col][0], $rows[$row][1], $cols[$col][1] );

         if( my $childwin = $child->window ) {
            $childwin->change_geometry( @geom );
         }
         else {
            $childwin = $win->make_sub( @geom );
            $child->set_window( $childwin );
         }
      }
   }
}

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   $rb->eraserect( $rect );
}

=head1 TODO

=over 4

=item *

Add C<move_{row,col}> methods for re-ordering existing rows or columns

=item *

Make C<{insert,append,delete,move}> operations more efficient by deferring the
C<children_changed> call until they are done.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
