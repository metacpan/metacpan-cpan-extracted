package CSS::SpriteMaker::Layout;

use strict;
use warnings;

use List::Util qw(max min);

=head1 NAME

CSS::SpriteMaker::Layout - Layout interface for items placed on a 2D grid.

Allows to access coordinates of items laid out on a 2D grid.

Shouldn't be instantiated directly, but subclasses should be instantiated
instead.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head2 _layout_items

Lays out the items given their properties. These properties can be global or
about individual items, and have the form of the following hashref:

    {
        '<item_id>' : {
            width => <integer>,
            height => <integer>,
            first_pixel_x => <integer>,
            first_pixel_y => <integer>,
            ... other arbitrary properties, if any
        },
        ...
    }

This method should never be called on this class, but on a subclass. It contains
the implementation of the specific layout after all.

=cut

sub _layout_items {
    my $self = shift;
    my $rh_item_info = shift;
    die "you shouldn't be calling layout_items directly on this object, but a subclass should implement it!";
}

=head2 get_item_coord

Gets the coordinates of a specific item within the layout.

    my ($x, $y) = $Layout->get_item_coord("129");

Returns a list containing the x and the y coordinates of the specified element
respectively.

=cut

sub get_item_coord {
    my $self = shift;
    my $id = shift;

    die "finalize() was not called on this class!" if !$self->{_layout_ran};

    if (!defined $self->{items} || !defined $self->{items}{$id}) {
        warn "item id: $id doesn't appear to be part of this layout";
        return;
    }

    my $rh_coords = $self->{items}{$id};
    return ($rh_coords->{x}, $rh_coords->{y});
}

=head2 set_item_coord

Sets the coordinates of a layout item.

    # sets coordinates of item #129 to x: 100 y: 200
    $Layout->set_item_coord("129", 100, 200); 

Sets coordinates of the given element internally and returns undef.

=cut

sub set_item_coord {
    my $self = shift;
    my $id = shift;
    my $x = shift;
    my $y = shift;

    $self->{items} = {} if !defined $self->{items};

    $self->{items}{$id} = {
        x => $x,
        y => $y,
    };

    return;
}

=head2 move_items

Moves all the items in this layout by the given deltay and deltax.
    
=cut

sub move_items {
    my $self = shift;
    my ($dx, $dy) = @_;
    for my $id ($self->get_item_ids) {
        my ($x, $y) = $self->get_item_coord($id);
        $self->set_item_coord($id, $x+$dx, $y+$dy);
    }
}

=head2 delete_item

Deletes the item with the specified id from the internal list of items that
have been layed out. 

WARNING - this doesn't trigger a re-layout: will result in having a hole in
the current layout. Be aware of it.

Triggers a warning if the element with the specified id doesn't exist in
the current layout.

=cut

sub delete_item {
    my $self = shift;
    my $item_id = shift;

    if (!exists $self->{items}{$item_id}) {
        warn "the item with id \"$item_id\" you are trying to delete doesn't exist in the current layout";
        return;
    }
    delete $self->{items}{$item_id};
    return;
}

=head2 merge_with

Merges the current layout with the one specified. For a successful merge to
happen, items in the old and in the new layout must have different ids.

=cut

sub merge_with {
    my $self = shift;
    my $Layout = shift;

    my ($minx, $miny);
    for my $id ($Layout->get_item_ids()) {
        my ($x, $y) = $Layout->get_item_coord($id);

        # check that the id doesn't exist
        if (exists $self->{items}{$id}) {
            warn "the id $id already exists in the target layout!";
        }
        
        # merge
        $self->set_item_coord($id, $x, $y);
    }

    return;
}

=head2 get_item_ids

Returns the id of each item into an array.

    my @ids = $Layout->get_item_ids();

=cut

sub get_item_ids {
    my $self = shift;
    return sort { $a <=> $b } keys %{$self->{items}};
}

=head2 get_layout_ascii_string

Returns the current layout in an ascii string suitable for console printing.

Optionally takes width and height of the canvas in px if the canvas is to be
reduced to a specific dimension in pixels.

    my $ascii_string = $Layout->get_layout_ascii_string();

OR
    
    my $ascii_string = $Layout->get_layout_ascii_string({
        canvas_width => 80,
        canvas_height => 60,
        rh_item_info => {
            '<item_id>' => {
                width => <integer>,
                height => <integer>,
            },
            ...
        }
    });

NOTE: the $Layout->finalize() method should've been called prior calling this
method.

=cut

sub get_layout_ascii_string {
    my $self = shift;
    my $rh_options = shift;

    die "finalize() was not called on this layout class!" if !$self->{_layout_ran};

    my %canvas;
    my %ids;

    # find max id and min id
    my @item_ids = $self->get_item_ids;
    my $max_item_id = max(@item_ids);
    my $min_item_id = min(@item_ids);

    # find canvas size
    my $remap_x = 0;
    my $remap_y = 0;

    my ($original_width, $original_height);
    if (my $rh_info = $rh_options->{rh_item_info}) {
        $original_width = (max map { 
            my ($x, undef) = $self->get_item_coord($_); 
            $x + $rh_info->{$_}{width}
        } @item_ids);

        $original_height = (max map { 
            my (undef, $y) = $self->get_item_coord($_); 
            $y + $rh_info->{$_}{height}
        } @item_ids);
    }
    else {
        $original_height = 1 + (max map { my ($x, $y) = $self->get_item_coord($_); $x } @item_ids);
        $original_width  = 1 + (max map { my ($x, $y) = $self->get_item_coord($_); $y } @item_ids);
    }

    my $canvas_width;
    my $canvas_height;

    if (exists $rh_options->{canvas_width}) {
        $canvas_width = $rh_options->{canvas_width};
        $remap_x = 1;
    }
    else {
        $canvas_width = $original_width;
    }

    if (exists $rh_options->{canvas_height}) {
        $canvas_height = $rh_options->{canvas_height};
        $remap_y = 1;
    }
    else {
        $canvas_height = $original_height;
    }

    my $rc_x = sub { 
        my $x = shift; 

        if ($remap_x) {
            $x = ($x * ($canvas_width - 1)) / $original_width;
            # round
            $x = int($x + ($x < 0 ? -0.5 : 0.5));
        }

        return $x;
    };
    my $rc_y = sub { 
        my $y = shift; 
        if ($remap_y) {

            $y = ($y * ($canvas_height - 1)) / $original_height;
            # round
            $y = int($y + ($y < 0 ? -0.5 : 0.5));
        }
        return $y;
    };

    # now draw each pixel in the canvas
    for my $id (@item_ids) {
        my ($x, $y) = $self->get_item_coord($id);

        # remap start points
        $x = $rc_x->($x);
        $y = $rc_y->($y);

        # remap end points if provided
        if (my $rh_info = $rh_options->{rh_item_info}) {
            my $w = $rc_x->($rh_info->{$id}{width});
            my $h = $rc_y->($rh_info->{$id}{height});

            my $end_x = $x + $w - 1;
            my $end_y = $y + $h - 1;

            # fill box
            for my $y_pt ($y .. $end_y) {
                for my $x_pt ($x .. $end_x) {
                    $canvas{$x_pt}{$y_pt} = '+';
                }
            }

            # plot the other 3 corners
            $canvas{$end_x}{$end_y} = 'o';
        }
        # plot the top left corner
        $canvas{$x}{$y} = '.';

        $ids{$x}{$y} //= [];
        push @{$ids{$x}{$y}}, $id;
    }

    # now write the canvas into chars
    my $skip_pixels = 0;
    my @ascii_chars;
    for my $y (0 .. $canvas_height - 1) {

        if ($skip_pixels) {
            $skip_pixels--;
        }
        else {
            push @ascii_chars, "|";
        }

        for my $x (0 .. $canvas_width - 1) {

            # write the position first
            if (exists $canvas{$x} && exists $canvas{$x}{$y}) {

                if ($canvas{$x}{$y} eq '.') {
                    push @ascii_chars, $canvas{$x}{$y};

                    # now append the label and skip the same amount of pixel,
                    my $label = join "+", @{$ids{$x}{$y}};
                    $skip_pixels += (length $label);

                    push @ascii_chars, (split "", $label);
                }
                else {
                    if ($skip_pixels) {
                        $skip_pixels--;
                    }
                    else {
                        push @ascii_chars, $canvas{$x}{$y};
                    }
                }
            }
            else {

                if ($skip_pixels) {
                    $skip_pixels--;
                }
                else {
                    push @ascii_chars, ' ';
                }
            }
        }
        if ($skip_pixels) {
            $skip_pixels--;
        }
        else {
            push @ascii_chars, "|";
        }
        push @ascii_chars, "\n";
    }

    return join('', @ascii_chars);
}

=head2 width

Returns the width of the overall layout in pixels.

    my $width = $Layout->width();

=cut

sub width {
    my $self = shift;
    return $self->{width};
}

=head2 height

Returns the height of the overall layout in pixels.

    my $width = $Layout->height();

=cut

sub height {
    my $self = shift;
    return $self->{height};
}

=head2 finalize

Sets this layout as instantiated. To only be called by a subclass of this base
class once class is instantiated.

    $Layout->finalize();

Once called, some checks are performed on the layout and
warnings are issued emitted if something is wrong.

Always returns undef.

=cut

sub finalize {
    my $self = shift;
    
    for my $attribute (qw/width height/) {
        if (!defined $self->{$attribute}) {
            warn "attribute $attribute should always be set in the layout class!";
        }
    }

    $self->{_layout_ran} = 1;
    return;
}

1;
