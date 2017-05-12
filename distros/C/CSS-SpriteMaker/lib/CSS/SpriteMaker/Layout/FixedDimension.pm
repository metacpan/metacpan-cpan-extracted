package CSS::SpriteMaker::Layout::FixedDimension;

use strict;
use warnings;

use base 'CSS::SpriteMaker::Layout';

=head1 NAME

CSS::SpriteMaker::Layout::FixedDimension

    my $FixedDimensionLayout = CSS::SpriteMaker::Layout::FixedDimension->new(
        # example $rh_item_info input structure
        {
            "1" => {
                width => 128,
                height => 128,
            },
            ...
        },
        # max 10 items on the same row,
        { 
            dimension => 'horizontal',
            n => 10
        },
    );

Layout maximum I<n> items on a row.

Items are chosen at random.

Input $rh_item_info structure must contain the following keys for this layout
to produce a result:

- width : the width in pixels of the image;

- height : the height in pixels of the image;

The following input parameters B<must> be specified:

- n : number of maximum items to place on the same row

The following input parameters are optional:

- dimension: can be 'horizontal' (default) or 'vertical'.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head2 new

Instantiates the layout:

    my $FixedDimensionLayout = CSS::SpriteMaker::Layout::FixedDimension->new(
        $rh_item_info,
        {   dimension => 'vertical'  # 'horizontal' is the default
            n => 10                  # compulsory!
        }
    );

=cut

sub new {
    my $class = shift;
    my $rh_items_info = shift;
    my $rh_input_params = shift;

    # defaults
    $rh_input_params->{dimension} //= 'horizontal';

    my $self = bless {}, $class;

    if (!$rh_items_info) {
        die 'no items info hashref was passed in construction to this layout';
    }

    $self->_layout_items($rh_items_info, $rh_input_params);
    $self->finalize();

    return $self;
}

=head2 _layout_items

=cut

sub _layout_items {
    my $self          = shift;
    my $rh_items_info = shift;
    my $rh_input_params = shift;

    if (!exists $rh_input_params->{n} || !defined $rh_input_params->{n}) {
        die "the layout parameter 'n' is required for this layout to produce a result.";
    }

    my $n = $rh_input_params->{n};
    my $dimension = $rh_input_params->{dimension};

    # 1. put items from the same directory in the same row
    my $dimension_id = $dimension eq 'horizontal' ? '0' : '1';

    my @xy = (0, 0);

    my @total_wh = (0, 0);
    my $dimension_size = 0;

    my $i = 0;
    for my $id (sort keys %$rh_items_info) {
        my @wh = ($rh_items_info->{$id}{width}, $rh_items_info->{$id}{height});

        # condition to switch to the next row
        if ($i == $n) {
            # this item must go on the next row
            $xy[1-$dimension_id] += $dimension_size;
            $xy[$dimension_id] = 0;
            $dimension_size = 0;

            # reset condition
            $i = 0;
        }

        # chain on the current row...
        $self->set_item_coord($id, @xy);

        # prepare next element
        $xy[$dimension_id] += $wh[$dimension_id];
        
        # calculate dimension size (height or width based on dimension)
        $dimension_size = $wh[1-$dimension_id]   if $wh[1-$dimension_id] > $dimension_size;

        # update min/max sizes
        if ($xy[$dimension_id] > $total_wh[$dimension_id]) {
            $total_wh[$dimension_id] = $xy[$dimension_id];
        }
        if ($xy[1-$dimension_id] + $dimension_size > $total_wh[1-$dimension_id]) {
            $total_wh[1-$dimension_id] = $xy[1-$dimension_id] + $dimension_size 
        }

        $i++;
    }

    $self->{width} = $total_wh[0];
    $self->{height} = $total_wh[1];

    return;
}

1;
